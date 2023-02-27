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
  String get invocation => 'fluttium test <flow.yaml> [arguments]';

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
  File get _userFlowFile {
    if (results.rest.isEmpty || results.rest.first.isEmpty) {
      usageException('No flow file specified.');
    }
    return File(results.rest.first);
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
      retrievingDevices.complete();
    } else {
      retrievingDevices.cancel();
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
    final userFlowFile = _userFlowFile;
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

    // Setup a fluttium config file, if there is no fluttium.yaml we set up a
    // basic one.
    FluttiumYaml fluttium;
    final fluttiumFile = File(join(projectDirectory.path, 'fluttium.yaml'));
    if (fluttiumFile.existsSync()) {
      fluttium = FluttiumYaml.fromData(fluttiumFile.readAsStringSync());
    } else {
      fluttium = FluttiumYaml(
        environment: FluttiumEnvironment(
          fluttium: FluttiumDriver.fluttiumVersionConstraint,
        ),
      );
    }

    if (!fluttium.environment.fluttium
        .allowsAny(FluttiumDriver.fluttiumVersionConstraint)) {
      _logger.err(
        '''
Version solving failed:
  The Fluttium CLI uses "${FluttiumDriver.fluttiumVersionConstraint}" as the version constraint.
  The current project uses "${fluttium.environment.fluttium}" as defined in the fluttium.yaml.

Either adjust the constraint in the Fluttium configuration or update the CLI to a compatible version.''',
      );
      return ExitCode.unavailable.code;
    }

    // Setup the driver config for Fluttium.
    fluttium = fluttium.copyWith(
      driver: fluttium.driver.copyWith(
        target: results.wasParsed('target') ? target.path : null,
        flavor: _flavor,
        dartDefines: [...fluttium.driver.dartDefines, ..._dartDefines],
        deviceId: results['device-id'] as String?,
      ),
    );

    // Retrieve the device to run on.
    if (fluttium.driver.deviceId == null) {
      final device = await getDevice(projectDirectory.path, fluttium);
      fluttium = fluttium.copyWith(
        driver: fluttium.driver.copyWith(deviceId: device?.id),
      );
    }

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

    final stepStates = <StepState>[];
    final printer =
        (stdin.hasTerminal ? PrettyPrinter.new : SimplePrinter.new)(_logger);

    driver.steps.listen(
      (steps) {
        stepStates
          ..clear()
          ..addAll(steps);

        printer.print(steps, driver.userFlow, watch);
      },
      onDone: printer.done,
      onError: (Object err) {
        if (err is FatalDriverException) {
          _logger.err(' Fatal driver exception occurred: ${err.reason}');
          return driver.quit();
        }
        _logger.err('Unknown exception occurred: $err');
      },
    );

    if (watch) {
      if (!stdin.hasTerminal) {
        throw UnsupportedError('Watch provided but no terminal was attached');
      }
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

    if (watch && stdin.hasTerminal) {
      stdin
        ..lineMode = true
        ..echoMode = true;
    }

    if (!stepStates.every((s) => s.status == StepStatus.done) ||
        stepStates.isEmpty) {
      return ExitCode.tempFail.code;
    }

    return ExitCode.success.code;
  }
}

abstract class Printer {
  Printer(this.logger);

  final Logger logger;

  void print(List<StepState> steps, UserFlowYaml userFlow, bool watch);

  void done();
}

class SimplePrinter extends Printer {
  SimplePrinter(super.logger);

  Progress? _progress;

  @override
  void print(List<StepState> steps, UserFlowYaml userFlow, bool watch) {
    final currentStep = steps.lastWhere(
      (step) => step.status != StepStatus.initial,
      orElse: () => steps.first,
    );
    if (steps.every((e) => e.status == StepStatus.done)) return;
    _progress ??= logger.progress('');

    final index = steps.indexOf(currentStep) + 1;
    _progress?.update('$index/${steps.length} ${currentStep.description}');

    if (currentStep.status == StepStatus.failed) {
      _progress?.fail();
    }
  }

  @override
  void done() {
    _progress?.complete();
  }
}

class PrettyPrinter extends Printer {
  PrettyPrinter(super.logger);

  @override
  void print(List<StepState> steps, UserFlowYaml userFlow, bool watch) {
    // Reset the cursor to the top of the screen and clear the screen.
    logger.info('''
\u001b[0;0H\u001b[0J
  ${styleBold.wrap(userFlow.description)}
''');

    // Render the steps.
    for (final step in steps) {
      switch (step.status) {
        case StepStatus.initial:
          logger.info('  🔲  ${step.description}');
          break;
        case StepStatus.running:
          logger.info('  ⏳  ${step.description}');
          break;
        case StepStatus.done:
          logger.info('  ✅  ${step.description}');
          for (final file in step.files.entries) {
            logger.detail('Writing ${file.value.length} bytes to $file');
            File(file.key)
              ..createSync(recursive: true)
              ..writeAsBytesSync(file.value);
          }
          break;
        case StepStatus.failed:
          logger.info('  ❌  ${step.description}');
          break;
      }
    }

    logger.info('');
    if (watch) {
      logger.info('''
  ${styleDim.wrap('Press')} r ${styleDim.wrap('to restart the test.')}
  ${styleDim.wrap('Press')} q ${styleDim.wrap('to quit.')}''');
    }
  }

  @override
  void done() {}
}
