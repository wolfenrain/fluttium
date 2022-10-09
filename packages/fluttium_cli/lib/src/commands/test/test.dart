import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:collection/collection.dart';
import 'package:fluttium_cli/src/commands/test/fluttium_runner.dart';
import 'package:fluttium_cli/src/flutter_device.dart';
import 'package:fluttium_flow/fluttium_flow.dart';
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
  String get description => 'A sample sub command that just prints one joke';

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
    progress.cancel();
    if (devices.length == 1) {
      return devices.first;
    }

    final deviceId = (results['device-id'] as String?) ??
        _logger.chooseOne(
          'Choose a device:',
          choices: devices.map((d) => d.name).toList(),
        );

    final device = devices.firstWhereOrNull(
      (device) =>
          device.id.startsWith(deviceId) || device.name.startsWith(deviceId),
    );
    if (device == null) {
      usageException('Device "$deviceId" not found.');
    }
    return device;
  }

  Future<List<FlutterDevice>> _getDevices(String workingDirectory) async {
    final result = await Process.run(
      'flutter',
      ['devices', '--machine'],
      runInShell: true,
      workingDirectory: workingDirectory,
    );
    final devices = jsonDecode(result.stdout as String) as List<dynamic>;

    return devices.cast<Map<String, dynamic>>().map(FlutterDevice.new).toList();
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
      device: device,
      logger: _logger,
    );

    await runner.run(watch: watch);

    return ExitCode.success.code;
  }
}
