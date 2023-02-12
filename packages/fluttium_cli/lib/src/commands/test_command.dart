import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:collection/collection.dart';
import 'package:fluttium_cli/src/flutter_device.dart';
import 'package:fluttium_cli/src/json_decode_safely.dart';
import 'package:fluttium_driver/fluttium_driver.dart';
import 'package:fluttium_interfaces/fluttium_interfaces.dart';
import 'package:mason/mason.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart';
import 'package:process/process.dart';

typedef FluttiumDriverCreator = FluttiumDriver Function({
  required DriverConfiguration configuration,
  required Map<String, ActionLocation> actions,
  required Directory projectDirectory,
  required File userFlowFile,
  Logger? logger,
  ProcessManager? processManager,
});

/// {@template test_command}
/// `fluttium test` command which runs a [UserFlowYaml] test.
/// {@endtemplate}
class TestCommand extends Command<int> {
  /// {@macro test_command}
  TestCommand({
    required Logger logger,
    ProcessManager? processManager,
    FluttiumDriverCreator? driver,
  })  : _logger = logger,
        _process = processManager ?? const LocalProcessManager(),
        _driver = driver ?? FluttiumDriver.new {
    argParser
      ..addFlag('watch', abbr: 'w', help: 'Watch for file changes.')
      ..addOption(
        'device-id',
        abbr: 'd',
        help: 'Target device id or name (prefixes allowed).',
      )
      ..addOption(
        'flavor',
        help: '''
Build a custom app flavor as defined by platform-specific build setup.
This will be passed to the --flavor option of flutter run.''',
      )
      ..addOption(
        'target',
        abbr: 't',
        help:
            '''The main entry-point file of the application, as run on the device.''',
        defaultsTo: 'lib/main.dart',
      )
      ..addMultiOption(
        'dart-define',
        valueHelp: 'key=value',
        help: '''
Pass additional key-value pairs to the flutter run.
Multiple defines can be passed by repeating "--dart-define" multiple times.''',
      );
  }

  @override
  String get description => 'Run a user flow test.';

  @override
  String get name => 'test';

  @override
  String get invocation {
    return super.invocation.replaceAll('[arguments]', '<flow.yaml>');
  }

  final Logger _logger;

  final ProcessManager _process;

  final FluttiumDriverCreator _driver;

  /// [ArgResults] used for testing purposes only.
  @visibleForTesting
  ArgResults? testArgResults;

  /// [ArgResults] for the current command.
  ArgResults get results => testArgResults ?? argResults!;

  /// Indicates whether the `--watch` flag was passed.
  bool get watch => results['watch'] as bool;

  String? get _flavor => results['flavor'] as String?;

  List<String> get _dartDefines => results['dart-define'] as List<String>;

  /// The file of the flow to run.
  File get _flowFile {
    if (results.arguments.isEmpty || results.arguments.first.isEmpty) {
      usageException('No flow file specified.');
    }
    return File(results.arguments.first);
  }

  /// The project directory to run in.
  Directory? _getProjectDirectory(File file) {
    var projectDir = file.parent.absolute;
    while (projectDir.listSync().firstWhereOrNull(
              (file) => basename(file.path) == 'pubspec.yaml',
            ) ==
        null) {
      if (projectDir.parent == projectDir) {
        return null;
      }
      projectDir = projectDir.parent;
    }
    return projectDir;
  }

  /// The target file to run.
  File _getTarget(Directory directory) {
    final target = results['target'] as String;
    return File(join(directory.path, target));
  }

  Future<FlutterDevice?> getDevice(
    String workingDirectory,
    FluttiumYaml fluttium,
  ) async {
    final retrievingDevices = _logger.progress('Retrieving devices');
    final devices = await _getDevices(workingDirectory);
    if (devices.isEmpty) {
      retrievingDevices.fail();
      return null;
    }

    FlutterDevice? device;
    if (devices.length == 1) {
      device = devices.first;
    } else {
      final optionalDeviceId = results['device-id'] as String?;
      if (optionalDeviceId != null && optionalDeviceId.isNotEmpty) {
        retrievingDevices.complete();
        device = devices.firstWhereOrNull(
          (device) => device.id == optionalDeviceId.trim(),
        );
      } else {
        retrievingDevices.cancel();
      }
    }

    return device ??
        _logger.chooseOne<FlutterDevice>(
          'Choose a device:',
          choices: devices,
          display: (device) => '${device.name} (${device.id})',
        );
  }

