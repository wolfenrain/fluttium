// ignore_for_file: prefer_const_constructors

import 'dart:async';
import 'dart:io';

import 'package:fluttium_runner/fluttium_runner.dart';
import 'package:mason/mason.dart';
import 'package:mocktail/mocktail.dart';
import 'package:process/process.dart';
import 'package:test/test.dart';

class _MockFile extends Mock implements File {}

class _MockDirectory extends Mock implements Directory {}

class _MockLogger extends Mock implements Logger {}

class _MockProgress extends Mock implements Progress {}

class _MockProcessManager extends Mock implements ProcessManager {}

class _MockProcess extends Mock implements Process {}

class _MockProcessResult extends Mock implements ProcessResult {}

void main() {
  group('FluttiumRunner', () {
    late File flowFile;
    late File mainEntry;
    late Directory projectDirectory;
    late File driver;
    late File pubspec;
    late Logger logger;
    late Progress progress;
    late ProcessManager processManager;
    late Process process;
    late ProcessResult flutterPubDepsResult;
    late Completer<int> processExitCode;

    setUp(() {
      mainEntry = _MockFile();
      when(() => mainEntry.path).thenReturn('lib/main.dart');
      when(mainEntry.existsSync).thenReturn(true);

      flowFile = _MockFile();
      when(() => flowFile.readAsStringSync()).thenReturn('''
description: test
---
- tapOn: "Text"
- expectVisible: "Text"
- expectNotVisible: "Text"
- inputText: "Text"
- takeScreenshot: "Text"
''');
      projectDirectory = _MockDirectory();
      when(() => projectDirectory.path).thenReturn('project_directory');
      driver = _MockFile();
      when(() => driver.path).thenReturn('project_directory/.test_driver.dart');

      pubspec = _MockFile();
      when(() => pubspec.path).thenReturn('project_directory/pubspec.yaml');
      when(() => pubspec.readAsStringSync()).thenReturn('''
name: test
''');

      logger = _MockLogger();
      progress = _MockProgress();
      when(() => logger.progress(any())).thenReturn(progress);

      processManager = _MockProcessManager();

      process = _MockProcess();
      processExitCode = Completer<int>();
      when(() => process.exitCode).thenAnswer(
        (_) async => processExitCode.future,
      );
      when(
        () => processManager.start(
          any(
            that: equals(
              ['flutter', 'run', '.test_driver.dart', '-d', 'deviceId'],
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
      ).thenAnswer((invocation) async => _MockProcessResult());
    });

    test('can be instantiated', () {
      IOOverrides.runZoned(
        () async {
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
          } else if (path == 'project_directory/.test_driver.dart') {
            return driver;
          } else if (path == 'project_directory/pubspec.yaml') {
            return pubspec;
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
