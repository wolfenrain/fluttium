import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:collection/collection.dart';
import 'package:fluttium_cli/src/flutter_device.dart';
import 'package:fluttium_flow/fluttium_flow.dart';
import 'package:fluttium_runner/fluttium_runner.dart';
import 'package:mason/mason.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart';

/// {@template test_command}
/// `fluttium test` command which runs a [FluttiumFlow] test.
/// {@endtemplate}
class TestCommand extends Command<int> {
  /// {@macro test_command}
  TestCommand({
    required Logger logger,
  }) : _logger = logger {
    argParser
      ..addFlag('watch', abbr: 'w', help: 'Watch for file changes.')
      ..addOption(
        'device-id',
        abbr: 'd',
        help: 'Target device id or name (prefixes allowed).',
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

  /// [ArgResults] used for testing purposes only.
  @visibleForTesting
  ArgResults? testArgResults;

  /// [ArgResults] for the current command.
  ArgResults get results => testArgResults ?? argResults!;

  /// Indicates whether the `--watch` flag was passed.
  bool get watch => results['watch'] as bool;

  /// The file of the flow to run.
  File get flowFile {
    if (results.arguments.isEmpty || results.arguments.first.isEmpty) {
      usageException('No flow file specified.');
    }
    final file = File(results.arguments.first);
    if (!file.existsSync()) {
      usageException('Flow file "${file.path} does not exist.');
    }
    return file;
  }

  /// The project directory to run in.
  Directory get projectDirectory {
    var projectDir = flowFile.parent.absolute;
    while (projectDir.listSync().firstWhereOrNull(
              (file) => basename(file.path) == 'pubspec.yaml',
            ) ==
        null) {
      if (projectDir.parent == projectDir) {
        usageException('Could not find pubspec.yaml in parent directories.');
      }
      projectDir = projectDir.parent;
    }
    return projectDir;
  }

  Future<FlutterDevice> getDevice(
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
      usageException('No devices found.');
    }
    final optionalDeviceId = results['device-id'] as String?;
    FlutterDevice? optionalDevice;
    if (optionalDeviceId != null) {
      progress.complete();
      optionalDevice = devices.firstWhereOrNull(
        (device) => device.id == optionalDeviceId,
      );
    } else {
      progress.cancel();
    }

    final device = optionalDevice ??
        _logger.chooseOne<FlutterDevice>(
          'Choose a device:',
          choices: devices,
          display: (device) => '${device.name} (${device.id})',
        );

    return device;
  }

  Future<List<FlutterDevice>> _getDevices(String workingDirectory) async {
    final result = await Process.run(
      'flutter',
      ['devices', '--machine'],
      runInShell: true,
      workingDirectory: workingDirectory,
    );
    final devices = (jsonDecode(result.stdout as String) as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(FlutterDevice.new)
        .toList();

    return devices.where((device) {
      if (device.targetPlatform.startsWith('web')) {
        return Directory(join(workingDirectory, 'web')).existsSync();
      } else if (device.targetPlatform.startsWith('darwin')) {
        return Directory(join(workingDirectory, 'macos')).existsSync();
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
    final projectDir = projectDirectory;
    final device = await getDevice(
      projectDir.path,
      _logger.progress('Retrieving devices'),
    );

    final runner = FluttiumRunner(
      flowFile: flowFile,
      projectDirectory: projectDir,
      deviceId: device.id,
      logger: _logger,
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

    await runner.run(watch: watch);

    stdin.lineMode = true;

    return ExitCode.success.code;
  }
}
