import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:fluttium_driver/fluttium_driver.dart';
import 'package:fluttium_driver/src/bundles/bundles.dart';
import 'package:fluttium_interfaces/fluttium_interfaces.dart';
import 'package:fluttium_protocol/fluttium_protocol.dart';
import 'package:mason/mason.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart';
import 'package:process/process.dart';
import 'package:watcher/watcher.dart';
import 'package:yaml/yaml.dart';

/// Returns the [MasonGenerator] to use.
typedef GeneratorBuilder = FutureOr<MasonGenerator> Function(
  MasonBundle specification,
);

/// Builder for a [DirectoryWatcher].
typedef DirectoryWatcherBuilder = DirectoryWatcher Function(
  String path, {
  Duration? pollingDelay,
});

/// Builder for a [FileWatcher].
typedef FileWatcherBuilder = FileWatcher Function(
  String path, {
  Duration? pollingDelay,
});

/// {@template fluttium_driver}
/// A driver for executing Fluttium flow tests.
/// {@endtemplate}
class FluttiumDriver {
  /// {@macro fluttium_driver}
  FluttiumDriver({
    required this.configuration,
    required this.actions,
    required this.projectDirectory,
    required this.userFlowFile,
    Logger? logger,
    ProcessManager? processManager,
    @visibleForTesting GeneratorBuilder? generator,
    @visibleForTesting DirectoryWatcherBuilder? directoryWatcher,
    @visibleForTesting FileWatcherBuilder? fileWatcher,
  })  : _logger = logger ?? Logger(),
        _processManager = processManager ?? const LocalProcessManager(),
        _generatorBuilder = generator ?? MasonGenerator.fromBundle,
        _directoryWatcher = directoryWatcher ?? DirectoryWatcher.new,
        _fileWatcher = fileWatcher ?? FileWatcher.new,
        _stepStateController = StreamController<List<StepState>>.broadcast(),
        assert(userFlowFile.existsSync(), 'userFlowFile does not exist') {
    userFlow = UserFlowYaml.fromFile(userFlowFile);
  }

  /// The configuration for the driver.
  final DriverConfiguration configuration;

  /// The actions to install to run the flow.
  final Map<String, ActionLocation> actions;

  /// The directory of the project.
  final Directory projectDirectory;

  /// The user flow file to run.
  final File userFlowFile;

  /// The user flow that is being run.
  late UserFlowYaml userFlow;

  /// Stream of the steps in the user flow.
  ///
  /// The steps are emitted as a list of [StepState]s representing the current
  /// state of those steps, the list is ordered by the order of execution.
  late final Stream<List<StepState>> steps = _stepStateController.stream;
  final StreamController<List<StepState>> _stepStateController;
  final List<StepState> _stepStates = [];

  final Logger _logger;

  final ProcessManager _processManager;
  Process? _process;
  var _didAttach = false;
  late final Listener _listener;

  final GeneratorBuilder _generatorBuilder;

  late final MasonGenerator _testRunnerGenerator;
  late final Directory _testRunnerDirectory;

  late final MasonGenerator _launcherGenerator;
  late final File _launcherFile;

  final DirectoryWatcherBuilder _directoryWatcher;
  final FileWatcherBuilder _fileWatcher;
  final List<StreamSubscription<dynamic>> _subscriptions = [];

  var _restarting = false;

