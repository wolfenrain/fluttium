import 'dart:async';
import 'dart:convert';
import 'dart:io';

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

/// {@template host_driver}
/// A driver for executing Fluttium flow tests from the host to a flutter
/// application.
/// {@endtemplate}
class HostDriver extends FluttiumDriver {
  /// {@macro host_driver}
  HostDriver({
    required super.configuration,
    required super.actions,
    required this.projectDirectory,
    required this.userFlowFile,
    ProcessManager? processManager,
    Logger? logger,
    @visibleForTesting GeneratorBuilder? generator,
    @visibleForTesting DirectoryWatcherBuilder? directoryWatcher,
    @visibleForTesting FileWatcherBuilder? fileWatcher,
  })  : _logger = logger ?? Logger(),
        _processManager = processManager ?? const LocalProcessManager(),
        _generatorBuilder = generator ?? MasonGenerator.fromBundle,
        _directoryWatcher = directoryWatcher ?? DirectoryWatcher.new,
        _fileWatcher = fileWatcher ?? FileWatcher.new,
        assert(userFlowFile.existsSync(), 'userFlowFile does not exist'),
        super(userFlow: UserFlowYaml.fromData(userFlowFile.readAsStringSync()));

  /// The directory of the project.
  final Directory projectDirectory;

  /// The user flow file to run.
  final File userFlowFile;

  final Logger _logger;

  final ProcessManager _processManager;

  final GeneratorBuilder _generatorBuilder;

  late final MasonGenerator _testRunnerGenerator;
  late final Directory _testRunnerDirectory;

  late final MasonGenerator _launcherGenerator;
  late final File _launcherFile;

  final DirectoryWatcherBuilder _directoryWatcher;
  final FileWatcherBuilder _fileWatcher;
  final List<StreamSubscription<dynamic>> _subscriptions = [];

  @override
  Future<FlutterDaemon> getFlutterDaemon() async {
    return FlutterDaemon(processManager: _processManager);
  }

  @override
  Future<FlutterApplication?> getFlutterApplication(
    FlutterDaemon daemon,
  ) async {
    final launchingTestRunner = _logger.progress('Launching the test runner');
    try {
      final application = await daemon.run(
        arguments: [
          _launcherFile.absolute.path,
          if (configuration.deviceId != null) ...[
            '-d',
            configuration.deviceId!,
          ],
          if (configuration.flavor != null) ...[
            '--flavor',
            configuration.flavor!,
          ],
          ...configuration.dartDefines.expand((e) => ['--dart-define', e]),
        ],
        workingDirectory: projectDirectory.path,
      );

      launchingTestRunner.complete();

      return application;
    } catch (err) {
      launchingTestRunner.fail('Failed to start test driver');
      _logger.err(err.toString());
      return null;
    }
  }

  @override
  Future<void> run({bool watch = false}) async {
    try {
      return await super.run(watch: watch);
    } on FluttiumFailedToGetReady catch (err) {
      _logger.err('Failed to get ready: ${err.reason}');
    } on FluttiumFatalStepFail catch (err) {
      _logger.err('Detected fatal failure on executing steps: ${err.reason}');
    }
  }

  @override
  Future<void> onRun({required bool watch}) async {
    await _setupGeneratedCode();

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
  }

  @override
  Future<void> onRestart() async {
    // Regenerate the test runner.
    await _generateTestRunner();
  }

  @override
  Future<void> quit() async {
    await super.quit();

    // Cleanup the generated files.
    await _cleanupGeneratedCode();
  }

  @override
  Future<void> onQuit() async {
    // Cancel all the subscriptions.
    await Future.wait(_subscriptions.map((e) => e.cancel()));
    _subscriptions.clear();
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

  /// The current Fluttium version constraint that is required for [HostDriver]
  /// to work.
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

  /// The current Flutter version constraint that is required for [HostDriver]
  /// to work.
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