  Future<List<FlutterDevice>> _getDevices(String workingDirectory) async {
    final result = await _process.run(
      ['flutter', '--no-version-check', 'devices', '--machine'],
      runInShell: true,
      workingDirectory: workingDirectory,
    );
    final devices = (jsonDecodeSafely(result.stdout as String) as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(FlutterDevice.new)
        .toList();

    return devices.where((device) {
      if (!device.isSupported) return false;

      if (device.targetPlatform.startsWith('web')) {
        return Directory(join(workingDirectory, 'web')).existsSync();
      } else if (device.targetPlatform.startsWith('darwin')) {
        return Directory(join(workingDirectory, 'macos')).existsSync();
      } else if (device.targetPlatform.startsWith('linux')) {
        return Directory(join(workingDirectory, 'linux')).existsSync();
      } else if (device.targetPlatform.startsWith('windows')) {
        return Directory(join(workingDirectory, 'windows')).existsSync();
      } else if (device.targetPlatform.startsWith('ios')) {
        return Directory(join(workingDirectory, 'ios')).existsSync();
      } else if (device.targetPlatform.startsWith('android')) {
        return Directory(join(workingDirectory, 'android')).existsSync();
      }
      return false;
    }).toList();
  }

  @override
  Future<int> run() async {
    final userFlowFile = _flowFile;
    if (!userFlowFile.existsSync()) {
      _logger.err('Flow file "${userFlowFile.path}" not found.');
      return ExitCode.unavailable.code;
    }

    final projectDirectory = _getProjectDirectory(userFlowFile);
    if (projectDirectory == null) {
      _logger.err('Could not find pubspec.yaml in parent directories.');
      return ExitCode.unavailable.code;
    }

    final target = _getTarget(projectDirectory);
    if (!target.existsSync()) {
      _logger.err('Target file "${results['target']}" not found.');
      return ExitCode.unavailable.code;
    }

    var fluttium = FluttiumYaml(
      environment: FluttiumEnvironment(
        // TODO: get version from bundle?
        fluttium: VersionConstraint.parse('any'),
      ),
    );
    final fluttiumFile = File(join(projectDirectory.path, 'fluttium.yaml'));
    if (fluttiumFile.existsSync()) {
      fluttium = FluttiumYaml.fromFile(fluttiumFile);
    }

    final device = await getDevice(projectDirectory.path, fluttium);

    fluttium = fluttium.copyWith(
      driver: fluttium.driver.copyWith(
        deviceId: device?.id,
        mainEntry: target.path,
        flavor: _flavor,
        dartDefines: [
          ...fluttium.driver.dartDefines,
          ..._dartDefines,
        ],
      ),
    );

    // TODO(wolfen): check `fluttium.environment`

    if (fluttium.driver.deviceId == null) {
      _logger.err('No devices found.');
      return ExitCode.unavailable.code;
    }

    final driver = _driver(
      configuration: fluttium.driver,
      actions: fluttium.actions,
      projectDirectory: projectDirectory,
      userFlowFile: userFlowFile,
      logger: _logger,
      processManager: _process,
    );

    driver.steps.listen((steps) {
      // Reset the cursor to the top of the screen and clear the screen.
      _logger.info('''
\u001b[0;0H\u001b[0J
  ${styleBold.wrap(driver.userFlow.description)}
''');

      // Render the steps.
      for (final step in steps) {
        switch (step.status) {
          case StepStatus.initial:
            _logger.info('  🔲  ${step.description}');
            break;
          case StepStatus.running:
            _logger.info('  ⏳  ${step.description}');
            break;
          case StepStatus.done:
            _logger.info('  ✅  ${step.description}');
            for (final file in step.files.entries) {
              _logger.detail('Writing ${file.value.length} bytes to $file');
              File(file.key)
                ..createSync(recursive: true)
                ..writeAsBytesSync(file.value);
            }
            break;
          case StepStatus.failed:
            _logger.info('  ❌  ${step.description}');
            break;
        }
      }

      _logger.info('');
      if (watch) {
        _logger.info('''
  ${styleDim.wrap('Press')} r ${styleDim.wrap('to restart the test.')}
  ${styleDim.wrap('Press')} q ${styleDim.wrap('to quit.')}''');
      }
    });

    if (watch) {
      stdin
        ..echoMode = false
        ..lineMode = false
        ..listen((event) async {
          switch (utf8.decode(event).trim()) {
            case 'q':
              return driver.quit();
            case 'r':
              return driver.restart();
          }
        });
    }

    await driver.run(watch: watch);

    if (watch) {
      stdin
        ..lineMode = true
        ..echoMode = true;
    }

    return ExitCode.success.code;
  }
}
