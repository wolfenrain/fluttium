// ignore_for_file: prefer_const_constructors

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:fluttium_driver/fluttium_driver.dart';
import 'package:fluttium_driver/src/bundles/bundles.dart';
import 'package:fluttium_interfaces/fluttium_interfaces.dart';
import 'package:mason/mason.dart';
import 'package:mocktail/mocktail.dart';
import 'package:process/process.dart';
import 'package:test/test.dart';
import 'package:watcher/watcher.dart';

class _FakeDirectoryGeneratorTarget extends Fake
    implements DirectoryGeneratorTarget {}

class _MockFile extends Mock implements File {}

class _MockDirectory extends Mock implements Directory {}

class _MockLogger extends Mock implements Logger {}

class _MockProgress extends Mock implements Progress {}

class _MockProcessManager extends Mock implements ProcessManager {}

class _MockProcess extends Mock implements Process {}

class _MockMasonGenerator extends Mock implements MasonGenerator {}

class _MockIOSink extends Mock implements IOSink {}

class _MockDirectoryWatcher extends Mock implements DirectoryWatcher {}

class _MockFileWatcher extends Mock implements FileWatcher {}

void main() {
  group('FluttiumDriver', () {
    late MasonGenerator launcherGenerator;
    late MasonGenerator runnerGenerator;
    late GeneratorBuilder generatorBuilder;
    late Progress settingUpTestRunner;
    late Directory testRunnerDirectory;
    late File userFlowFile;
    late Directory projectDirectory;
    late File launcher;

    late File pubspec;
    late Logger logger;
    late Progress startingUpTestDriverProgress;
    late ProcessManager processManager;
    late Process process;
    late IOSink sink;
    late StreamController<List<int>> stdoutController;
    late StreamController<List<int>> stderrController;
    late Completer<int> processExitCode;
    late List<StepState> testStepStates;
    late File screenshot;

    setUpAll(() {
      registerFallbackValue(_FakeDirectoryGeneratorTarget());
    });

    setUp(() {
      launcherGenerator = _MockMasonGenerator();
      when(() => launcherGenerator.generate(any(), vars: any(named: 'vars')))
          .thenAnswer(
        (invocation) async => [
          GeneratedFile.created(
            path: 'project_directory/.fluttium_test_launcher.dart',
          )
        ],
      );

      runnerGenerator = _MockMasonGenerator();
      when(() => runnerGenerator.generate(any(), vars: any(named: 'vars')))
          .thenAnswer(
        (invocation) async => [],
      );

      generatorBuilder = (MasonBundle bundle) {
        if (bundle == fluttiumLauncherBundle) {
          return launcherGenerator;
        }
        return runnerGenerator;
      };

      logger = _MockLogger();
      settingUpTestRunner = _MockProgress();
      when(() => logger.progress(any(that: equals('Setting up test runner'))))
          .thenReturn(settingUpTestRunner);

      testRunnerDirectory = _MockDirectory();

      userFlowFile = _MockFile();
      when(() => userFlowFile.readAsStringSync()).thenReturn('''
description: test
---
- tapOn: Text
- expectVisible: Text
''');
      when(() => userFlowFile.path).thenReturn('flow.yaml');

      projectDirectory = _MockDirectory();
      when(() => projectDirectory.path).thenReturn('project_directory');
      launcher = _MockFile();
      when(() => launcher.path)
          .thenReturn('project_directory/.fluttium_test_launcher.dart');
      when(() => launcher.existsSync()).thenReturn(true);

      pubspec = _MockFile();
      when(() => pubspec.path).thenReturn('project_directory/pubspec.yaml');
      when(() => pubspec.readAsStringSync()).thenReturn('''
name: project_name
''');

      processManager = _MockProcessManager();

      process = _MockProcess();
      processExitCode = Completer<int>();
      when(() => process.exitCode).thenAnswer(
        (_) async => processExitCode.future,
      );
      sink = _MockIOSink();
      when(() => sink.write(any(that: equals('q')))).thenAnswer((_) {
        processExitCode.complete(ExitCode.success.code);
      });
      when(() => process.stdin).thenReturn(sink);

      stdoutController = StreamController<List<int>>();
      when(() => process.stdout).thenAnswer(
        (_) => stdoutController.stream,
      );
      stderrController = StreamController<List<int>>();
      when(() => process.stderr).thenAnswer(
        (_) => stderrController.stream,
      );

      when(
        () => processManager.start(
          any(
            that: containsAllInOrder(
              [
                'flutter',
                'run',
                'project_directory/.fluttium_test_launcher.dart',
                '-d',
                'deviceId'
              ],
            ),
          ),
          runInShell: any(named: 'runInShell'),
          workingDirectory: any(
            named: 'workingDirectory',
            that: equals('project_directory'),
          ),
        ),
      ).thenAnswer((invocation) async => process);

      testStepStates = [];
    });

    FluttiumDriver createDriver({
      DirectoryWatcher? directoryWatcher,
      FileWatcher? fileWatcher,
      List<String> dartDefines = const [],
      Map<String, ActionLocation> actions = const {},
    }) {
      final driver = FluttiumDriver(
        configuration: DriverConfiguration(
          deviceId: 'deviceId',
          dartDefines: dartDefines,
        ),
        actions: actions,
        projectDirectory: Directory('project_directory'),
        userFlowFile: File('flow.yaml'),
        logger: logger,
        processManager: processManager,
        generator: generatorBuilder,
        directoryWatcher: directoryWatcher != null
            ? (path, {Duration? pollingDelay}) => directoryWatcher
            : null,
        fileWatcher: fileWatcher != null
            ? (path, {Duration? pollingDelay}) => fileWatcher
            : null,
      );

      return driver..steps.listen((steps) => testStepStates = steps);
    }

    test('can run a flow test', () async {
      await IOOverrides.runZoned(
        () async {
          final driver = createDriver();
          final future = driver.run();

          // Wait for the process to start.
          await Future<void>.delayed(Duration.zero);

          // Generate driver
          verify(() => userFlowFile.readAsStringSync()).called(1);
          verify(
            () => generator.generate(
              any(),
              vars: any(named: 'vars', that: equals(vars)),
            ),
          ).called(1);

          // Rest of the run
          verify(
            () => logger.progress(any(that: equals('Starting up test driver'))),
          ).called(1);
          verify(
            () => processManager.start(
              any(
                that: equals(
                  [
                    'flutter',
                    'run',
                    'project_directory/.test_driver.dart',
                    '-d',
                    'deviceId'
                  ],
                ),
              ),
              runInShell: any(named: 'runInShell'),
              workingDirectory: any(
                named: 'workingDirectory',
                that: equals('project_directory'),
              ),
            ),
          ).called(1);
          verify(() => process.stdout).called(1);
          verify(() => process.stderr).called(1);
          verify(() => process.exitCode).called(1);

          // Trigger the attach
          stdoutController.add(utf8.encode('flutter: fake message'));
          await Future<void>.delayed(Duration.zero);
          verify(() => startingUpTestDriverProgress.complete()).called(1);

          // Trigger the first step
          stdoutController.add(utf8.encode('flutter: fluttium:start:null;'));
          await Future<void>.delayed(Duration.zero);
          expect(testStepStates.length, 1);
          expect(testStepStates[0], null);

          // Finish the first step
          stdoutController.add(utf8.encode('flutter: fluttium:done:null;'));
          await Future<void>.delayed(Duration.zero);
          expect(testStepStates.length, 1);
          expect(testStepStates[0], true);

          // Trigger the second step
          stdoutController.add(utf8.encode('flutter: fluttium:start:null;'));
          await Future<void>.delayed(Duration.zero);
          expect(testStepStates.length, 2);
          expect(testStepStates[0], true);
          expect(testStepStates[1], null);

          // Finish the second step and trigger the third step by splitting
          // them up
          stdoutController
            ..add(
              utf8.encode(
                'flutter: fluttium:done:null;flutter: fluttium:start:',
              ),
            )
            ..add(utf8.encode('null;'));
          await Future<void>.delayed(Duration.zero);
          expect(testStepStates.length, 3);
          expect(testStepStates[0], true);
          expect(testStepStates[1], true);
          expect(testStepStates[2], null);

          // Finish the third step and trigger the rest.
          stdoutController
            ..add(utf8.encode('flutter: fluttium:done:null;'))
            ..add(utf8.encode('flutter: fluttium:start:null;'))
            ..add(utf8.encode('flutter: fluttium:done:null;'))
            ..add(utf8.encode('flutter: fluttium:start:null;'))
            ..add(utf8.encode('flutter: fluttium:done:null;'));
          await Future<void>.delayed(Duration.zero);
          expect(testStepStates.length, 5);
          expect(testStepStates[0], true);
          expect(testStepStates[1], true);
          expect(testStepStates[2], true);
          expect(testStepStates[3], true);
          expect(testStepStates[4], true);

          await future;

          verifyNever(
            () => startingUpTestDriverProgress
                .fail('Failed to start test driver'),
          );
        },
        createFile: (path) {
          if (path == 'flow.yaml') {
            return userFlowFile;
          } else if (path == 'project_directory/.fluttium_test_launcher.dart') {
            return launcher;
          } else if (path == 'project_directory/pubspec.yaml') {
            return pubspec;
          }
          throw UnimplementedError(path);
        },
        createDirectory: (path) {
          if (path == '/temp/test') {
            return testRunnerDirectory;
          } else if (path == 'project_directory') {
            return projectDirectory;
          }
          throw UnimplementedError(path);
        },
      );
    });
  });
}
