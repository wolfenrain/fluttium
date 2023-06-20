import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:clock/clock.dart';
import 'package:flutter_daemon/flutter_daemon.dart';
import 'package:fluttium_driver/fluttium_driver.dart';
import 'package:fluttium_driver/src/bundles/bundles.dart';
import 'package:fluttium_interfaces/fluttium_interfaces.dart';
import 'package:mason/mason.dart' hide canonicalize;
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
        _stepStateController = StreamController.broadcast(),
        _filesController = StreamController.broadcast(),
        assert(userFlowFile.existsSync(), 'userFlowFile does not exist') {
    userFlow = UserFlowYaml.fromData(userFlowFile.readAsStringSync());
    _stepStates = userFlow.steps.map(UserFlowStepState.new).toList();
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
  /// The steps are emitted as a list of [UserFlowStepState]s representing the
  /// current state of those steps, the list is ordered by the order of
  /// execution.
  late final Stream<List<UserFlowStepState>> steps =
      _stepStateController.stream;
  final StreamController<List<UserFlowStepState>> _stepStateController;
  late final List<UserFlowStepState> _stepStates;

  /// Stream of files that should be stored.
  late final Stream<StoredFile> files = _filesController.stream;
  final StreamController<StoredFile> _filesController;

  final Logger _logger;

  final ProcessManager _processManager;

  FlutterDaemon? _daemon;
  FlutterApplication? _application;

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
    _application = await _launchTestRunner();
    if (_application == null) return;

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
          _fileWatcher(userFlowFile.path).events.listen((event) => restart()),
        );
    }

    await _executeSteps();

    // If all steps were done, or if a step failed, stop the process unless
    // we're in watch mode.
    if (!watch &&
        (_stepStates.every((e) => e.status == StepStatus.done) ||
            _stepStates.any((e) => e.status == StepStatus.failed))) {
      return quit();
    }

    // Wait for Daemon to finish.
    await _daemon?.finished;

    await quit();
  }

  /// Restart the runner and the driver.
  Future<void> restart() async {
    if (_restarting || _daemon == null) return;
    _restarting = true;

    // Regenerate the test runner.
    await _generateTestRunner();

    // Tell the daemon to restart the runner.
    await _application?.restart();
    _restarting = false;

    await _executeSteps();
  }

  /// Close the runner and it's driver.
  Future<void> quit() async {
    // Cancel all the subscriptions.
    await Future.wait(_subscriptions.map((e) => e.cancel()));
    _subscriptions.clear();

    // Close the step state controller.
    await _stepStateController.close();

    // Tell the daemon to stop the runner.
    if (!(_daemon?.isFinished ?? true)) {
      await _application?.stop();
    }
    await _daemon?.dispose();

    // Cleanup the generated files.
    await _cleanupGeneratedCode();
  }

  Future<void> _setupGeneratedCode() async {
    // Setup the test runner.
    final settingUpTestRunner = _logger.progress('Setting up the test runner');
    _testRunnerGenerator = await _generatorBuilder(fluttiumTestRunnerBundle);
    _testRunnerDirectory = Directory.systemTemp.createTempSync('fluttium_');
    settingUpTestRunner.complete();

    // Setup the launcher.
    final settingUpLauncher = _logger.progress('Setting up the launcher');
    final projectData = loadYaml(
      File(join(projectDirectory.path, 'pubspec.yaml')).readAsStringSync(),
    ) as YamlMap;

    _launcherGenerator = await _generatorBuilder(fluttiumLauncherBundle);
    final launcherVars = {
      'runner_id': basename(_testRunnerDirectory.path),
      'project_name': projectData['name'],
      'target': configuration.target
          .replaceFirst('${projectDirectory.path}/', '')
          .replaceFirst('lib/', ''),
      'runner_path': _testRunnerDirectory.path,
    };
    settingUpLauncher.complete();

    // Generate the test runner project.
    await _generateTestRunner(runPubGet: true);

    // Install the test runner into the project.
    await _launcherGenerator.hooks.preGen(
      workingDirectory: projectDirectory.path,
      vars: launcherVars,
    );

    // Generate the launcher file.
    final files = await _launcherGenerator.generate(
      DirectoryGeneratorTarget(projectDirectory),
      vars: launcherVars,
      logger: _logger,
      fileConflictResolution: FileConflictResolution.overwrite,
    );
    _launcherFile = File(files.first.path);
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

  Future<void> _generateTestRunner({bool runPubGet = false}) async {
    userFlow = UserFlowYaml.fromData(userFlowFile.readAsStringSync());
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

  Future<FlutterApplication?> _launchTestRunner() async {
    _daemon = FlutterDaemon(processManager: _processManager);

    final launchingTestRunner = _logger.progress('Launching the test runner');
    try {
      final application = await _daemon?.run(
        arguments: [
          _launcherFile.absolute.path,
          if (configuration.deviceId != null) ...[
            '-d',
            configuration.deviceId!
          ],
          if (configuration.flavor != null) ...[
            '--flavor',
            configuration.flavor!
          ],
          ...configuration.dartDefines.expand((e) => ['--dart-define', e]),
        ],
        workingDirectory: projectDirectory.path,
      );

      launchingTestRunner.complete();

      await Future<void>.delayed(const Duration(seconds: 5));

      return application;
    } catch (err) {
      await _daemon?.dispose();
      launchingTestRunner.fail('Failed to start test driver');
      _logger.err(err.toString());
      return null;
    }
  }

  Future<void> _executeSteps() async {
    _stepStates
      ..clear()
      ..addAll(userFlow.steps.map(UserFlowStepState.new));

    // The service extensions might not be setup yet, so we wait at most 30
    // seconds and constantly trying half a second to determine if it is setup.
    AppCallServiceExtensionResponse? readyResponse;
    final timeout = clock.now().add(const Duration(seconds: 30));
    while (readyResponse?.result?['ready'] != true) {
      readyResponse = await _application!.callServiceExtension(
        'ext.fluttium.ready',
      );

      if (readyResponse.hasError || readyResponse.result!['ready'] == false) {
        if (clock.now().isBefore(timeout)) {
          await Future<void>.delayed(Duration.zero);
          continue;
        }

        return _logger.err(
          '''Failed to get ready: ${readyResponse.error ?? readyResponse.result!['reason'] as String?}''',
        );
      }
    }

    // Get all action descriptions and announce them.
    for (var i = 0; i < _stepStates.length; i++) {
      final response = await _application!.callServiceExtension(
        'ext.fluttium.getActionDescription',
        params: {
          'name': _stepStates[i].step.actionName,
          'arguments': json.encode(_stepStates[i].step.arguments),
        },
      );
      if (response.hasError) return _logger.err('Failed: ${response.error}');

      _stepStates[i] = _stepStates[i].copyWith(
        description: response.result!['description'] as String,
      );
    }
    _stepStateController.add(_stepStates);

    for (var i = 0; i < _stepStates.length; i++) {
      _stepStates[i] = _stepStates[i].copyWith(status: StepStatus.running);
      _stepStateController.add(_stepStates);
      final response = await _application!.callServiceExtension(
        'ext.fluttium.executeAction',
        params: {
          'name': _stepStates[i].step.actionName,
          'arguments': json.encode(_stepStates[i].step.arguments),
        },
      );

      final hasError =
          response.hasError || response.result!['success'] == false;

      if (hasError) {
        _stepStates[i] = _stepStates[i].copyWith(
          status: StepStatus.failed,
          failReason: response.error ?? response.result!['reason'] as String?,
        );
      } else {
        final files = response.result!['files'] as Map<String, dynamic>;
        if (files.isNotEmpty) {
          for (final key in files.keys) {
            _filesController.add(
              StoredFile(key, base64.decode(files[key]! as String)),
            );
          }
        }
        _stepStates[i] = _stepStates[i].copyWith(
          status: StepStatus.done,
          // ignore: deprecated_member_use_from_same_package
          files: files.map((k, v) => MapEntry(k, base64.decode(v as String))),
        );
      }
      _stepStateController.add(_stepStates);

      // We had an error, do not continue.
      if (hasError) break;
    }
  }

  /// The current Fluttium version constraint that the driver needs to work.
  static VersionRange get fluttiumVersionConstraint {
    final content = utf8.decode(
      base64.decode(
        fluttiumTestRunnerBundle.files
            .firstWhere((e) => e.path == 'pubspec.yaml')
            .data,
      ),
    );

    final version = RegExp('  fluttium: "(.*?)"{').firstMatch(content)!;
    return VersionConstraint.parse(version.group(1)!) as VersionRange;
  }

  /// The current Fluttium version constraint that the driver needs to work.
  static VersionRange get flutterVersionConstraint {
    final content = utf8.decode(
      base64.decode(
        fluttiumTestRunnerBundle.files
            .firstWhere((e) => e.path == 'pubspec.yaml')
            .data,
      ),
    );

    final version = RegExp('  flutter: "(.*?)"\n').firstMatch(content)!;
    return VersionConstraint.parse(version.group(1)!) as VersionRange;
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
    }

    // Else it is a path location
    return '''

    path: ${canonicalize(join(relativeDirectory.absolute.path, path))}''';
  }
}
