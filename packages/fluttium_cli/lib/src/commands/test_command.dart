import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:collection/collection.dart';
import 'package:fluttium_cli/src/flutter_device.dart';
import 'package:fluttium_flow/fluttium_flow.dart';
import 'package:fluttium_runner/fluttium_runner.dart' as fluttium;
import 'package:mason/mason.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart';
import 'package:process/process.dart';

typedef FluttiumRunner = fluttium.FluttiumRunner Function({
  required File flowFile,
  required Directory projectDirectory,
  required String deviceId,
  required fluttium.FlowRenderer renderer,
  required File mainEntry,
  required Logger logger,
  List<String> dartDefines,
  String? flavor,
  ProcessManager? processManager,
});

/// {@template test_command}
/// `fluttium test` command which runs a [FluttiumFlow] test.
/// {@endtemplate}
class TestCommand extends Command<int> {
  /// {@macro test_command}
  TestCommand({
    required Logger logger,
    ProcessManager? processManager,
    FluttiumRunner? runner,
  })  : _logger = logger,
        _process = processManager ?? const LocalProcessManager(),
        _fluttiumRunner = runner ?? fluttium.FluttiumRunner.new {
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
  String get description => 'Run a FluttiumFlow test.';

  @override
  String get name => 'test';

  @override
  String get invocation {
    return super.invocation.replaceAll('[arguments]', '<flow.yaml>');
  }

  final Logger _logger;

  final ProcessManager _process;

  final FluttiumRunner _fluttiumRunner;

  /// [ArgResults] used for testing purposes only.
  @visibleForTesting
  ArgResults? testArgResults;

  /// [ArgResults] for the current command.
  ArgResults get results => testArgResults ?? argResults!;

  /// Indicates whether the `--watch` flag was passed.
  bool get watch => results['watch'] as bool;

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
    Progress progress,
  ) async {
    final devices = await _getDevices(workingDirectory);
    if (devices.length == 1) {
      progress.complete();
      return devices.first;
    }
    if (devices.isEmpty) {
      progress.fail();
      return null;
    }
    final optionalDeviceId = results['device-id'] as String?;
    FlutterDevice? optionalDevice;
    if (optionalDeviceId != null) {
      progress.complete();
      optionalDevice = devices.firstWhereOrNull(
        (device) => device.id == optionalDeviceId.trim(),
      );
    } else {
      progress.cancel();
    }

    return optionalDevice ??
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
    final flowFile = _flowFile;
    if (!flowFile.existsSync()) {
      _logger.err('Flow file "${flowFile.path}" not found.');
      return ExitCode.unavailable.code;
    }

    final projectDirectory = _getProjectDirectory(flowFile);
    if (projectDirectory == null) {
      _logger.err('Could not find pubspec.yaml in parent directories.');
      return ExitCode.unavailable.code;
    }

    final target = _getTarget(projectDirectory);
    if (!target.existsSync()) {
      _logger.err('Target file "${results['target']}" not found.');
      return ExitCode.unavailable.code;
    }

    final device = await getDevice(
      projectDirectory.path,
      _logger.progress('Retrieving devices'),
    );
    if (device == null) {
      _logger.err('No devices found.');
      return ExitCode.unavailable.code;
    }

    final runner = _fluttiumRunner(
      flowFile: flowFile,
      projectDirectory: projectDirectory,
      deviceId: device.id,
      logger: _logger,
      processManager: _process,
      flavor: results['flavor'] as String?,
      mainEntry: target,
      dartDefines: _dartDefines,
      renderer: (flow, stepStates) {
        // Reset the cursor to the top of the screen and clear the screen.
        _logger.info('''
\u001b[0;0H\u001b[0J
  ${styleBold.wrap(flow.description)}
''');

        for (var i = 0; i < flow.steps.length; i++) {
          final step = flow.steps[i];

          final String actionDescription;
          switch (step.action) {
            case FluttiumAction.expectVisible:
              actionDescription = 'Expect visible "${step.text}"';
              break;
            case FluttiumAction.expectNotVisible:
              actionDescription = 'Expect not visible "${step.text}"';
              break;
            case FluttiumAction.tapOn:
              actionDescription = 'Tap on "${step.text}"';
              break;
            case FluttiumAction.inputText:
              actionDescription = 'Input text "${step.text}"';
              break;
            case FluttiumAction.takeScreenshot:
              actionDescription = 'Screenshot "${step.text}"';
              break;
          }

          if (i < stepStates.length) {
            final state = stepStates[i];
            if (state == null) {
              _logger.info('  ⏳  $actionDescription');
            } else if (state) {
              _logger.info('  ✅  $actionDescription');
            } else {
              _logger.info('  ❌  $actionDescription');
            }
          } else {
            _logger.info('  🔲  $actionDescription');
          }
        }
        _logger.info('');
        if (watch) {
          _logger.info('''
  ${styleDim.wrap('Press')} r ${styleDim.wrap('to restart the test.')}
  ${styleDim.wrap('Press')} q ${styleDim.wrap('to quit.')}''');
        }
      },
    );

    if (watch) {
      stdin.echoMode = false;
      stdin.lineMode = false;

      stdin.listen((event) {
        final key = utf8.decode(event).trim();
        switch (key) {
          case 'q':
            runner.quit();
            break;
          case 'r':
            runner.restart();
            break;
        }
      });
    }

    await runner.run(watch: watch);

    if (watch) {
      stdin.lineMode = true;
      stdin.echoMode = true;
    }

    return ExitCode.success.code;
  }
}
