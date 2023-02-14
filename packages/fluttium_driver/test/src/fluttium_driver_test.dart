// ignore_for_file: prefer_const_constructors

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:fluttium_driver/fluttium_driver.dart';
import 'package:fluttium_driver/src/bundles/bundles.dart';
import 'package:fluttium_interfaces/fluttium_interfaces.dart';
import 'package:fluttium_protocol/fluttium_protocol.dart';
import 'package:mason/mason.dart' hide GitPath;
import 'package:mocktail/mocktail.dart';
import 'package:process/process.dart';
import 'package:test/test.dart';
import 'package:watcher/watcher.dart';

class _FakeDirectoryGeneratorTarget extends Fake
    implements DirectoryGeneratorTarget {}

class _MockLogger extends Mock implements Logger {}

class _MockProgress extends Mock implements Progress {}

class _MockProcessManager extends Mock implements ProcessManager {}

class _MockProcess extends Mock implements Process {}

class _MockFile extends Mock implements File {}

class _MockDirectory extends Mock implements Directory {}

class _MockMasonGenerator extends Mock implements MasonGenerator {}

class _MockGeneratorHooks extends Mock implements GeneratorHooks {}

class _MockIOSink extends Mock implements IOSink {}

class _MockDirectoryWatcher extends Mock implements DirectoryWatcher {}

class _MockFileWatcher extends Mock implements FileWatcher {}

