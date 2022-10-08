import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:collection/collection.dart';
import 'package:fluttium_cli/src/bundles/fluttium_test_bundle.dart';
import 'package:fluttium_cli/src/flutter_device.dart';
import 'package:fluttium_flow/fluttium_flow.dart';
import 'package:mason/mason.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart';
import 'package:watcher/watcher.dart';

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

  /// The flow itself.
  FluttiumFlow get flow => FluttiumFlow(flowFile.readAsStringSync());

  /// The project directory to run in.
  Directory get projectDirectory {
    if (_projectDirectory != null) return _projectDirectory!;

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
    return _projectDirectory ??= projectDir;
  }

  Directory? _projectDirectory;

  Future<FlutterDevice> getDevice(String workingDirectory) async {
    final devices = await _getDevices(workingDirectory);
    if (devices.length == 1) {
      return devices.first;
    }

    final deviceId = (results['device-id'] as String?) ??
        _logger.chooseOne(
          'Please choose the device on which you want to run:',
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

  late List<bool?> stepStates = [];

  MasonGenerator? _generator;

  @override
  Future<int> run() async {
    final projectDir = projectDirectory;
    final device = await getDevice(projectDir.path);

    final tempDir = Directory(join(Directory.current.path, 'temp'))
      ..deleteAndCreateSync();

    await _generate(tempDir, withHooks: true);

    final startingUpTestDriver = _logger.progress('Starting up test driver');
    final process = await Process.start(
      'flutter',
      ['run', 'fluttium_test.dart', '-d', device.id],
      runInShell: true,
      workingDirectory: tempDir.path,
    );

    var isCompleted = false;
    final buffer = StringBuffer();
    process.stdout.listen((event) async {
      final data = utf8.decode(event).trim();
      buffer.write(data);

      // Skip until we see the first line of the test output.
      if (!isCompleted && data.startsWith('flutter: ')) {
        startingUpTestDriver.complete();
        isCompleted = true;
      }

      // Skip until the driver is ready.
      if (!isCompleted) {
        return;
      }

      final regex = RegExp('fluttium:(start|fail|done|screenshot):(.*?);');
      final matches = regex.allMatches(buffer.toString());

      // If matches is not empty, clear the buffer and check if the last match
      // is the end of the buffer. If it is not, we add what is left back to
      // the buffer.
      if (matches.isNotEmpty) {
        final content = buffer.toString();
        final lastMatch = matches.last;

        buffer.clear();
        if (content.length > lastMatch.end) {
          buffer.write(content.substring(lastMatch.end));
        }
      }

      // For each action we have received, update the step states
      for (final match in matches) {
        final action = match.group(1);
        switch (action) {
          case 'start':
            stepStates.add(null);
            break;
          case 'fail':
            stepStates.last = false;
            break;
          case 'done':
            stepStates.last = true;
            break;
          case 'screenshot':
            final step = flow.steps[stepStates.length - 1];
            final bytes = match.group(2)!.split(',').map(int.parse).toList();
            File(join(projectDir.path, 'screenshots', '${step.text}.png'))
              ..createSync(recursive: true)
              ..writeAsBytesSync(bytes);
            break;
          default:
            throw Exception('Unknown action: $action');
        }
      }

      _showCurrentFlowState();

      // If we have completed all the steps, or if we have failed, exit the
      // process unless we are in watch mode.
      if (!watch &&
          (stepStates.length == flow.steps.length ||
              stepStates.any((e) => e == false))) {
        process.stdin.write('q');
      }
    });

    if (watch) {
      final projectWatcher = DirectoryWatcher(projectDir.path);
      projectWatcher.events.listen((event) {
        if (event.path.endsWith('.dart')) {
          stepStates.clear();
          process.stdin.write('R');
        }
      });

      final flowWatcher = FileWatcher(flowFile.path);
      flowWatcher.events.listen((event) async {
        await _generate(tempDir);
        stepStates.clear();
        process.stdin.write('R');
      });
    }

    await process.exitCode;
    tempDir.deleteSync(recursive: true);
    _logger.info('');
    return ExitCode.success.code;
  }

  Future<void> _generate(Directory tempDir, {bool withHooks = false}) async {
    _generator ??= await MasonGenerator.fromBundle(fluttiumTestBundle);

    final vars = <String, dynamic>{
      'projectPath': projectDirectory.path,
      'flowDescription': flow.description,
      'flowSteps': flow.steps
          .map((e) {
            switch (e.action) {
              case FluttiumAction.expectVisible:
                return "await tester.expectVisible('${e.text}');";
              case FluttiumAction.expectNotVisible:
                return "await tester.expectNotVisible('${e.text}');";
              case FluttiumAction.tapOn:
                return "await tester.tapOn('${e.text}');";
              case FluttiumAction.inputText:
                return "await tester.inputText('${e.text}');";
              case FluttiumAction.takeScreenshot:
                return "await tester.takeScreenshot('${e.text}');";
            }
          })
          .map((e) => {'step': e})
          .toList(),
    };
    if (withHooks) {
      await _generator!.hooks.preGen(
        vars: vars,
        workingDirectory: tempDir.path,
      );
    }
    await _generator!.generate(DirectoryGeneratorTarget(tempDir), vars: vars);
  }

  void _showCurrentFlowState() {
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
  }
}

extension on Directory {
  void deleteAndCreateSync({bool recursive = true}) {
    if (existsSync()) {
      deleteSync(recursive: recursive);
    }
    createSync(recursive: recursive);
  }
}
