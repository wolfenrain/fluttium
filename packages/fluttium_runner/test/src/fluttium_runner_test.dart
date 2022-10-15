// ignore_for_file: prefer_const_constructors

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:fluttium_runner/fluttium_runner.dart';
import 'package:mason/mason.dart';
import 'package:mocktail/mocktail.dart';
import 'package:process/process.dart';
import 'package:test/test.dart';

class MockFile extends Mock implements File {}

class MockDirectory extends Mock implements Directory {}

class MockLogger extends Mock implements Logger {}

class MockProgress extends Mock implements Progress {}

class MockProcessManager extends Mock implements ProcessManager {}

class MockProcess extends Mock implements Process {}

class MockProcessResult extends Mock implements ProcessResult {}

void main() {
  group('FluttiumRunner', () {
    late File flowFile;
    late File mainEntry;
    late Directory projectDirectory;
    late File driver;
    late Logger logger;
    late Progress progress;
    late ProcessManager processManager;
    late Process process;
    late ProcessResult flutterPubDepsResult;
    late Completer<int> processExitCode;

    setUp(() {
      mainEntry = MockFile();
      when(() => mainEntry.path).thenReturn('lib/main.dart');

      flowFile = MockFile();
      when(() => flowFile.readAsStringSync()).thenReturn('''
description: test
---
- tapOn: "Text"
- expectVisible: "Text"
- expectNotVisible: "Text"
- inputText: "Text"
- takeScreenshot: "Text"
''');
      projectDirectory = MockDirectory();
      when(() => projectDirectory.path).thenReturn('project_directory');
      driver = MockFile();
      when(() => driver.path).thenReturn(
        'project_directory/.fluttium_driver.dart',
      );

      logger = MockLogger();
      progress = MockProgress();
      when(() => logger.progress(any())).thenReturn(progress);

      processManager = MockProcessManager();

      process = MockProcess();
      processExitCode = Completer<int>();
      when(() => process.exitCode).thenAnswer(
        (_) async => processExitCode.future,
      );
      when(
        () => processManager.start(
          any(
            that: equals(
              ['flutter', 'run', '.fluttium_driver.dart', '-d', 'deviceId'],
            ),
          ),
          runInShell: any(named: 'runInShell'),
          workingDirectory: any(named: 'workingDirectory'),
        ),
      ).thenAnswer((invocation) async => process);

      when(
        () => processManager.run(
          any(),
          runInShell: any(named: 'runInShell'),
          workingDirectory: any(named: 'workingDirectory'),
        ),
      ).thenAnswer((invocation) async => MockProcessResult());

      flutterPubDepsResult = MockProcessResult();
      when(
        () => processManager.run(
          any(that: equals(['flutter', 'pub', 'deps', '--json'])),
          runInShell: any(named: 'runInShell'),
          workingDirectory: any(named: 'workingDirectory'),
        ),
      ).thenAnswer((invocation) async => flutterPubDepsResult);
    });

    test('can be instantiated', () {
      IOOverrides.runZoned(
        () async {
          when(() => flutterPubDepsResult.stdout).thenReturn(
            jsonEncode({
              'root': 'project_name',
              'packages': [
                {
                  'name': 'project_name',
                  'version': '0.0.1',
                  'kind': 'root',
                  'source': 'root',
                  'dependencies': <String>[],
                }
              ]
            }),
          );

          final fluttiumRunner = FluttiumRunner(
            flowFile: File('flow.yaml'),
            projectDirectory: Directory('project_directory'),
            deviceId: 'deviceId',
            renderer: (flow, stepStates) {},
            mainEntry: mainEntry,
            logger: logger,
            processManager: processManager,
          );

          await fluttiumRunner.run();
        },
        createFile: (path) {
          if (path == 'flow.yaml') {
            return flowFile;
          } else if (path == 'project_directory/.fluttium_driver.dart') {
            return driver;
          }
          throw UnimplementedError(path);
        },
        createDirectory: (path) {
          if (path == 'project_directory') {
            return projectDirectory;
          }
          throw UnimplementedError(path);
        },
      );
    });
  });
}
