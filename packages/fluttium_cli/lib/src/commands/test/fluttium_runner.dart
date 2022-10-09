import 'dart:convert';
import 'dart:io';

import 'package:fluttium_cli/src/commands/test/bundles/bundles.dart';
import 'package:fluttium_cli/src/flutter_device.dart';
import 'package:fluttium_flow/fluttium_flow.dart';
import 'package:mason/mason.dart';
import 'package:path/path.dart';
import 'package:watcher/watcher.dart';

class FluttiumRunner {
  FluttiumRunner({
    required this.flowFile,
    required this.projectDirectory,
    required this.device,
    required this.logger,
  });

  final File flowFile;

  /// The flow itself.
  FluttiumFlow? flow;

  final Directory projectDirectory;

  final FlutterDevice device;

  final Logger logger;

  MasonGenerator? _generator;

  final List<bool?> _stepStates = [];

  void _handleAction(String action, String? data) {
    switch (action) {
      case 'start':
        _stepStates.add(null);
        break;
      case 'fail':
        _stepStates.last = false;
        break;
      case 'done':
        _stepStates.last = true;
        break;
      case 'screenshot':
        final step = flow!.steps[_stepStates.length - 1];
        final bytes = data!.split(',').map(int.parse).toList();
        File(join(projectDirectory.path, 'screenshots', '${step.text}.png'))
          ..createSync(recursive: true)
          ..writeAsBytesSync(bytes);
        break;
      default:
        throw Exception('Unknown action: $action');
    }
  }

  Future<void> _generate(Directory tempDir, {bool withHooks = false}) async {
    flow = FluttiumFlow(flowFile.readAsStringSync());
    _generator ??= await MasonGenerator.fromBundle(fluttiumTestBundle);

    final vars = <String, dynamic>{
      'projectPath': projectDirectory.path,
      'flowDescription': flow!.description,
      'flowSteps': flow!.steps
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
    logger.info('''
\u001b[0;0H\u001b[0J
  ${styleBold.wrap(flow!.description)}
''');

    for (var i = 0; i < flow!.steps.length; i++) {
      final step = flow!.steps[i];

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

      if (i < _stepStates.length) {
        final state = _stepStates[i];
        if (state == null) {
          logger.info('  ⏳  $actionDescription');
        } else if (state) {
          logger.info('  ✅  $actionDescription');
        } else {
          logger.info('  ❌  $actionDescription');
        }
      } else {
        logger.info('  🔲  $actionDescription');
      }
    }
    logger.info('');
  }

  Future<void> run({bool watch = false}) async {
    final tempDir = Directory.systemTemp.createTempSync('fluttium');
    await _generate(tempDir, withHooks: true);

    // final startingUpTestDriver = logger.progress('Starting up test driver');
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
      if (!isCompleted &&
          data.startsWith(RegExp(r'^[I/]*flutter[\s*\(\s*\d+\)]*: '))) {
        // startingUpTestDriver.complete();
        isCompleted = true;
      }

      // Skip until the driver is ready.
      if (!isCompleted) return;

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

      for (final match in matches) {
        _handleAction(match.group(1)!, match.group(2));
      }

      _showCurrentFlowState();

      // If we have completed all the steps, or if we have failed, exit the
      // process unless we are in watch mode.
      if (!watch &&
          (_stepStates.length == flow!.steps.length ||
              _stepStates.any((e) => e == false))) {
        process.stdin.write('q');
      }
    });

    if (watch) {
      final projectWatcher = DirectoryWatcher(projectDirectory.path);
      projectWatcher.events.listen((event) {
        if (event.path.endsWith('.dart')) {
          _stepStates.clear();
          process.stdin.write('R');
        }
      });

      final flowWatcher = FileWatcher(flowFile.path);
      flowWatcher.events.listen((event) async {
        await _generate(tempDir);
        _stepStates.clear();
        process.stdin.write('R');
      });
    }

    final onSigintSubscription = ProcessSignal.sigint.watch().listen((signal) {
      process.stdin.write('q');
      tempDir.deleteSync(recursive: true);
    });

    await process.exitCode;
    await onSigintSubscription.cancel();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  }
}