  /// Run the driver.
  ///
  /// This will setup the driver generated code, generate the runner, and start
  /// the runner with the given user flow.
  ///
  /// This will return a [Future] that completes when the driver is done,
  /// either by completing the user flow, application was closed, [quit] was
  /// called, or an error occurred.
  ///
  /// To listen to the steps in the user flow, use the [steps] stream.
  Future<void> run({bool watch = false}) async {
    await _setupGeneratedCode();
    await _startRunner(watch: watch);

    _subscriptions.add(
      _listener.messages.listen((message) async {
        switch (message.type) {
          case MessageType.announce:
            _stepStates.add(StepState(message.data as String));
            break;
          case MessageType.start:
            final index = _stepStates.indexWhere(
              (state) => state.status == StepStatus.initial,
            );
            _stepStates[index] = _stepStates[index].copyWith(
              status: StepStatus.running,
            );
            break;
          case MessageType.done:
            final index = _stepStates.indexWhere(
              (state) => state.status == StepStatus.running,
            );
            _stepStates[index] = _stepStates[index].copyWith(
              status: StepStatus.done,
            );
            break;
          case MessageType.fail:
            final data = message.data as List<dynamic>;
            final reason = data.last as String;

            final index = _stepStates.indexWhere(
              (state) => state.status == StepStatus.running,
            );
            _stepStates[index] = _stepStates[index].copyWith(
              status: StepStatus.failed,
              failReason: reason,
            );
            break;
          case MessageType.store:
            final data = message.data as List<dynamic>;
            final fileName = data.first as String;
            final fileData = data.last as List<int>;

            final index = _stepStates.indexWhere(
              (state) => state.status == StepStatus.running,
            );
            _stepStates[index] = _stepStates[index].copyWith(
              files: {..._stepStates[index].files, fileName: fileData},
            );
            break;
        }

        // Don't do anything past this point if the runner is still announcing.
        if (message.type == MessageType.announce) return;
        _stepStateController.add(_stepStates);
        _restarting = false;

        // If all steps were done, or if a step failed, stop the process unless
        // we're in watch mode.
        if (!watch &&
            (_stepStates.every((e) => e.status == StepStatus.done) ||
                _stepStates.any((e) => e.status == StepStatus.failed))) {
          await quit();
        }
      }),
    );

    // Wait for the process to exit, and then clean up the project.
    await _process?.exitCode;

    // Cancel all the subscriptions.
    await Future.wait(_subscriptions.map((e) => e.cancel()));
    _subscriptions.clear();

    // Close the step state controller.
    await _stepStateController.close();

    // Close the message listener.
    await _listener.close();

    // Cleanup the generated files.
    await _cleanupGeneratedCode();

    _process = null;
  }

  /// Restart the runner and the driver.
  Future<void> restart() async {
    if (_restarting || _process == null) return;
    _restarting = true;

    // Set the status of all steps to initial, we already know the steps so
    // there is no need to wait with telling the listener.
    _stepStateController.add(
      _stepStates.map((e) => StepState(e.description)).toList(),
    );

    // Clear all the states after the listener has been notified, it will
    // automatically be filled up by the runner.
    _stepStates.clear();

    // Regenerate the runner.
    await _generateRunner();

    // Tell the runner to restart.
    _process?.stdin.write('R');
  }

  /// Quit the runner and it's driver.
  Future<void> quit() async {
    // Tell the runner to quit.
    _process?.stdin.write('q');
  }

  Future<void> _setupGeneratedCode() async {
    final settingUpTestRunner = _logger.progress('Setting up the test runner');

    // Setup the test runner.
    _testRunnerGenerator = await _generatorBuilder(fluttiumTestRunnerBundle);
    _testRunnerDirectory = Directory.systemTemp.createTempSync('fluttium_');
    settingUpTestRunner.complete();

    final settingUpLauncher = _logger.progress('Setting up the launcher');

    // Setup the launcher.
    final projectData = loadYaml(
      File(join(projectDirectory.path, 'pubspec.yaml')).readAsStringSync(),
    ) as YamlMap;

    _launcherGenerator = await _generatorBuilder(fluttiumLauncherBundle);
    final launcherVars = {
      'runner_id': basename(_testRunnerDirectory.path),
      'project_name': projectData['name'],
      'main_entry': configuration.mainEntry
          .replaceFirst('${projectDirectory.path}/', '')
          .replaceFirst('lib/', ''),
      'runner_path': _testRunnerDirectory.path,
    };
    settingUpLauncher.complete();

    // Generate the test runner project.
    await _generateRunner(runPubGet: true);

    // Generate the launcher file.
    final files = await _launcherGenerator.generate(
      DirectoryGeneratorTarget(projectDirectory),
      vars: launcherVars,
      logger: _logger,
      fileConflictResolution: FileConflictResolution.overwrite,
    );
    _launcherFile = File(files.first.path);

    // Install the test runner into the project.
    await _launcherGenerator.hooks.preGen(
      workingDirectory: projectDirectory.path,
      vars: launcherVars,
    );
  }