void main() {
  group('FluttiumDriver', () {
    late Logger logger;
    late Progress settingUpTestRunner;
    late Progress settingUpLauncher;
    late Progress launchingTestRunner;

    late GeneratorBuilder generatorBuilder;
    late MasonGenerator testRunnerGenerator;
    late GeneratorHooks testRunnerGeneratorHooks;
    late MasonGenerator launcherGenerator;
    late GeneratorHooks launcherGeneratorHooks;

    late Directory tempDirectory;
    late Directory testRunnerDirectory;
    late File userFlowFile;
    late Directory projectDirectory;
    late File launcherFile;
    late File pubspecFile;

    late ProcessManager processManager;
    late Process process;
    late IOSink processSink;
    late StreamController<List<int>> stdoutController;
    late StreamController<List<int>> stderrController;
    late Completer<int> processExitCode;

    late List<StepState> testStepStates;

    setUpAll(() {
      registerFallbackValue(_FakeDirectoryGeneratorTarget());
    });

    setUp(() {
      // Setting up logger
      logger = _MockLogger();
      settingUpTestRunner = _MockProgress();
      when(
        () => logger.progress(any(that: equals('Setting up the test runner'))),
      ).thenReturn(settingUpTestRunner);
      settingUpLauncher = _MockProgress();
      when(
        () => logger.progress(any(that: equals('Setting up the launcher'))),
      ).thenReturn(settingUpLauncher);
      launchingTestRunner = _MockProgress();
      when(
        () => logger.progress(any(that: equals('Launching the test runner'))),
      ).thenReturn(launchingTestRunner);

      // Setting up mason
      testRunnerGenerator = _MockMasonGenerator();
      when(
        () => testRunnerGenerator.generate(
          any(),
          vars: any(named: 'vars'),
          logger: any(named: 'logger'),
          fileConflictResolution: any(named: 'fileConflictResolution'),
        ),
      ).thenAnswer((_) async => []);

      testRunnerGeneratorHooks = _MockGeneratorHooks();
      when(
        () => testRunnerGeneratorHooks.postGen(
          workingDirectory: any(named: 'workingDirectory'),
        ),
      ).thenAnswer((_) async {});
      when(() => testRunnerGenerator.hooks)
          .thenReturn(testRunnerGeneratorHooks);

      launcherGenerator = _MockMasonGenerator();
      when(
        () => launcherGenerator.generate(
          any(),
          vars: any(named: 'vars'),
          logger: any(named: 'logger'),
          fileConflictResolution: any(named: 'fileConflictResolution'),
        ),
      ).thenAnswer(
        (_) async => [
          GeneratedFile.created(
            path: 'project_directory/.fluttium_test_launcher.dart',
          )
        ],
      );
      launcherGeneratorHooks = _MockGeneratorHooks();
      when(
        () => launcherGeneratorHooks.preGen(
          workingDirectory: any(named: 'workingDirectory'),
          vars: any(named: 'vars'),
        ),
      ).thenAnswer((_) async {});
      when(
        () => launcherGeneratorHooks.postGen(
          workingDirectory: any(named: 'workingDirectory'),
        ),
      ).thenAnswer((_) async {});
      when(() => launcherGenerator.hooks).thenReturn(launcherGeneratorHooks);

      generatorBuilder = (MasonBundle bundle) {
        if (bundle == fluttiumLauncherBundle) return launcherGenerator;
        return testRunnerGenerator;
      };

      // Setting up directories
      testRunnerDirectory = _MockDirectory();
      when(() => testRunnerDirectory.path).thenReturn('/tmp/fluttium_xxxxxxx');
      tempDirectory = _MockDirectory();
      when(
        () => tempDirectory.createTempSync(any(that: equals('fluttium_'))),
      ).thenReturn(testRunnerDirectory);
      when(() => testRunnerDirectory.existsSync()).thenReturn(true);
      when(
        () => testRunnerDirectory.deleteSync(
          recursive: any(named: 'recursive'),
        ),
      ).thenAnswer((_) {});

      userFlowFile = _MockFile();
      when(() => userFlowFile.existsSync()).thenReturn(true);
      when(() => userFlowFile.readAsStringSync()).thenReturn('''
description: test
---
- tapOn: Text
- expectVisible: Text
''');
      when(() => userFlowFile.path).thenReturn('flow.yaml');

      projectDirectory = _MockDirectory();
      when(() => projectDirectory.path).thenReturn('project_directory');
      when(() => projectDirectory.uri)
          .thenReturn(Uri.parse('project_directory/'));
      when(() => projectDirectory.absolute).thenReturn(projectDirectory);
      launcherFile = _MockFile();
      when(() => launcherFile.absolute).thenReturn(launcherFile);
      when(() => launcherFile.path)
          .thenReturn('project_directory/.fluttium_test_launcher.dart');
      when(() => launcherFile.existsSync()).thenReturn(true);
      when(() => launcherFile.deleteSync()).thenAnswer((_) {});

      pubspecFile = _MockFile();
      when(() => pubspecFile.path).thenReturn('project_directory/pubspec.yaml');
      when(() => pubspecFile.readAsStringSync()).thenReturn('''
name: project_name
''');

      processManager = _MockProcessManager();

      process = _MockProcess();
      processExitCode = Completer<int>();
      when(() => process.exitCode).thenAnswer((_) => processExitCode.future);

      processSink = _MockIOSink();
      when(() => processSink.write(any(that: equals('q')))).thenAnswer((_) {
        processExitCode.complete(ExitCode.success.code);
      });
      when(() => process.stdin).thenReturn(processSink);

      stdoutController = StreamController<List<int>>();
      when(() => process.stdout).thenAnswer((_) => stdoutController.stream);
      stderrController = StreamController<List<int>>();
      when(() => process.stderr).thenAnswer((_) => stderrController.stream);
      when(() => process.kill()).thenReturn(true);

      when(
        () => processManager.start(
          any(
            that: containsAllInOrder([
              'flutter',
              'run',
              'project_directory/.fluttium_test_launcher.dart',
              '-d',
              'deviceId'
            ]),
          ),
          runInShell: any(named: 'runInShell'),
          workingDirectory: any(named: 'workingDirectory'),
        ),
      ).thenAnswer((_) async => process);

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

    test('can be instantiated', () {
      IOOverrides.runZoned(
        () {
          expect(
            FluttiumDriver(
              configuration: DriverConfiguration(),
              actions: {},
              projectDirectory: projectDirectory,
              userFlowFile: userFlowFile,
            ),
            isNotNull,
          );
        },
        createFile: (path) {
          if (path == 'flow.yaml') return userFlowFile;
          throw UnimplementedError(path);
        },
      );
    });

    Future<void> runWithMocks(Future<void> Function() callback) async {
      await IOOverrides.runZoned(
        callback,
        createFile: (path) {
          if (path == 'flow.yaml') {
            return userFlowFile;
          } else if (path == 'project_directory/.fluttium_test_launcher.dart') {
            return launcherFile;
          } else if (path == 'project_directory/pubspec.yaml') {
            return pubspecFile;
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
        getSystemTempDirectory: () => tempDirectory,
      );
    }

    test('can run a flow test', () async {
      await runWithMocks(() async {
        final driver = createDriver(
          actions: {
            'hosted_action': ActionLocation(
              hosted: HostedPath(
                url: 'https://pub.dev/packages/hosted_action',
                version: VersionConstraint.parse('^1.2.3'),
              ),
            ),
            'git_action_simple': ActionLocation(
              git: GitPath(
                url: 'git@github.com/wolfenrain/git_action_simple',
              ),
            ),
            'git_action_advanced': ActionLocation(
              git: GitPath(
                url: 'git@github.com/wolfenrain/git_action_advanced',
                ref: 'dev',
                path: 'packages/advanced',
              ),
            ),
            'path_action': ActionLocation(path: './path_action'),
          },
        );
        verify(() => userFlowFile.readAsStringSync()).called(equals(1));

        final future = driver.run();

        // Wait for the process to start.
        await Future<void>.delayed(Duration.zero);

        // Check if the start of the generated code is working correctly.
        verify(
          () =>
              logger.progress(any(that: equals('Setting up the test runner'))),
        ).called(equals(1));
        verify(
          () => tempDirectory.createTempSync(any(that: equals('fluttium_'))),
        ).called(equals(1));
        verify(() => settingUpTestRunner.complete()).called(equals(1));
        verify(
          () => logger.progress(any(that: equals('Setting up the launcher'))),
        ).called(equals(1));
        verify(() => pubspecFile.readAsStringSync()).called(equals(1));
        verify(() => settingUpLauncher.complete()).called(equals(1));

        // Check if the test runner generation is working correctly
        verify(() => userFlowFile.readAsStringSync()).called(equals(1));
        verify(
          () => testRunnerGenerator.generate(
            any(),
            vars: any(
              named: 'vars',
              that: equals({
                'actions': [
                  {
                    'name': 'hosted_action',
                    'source': '''

    hosted: https://pub.dev/packages/hosted_action
    version: ^1.2.3'''
                  },
                  {
                    'name': 'git_action_simple',
                    'source': 'git@github.com/wolfenrain/git_action_simple'
                  },
                  {
                    'name': 'git_action_advanced',
                    'source': '''

    git:
      url: git@github.com/wolfenrain/git_action_advanced
      ref: dev
      path: packages/advanced'''
                  },
                  {
                    'name': 'path_action',
                    'source': '''

    path: project_directory/path_action'''
                  }
                ],
                'steps': [
                  {
                    'step': json.encode({'tapOn': 'Text'})
                  },
                  {
                    'step': json.encode({'expectVisible': 'Text'})
                  }
                ],
              }),
            ),
            logger: any(named: 'logger'),
            fileConflictResolution: any(
              named: 'fileConflictResolution',
              that: equals(FileConflictResolution.overwrite),
            ),
          ),
        ).called(equals(1));
        verify(
          () => testRunnerGeneratorHooks.postGen(
            workingDirectory: any(
              named: 'workingDirectory',
              that: equals('/tmp/fluttium_xxxxxxx'),
            ),
          ),
        ).called(equals(1));

        // Verify that the rest of the test runner generation is working.
        verify(
          () => launcherGeneratorHooks.preGen(
            workingDirectory: any(
              named: 'workingDirectory',
              that: equals('project_directory'),
            ),
            vars: any(
              named: 'vars',
              that: equals({
                'runner_id': 'fluttium_xxxxxxx',
                'project_name': 'project_name',
                'main_entry': 'main.dart',
                'runner_path': '/tmp/fluttium_xxxxxxx',
              }),
            ),
          ),
        ).called(equals(1));
        verify(
          () => launcherGenerator.generate(
            any(),
            vars: any(
              named: 'vars',
              that: equals({
                'runner_id': 'fluttium_xxxxxxx',
                'project_name': 'project_name',
                'main_entry': 'main.dart',
                'runner_path': '/tmp/fluttium_xxxxxxx',
              }),
            ),
            logger: any(named: 'logger'),
            fileConflictResolution: any(named: 'fileConflictResolution'),
          ),
        ).called(equals(1));

        // Verifying that the launching works correctly.
        verify(
          () => logger.detail(
            any(
              that: equals(
                'Running command: flutter run project_directory/.fluttium_test_launcher.dart -d deviceId',
              ),
            ),
          ),
        ).called(equals(1));
        verify(
          () => logger.progress(any(that: equals('Launching the test runner'))),
        ).called(equals(1));
        verify(
          () => processManager.start(
            any(
              that: equals([
                'flutter',
                'run',
                'project_directory/.fluttium_test_launcher.dart',
                '-d',
                'deviceId'
              ]),
            ),
            runInShell: any(named: 'runInShell', that: isTrue),
            workingDirectory: any(
              named: 'workingDirectory',
              that: equals('project_directory'),
            ),
          ),
        ).called(equals(1));

        // Trigger the attach by sending the first announce.
        stdoutController
          ..addAll(MessageType.announce.toData('stepName1'))
          ..addAll(MessageType.announce.toData('stepName2'));
        await Future<void>.delayed(Duration.zero);
        verify(() => launchingTestRunner.complete()).called(equals(1));

        // Finish the process by starting and finishing a step.
        stdoutController
          ..addAll(MessageType.start.toData('stepName1'))
          ..addAll(MessageType.store.toData('stepName1'))
          ..addAll(MessageType.done.toData('stepName1'))
          ..addAll(MessageType.start.toData('stepName2'))
          ..addAll(MessageType.fail.toData('stepName2'));

        // Wait for the messages to be consumed.
        await Future<void>.delayed(Duration.zero);

        // Verify that the code clean is working correctly.
        verify(
          () => launcherGeneratorHooks.postGen(
            workingDirectory: any(
              named: 'workingDirectory',
              that: equals('project_directory'),
            ),
          ),
        ).called(equals(1));
        verify(() => launcherFile.existsSync()).called(1);
        verify(() => launcherFile.deleteSync()).called(1);
        verify(() => testRunnerDirectory.existsSync()).called(1);
        verify(
          () => testRunnerDirectory.deleteSync(
            recursive: any(named: 'recursive', that: isTrue),
          ),
        ).called(1);

        await future;

        expect(
          testStepStates,
          equals([
            StepState(
              'stepName1',
              status: StepStatus.done,
              files: const {
                'fileName': [1, 2, 3]
              },
            ),
            StepState(
              'stepName2',
              status: StepStatus.failed,
              failReason: 'reason',
            ),
          ]),
        );
      });
    });

    test('can run a flow test', () async {
      await runWithMocks(() async {
        final driver = createDriver();
        verify(() => userFlowFile.readAsStringSync()).called(equals(1));

        final future = driver.run();

        // Wait for the process to start.
        await Future<void>.delayed(Duration.zero);

        // Write an error to stderr
        stderrController.add(utf8.encode('fake failure'));
        await Future<void>.delayed(Duration.zero);

        // Close process and stderr controller.
        await stderrController.close();
        processExitCode.complete(ExitCode.unavailable.code);

        await Future<void>.delayed(Duration.zero);
        verifyNever(() => launchingTestRunner.complete());
        verify(
          () => launchingTestRunner
              .fail(any(that: equals('Failed to start test driver'))),
        ).called(equals(1));
        verify(() => logger.err(any(that: equals('fake failure'))))
            .called(equals(1));

        await future;

        expect(testStepStates, equals([]));
      });
    });

    group('watch mode', () {
      late DirectoryWatcher directoryWatcher;
      late StreamController<WatchEvent> watchEventController;
      late FileWatcher fileWatcher;
      late StreamController<WatchEvent> fileWatchEventController;

      setUp(() {
        directoryWatcher = _MockDirectoryWatcher();
        watchEventController = StreamController<WatchEvent>();
        when(() => directoryWatcher.events)
            .thenAnswer((_) => watchEventController.stream);

        fileWatcher = _MockFileWatcher();
        fileWatchEventController = StreamController<WatchEvent>();
        when(() => fileWatcher.events)
            .thenAnswer((_) => fileWatchEventController.stream);
      });

      test('restart if a project file changes', () async {
        await runWithMocks(() async {
          final driver = createDriver(
            directoryWatcher: directoryWatcher,
            fileWatcher: fileWatcher,
          );

          final future = driver.run(watch: true);
          // Wait for the process to start.
          await Future<void>.delayed(Duration.zero);

          // Trigger the attach by sending the first announce.
          stdoutController.addAll(MessageType.announce.toData('stepName'));
          await Future<void>.delayed(Duration.zero);

          // Trigger a file change
          watchEventController.add(
            WatchEvent(ChangeType.MODIFY, 'project_directory/lib/main.dart'),
          );
          await Future<void>.delayed(Duration.zero);

          verify(() => process.stdin.write(any(that: equals('R')))).called(1);

          processExitCode.complete(ExitCode.success.code);
          await future;

          expect(testStepStates, equals([StepState('stepName')]));
        });
      });

      test('logs an error if it temporary cant watch a file', () async {
        await runWithMocks(() async {
          final driver = createDriver(
            directoryWatcher: directoryWatcher,
            fileWatcher: fileWatcher,
          );

          final future = driver.run(watch: true);
          // Wait for the process to start.
          await Future<void>.delayed(Duration.zero);

          // Trigger the attach by sending the first announce.
          stdoutController.addAll(MessageType.announce.toData('stepName'));
          await Future<void>.delayed(Duration.zero);

          // Trigger a file system exception.
          watchEventController.addError(FileSystemException('Failed to watch'));
          await Future<void>.delayed(Duration.zero);

          verify(
            () => logger.detail(
              any(
                that: equals(
                  "FileSystemException: Failed to watch, path = ''",
                ),
              ),
            ),
          ).called(1);
          verifyNever(() => process.stdin.write(any(that: equals('R'))));

          processExitCode.complete(ExitCode.success.code);
          await future;

          expect(testStepStates, equals([]));
        });
      });

      test('regenerate test runner if the flow file change', () async {
        await runWithMocks(() async {
          final driver = createDriver(
            directoryWatcher: directoryWatcher,
            fileWatcher: fileWatcher,
          );

          final future = driver.run(watch: true);
          // Wait for the process to start.
          await Future<void>.delayed(Duration.zero);

          verify(() => userFlowFile.readAsStringSync()).called(2);

          // Trigger the attach by sending the first announce.
          stdoutController.addAll(MessageType.announce.toData('stepName'));
          await Future<void>.delayed(Duration.zero);

          verifyNever(() => userFlowFile.readAsStringSync());
          fileWatchEventController.add(
            WatchEvent(ChangeType.MODIFY, 'flow.yaml'),
          );
          await Future<void>.delayed(Duration.zero);
          verify(() => userFlowFile.readAsStringSync()).called(1);
          verify(() => process.stdin.write(any(that: equals('R')))).called(1);

          processExitCode.complete(ExitCode.success.code);
          await future;

          expect(testStepStates, equals([StepState('stepName')]));
        });
      });
    });
  });
}

extension on MessageType {
  Iterable<List<int>> toData(String stepName) {
    switch (this) {
      case MessageType.announce:
        return [
          {'type': 'start'},
          {
            'type': 'data',
            'data':
                '"{\\"type\\":\\"announce\\",\\"data\\":\\"\\\\\\"$stepName\\\\\\"\\"}"'
          },
          {'type': 'done'}
        ].map((data) => utf8.encode('${json.encode(data)}\n'));
      case MessageType.start:
        return [
          {'type': 'start'},
          {
            'type': 'data',
            'data':
                '"{\\"type\\":\\"start\\",\\"data\\":\\"\\\\\\"$stepName\\\\\\"\\"}"'
          },
          {'type': 'done'},
        ].map((data) => utf8.encode('${json.encode(data)}\n'));
      case MessageType.done:
        return [
          {'type': 'start'},
          {
            'type': 'data',
            'data':
                '"{\\"type\\":\\"done\\",\\"data\\":\\"\\\\\\"$stepName\\\\\\"\\"}"'
          },
          {'type': 'done'},
        ].map((data) => utf8.encode('${json.encode(data)}\n'));
      case MessageType.fail:
        return [
          {'type': 'start'},
          {
            'type': 'data',
            'data':
                '"{\\"type\\":\\"fail\\",\\"data\\":\\"[\\\\\\"$stepName\\\\\\",\\\\\\"reason\\\\\\"]\\"}"'
          },
          {'type': 'done'},
        ].map((data) => utf8.encode('${json.encode(data)}\n'));
      case MessageType.store:
        return [
          {'type': 'start'},
          {
            'type': 'data',
            'data':
                r'"{\"type\":\"store\",\"data\":\"[\\\"fileName\\\",[1,2,3]]\"}"'
          },
          {'type': 'done'},
        ].map((data) => utf8.encode('${json.encode(data)}\n'));
    }
  }
}

extension on StreamController<List<int>> {
  void addAll(Iterable<List<int>> data) => data.forEach(add);
}
