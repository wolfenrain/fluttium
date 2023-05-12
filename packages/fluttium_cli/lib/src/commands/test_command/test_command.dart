import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:collection/collection.dart';
import 'package:fluttium_cli/src/commands/test_command/reporters/reporters.dart';
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

/// Whether or not the current terminal supports ANSI escape codes.
///
/// Otherwise only printable ASCII characters should be used.
bool get canUseSpecialChars => stdout.supportsAnsiEscapes;

/// Whether or not the stdin has a terminal and if that terminal supports ANSI
/// escape codes.
bool get hasAnsiTerminal => stdin.hasTerminal && canUseSpecialChars;

final defaultReporter = hasAnsiTerminal
    ? 'pretty'
    : canUseSpecialChars
        ? 'compact'
        : 'expanded';

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
      ..addFlag(
        'watch',
        abbr: 'w',
        help: 'Watch for file changes.',
        negatable: false,
      )
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
      )
      ..addOption(
        'reporter',
        abbr: 'r',
        defaultsTo: defaultReporter,
        allowed: [
          'expanded',
          'pretty',
          'compact',
        ],
        allowedHelp: {
          'expanded': 'A separate line for each update.',
          'compact': 'A single line that updates dynamically.',
          'pretty': 'A nicely formatted output that works nicely with --watch.',
        },
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

  Reporter _getReporter(FluttiumDriver driver) {
    switch (results['reporter']) {
      case 'pretty':
        return PrettyReporter(driver, logger: _logger, watch: watch);
      case 'compact':
        return CompactReporter(driver, logger: _logger, watch: watch);
      case 'expanded':
        return ExpandedReporter(driver, logger: _logger, watch: watch);
      default:
        throw UnsupportedError('Unknown reporter: ${results['reporter']}');
    }
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

  List<StepState> _storeFiles(List<StepState> steps) {
    final step = steps.firstWhereOrNull((e) => e.status == StepStatus.done);
    if (step == null) return steps;
    for (final file in step.files.entries) {
      _logger.detail('Writing ${file.value.length} bytes to "${file.key}"');
      File(file.key)
        ..createSync(recursive: true)
        ..writeAsBytesSync(file.value);
    }
    return steps;
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

    final Reporter reporter;
    try {
      reporter = _getReporter(driver);
    } catch (err) {
      if (err is UnsupportedError) {
        _logger.err(err.message);
        return ExitCode.usage.code;
      }
      rethrow;
    }

    final steps = <StepState>[];
    driver.steps
        .map((s) => (steps..clear())..addAll(s))
        .map(_storeFiles)
        .listen(
          reporter.report,
          onDone: reporter.done,
          onError: reporter.error,
        );

    await driver.run(watch: watch);

    if (!steps.every((s) => s.status == StepStatus.done) || steps.isEmpty) {
      return ExitCode.tempFail.code;
    }

    return ExitCode.success.code;
  }
}