  Future<void> _cleanupGeneratedCode() async {
    // Remove the test runner project.
    await _launcherGenerator.hooks.postGen(
      workingDirectory: projectDirectory.path,
    );

    // Remove the launcher file if it exists.
    if (_launcherFile.existsSync()) {
      _launcherFile.deleteSync();
    }

    // Remove the test runner if it exists.
    if (_testRunnerDirectory.existsSync()) {
      _testRunnerDirectory.deleteSync(recursive: true);
    }
  }

  Future<void> _generateRunner({bool runPubGet = false}) async {
    userFlow = UserFlowYaml.fromFile(userFlowFile);
    await _testRunnerGenerator.generate(
      DirectoryGeneratorTarget(_testRunnerDirectory),
      vars: {
        'actions': actions.entries
            .map(
              (entry) => {
                'name': entry.key,
                'source': entry.value.source(projectDirectory),
              },
            )
            .toList(),
        'steps': userFlow.steps
            .map((step) => {'step': json.encode(step.toJson())})
            .toList(),
      },
      logger: _logger,
      fileConflictResolution: FileConflictResolution.overwrite,
    );

    if (runPubGet) {
      await _testRunnerGenerator.hooks.postGen(
        workingDirectory: _testRunnerDirectory.path,
      );
    }
  }

  Future<void> _startRunner({required bool watch}) async {
    final commandArgs = [
      'flutter',
      'run',
      _launcherFile.absolute.path,
      if (configuration.deviceId != null) ...['-d', configuration.deviceId!],
      if (configuration.flavor != null) ...['--flavor', configuration.flavor!],
      ...configuration.dartDefines.expand((e) => ['--dart-define', e]),
    ];
    _logger.detail('Running command: ${commandArgs.join(' ')}');

    final launchingTestRunner = _logger.progress('Launching the test runner');
    _process = await _processManager.start(
      commandArgs,
      runInShell: true,
      workingDirectory: projectDirectory.path,
    );

    _listener = Listener(
      _process!.stdout.map((event) {
        final regex = RegExp(
          r'^[I\/]*flutter[\s*\(\s*\d+\)]*: ',
          multiLine: true,
        );
        final data = utf8.decode(event);
        _logger.detail('driver: $data');

        final isValidAttach =
            data.startsWith(regex) || data.contains('Flutter Web Bootstrap');
        if (!_didAttach && isValidAttach) {
          _didAttach = true;
          launchingTestRunner.complete();

          if (watch) {
            // Watch the project directory for changes and hot restart the
            // runner when changes are detected.
            _subscriptions
              ..add(
                _directoryWatcher(projectDirectory.path).events.listen(
                  (event) {
                    if (!event.path.endsWith('.dart')) return;
                    restart();
                  },
                  onError: (Object err) {
                    if (err is FileSystemException &&
                        err.message.contains('Failed to watch')) {
                      return _logger.detail(err.toString());
                    }
                    // ignore: only_throw_errors
                    throw err;
                  },
                ),
              )
              // Watch the user flow file for changes and restart the driver
              // when changes are detected.
              ..add(
                _fileWatcher(userFlowFile.path)
                    .events
                    .listen((event) => restart()),
              );
          }
        }
        return utf8.encode(data.replaceAll(regex, ''));
      }),
    );

    final errorBuffer = StringBuffer();
    _subscriptions.add(
      _process!.stderr.transform(utf8.decoder).listen(
        errorBuffer.write,
        onDone: () {
          // If it exited without correctly attaching to the application, we
          // output the errors.
          if (!_didAttach) {
            launchingTestRunner.fail('Failed to start test driver');
            _logger.err(errorBuffer.toString());
          }
        },
      ),
    );
  }
}

extension on ActionLocation {
  String source(Directory relativeDirectory) {
    if (hosted != null) {
      return '''

    hosted: ${hosted!.url}
    version: ${hosted!.version}''';
    } else if (git != null) {
      if (git!.ref == null && git!.path == null) {
        return git!.url;
      }
      return '''

    git:
      url: ${git!.url}
      ref: ${git!.ref}
      path: ${git!.path}''';
    } else if (path != null) {
      return '''

    path: ${relativeDirectory.absolute.uri.resolve(path!)}''';
    }
    throw Exception('Invalid action location.');
  }
}
