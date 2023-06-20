// ignore_for_file: prefer_const_constructors

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:fake_async/fake_async.dart';
import 'package:fluttium_driver/fluttium_driver.dart';
import 'package:fluttium_driver/src/bundles/bundles.dart';
import 'package:fluttium_interfaces/fluttium_interfaces.dart';
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
  group('$FluttiumDriver', () {
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
    late Process daemonProcess;
    late IOSink daemonSink;
    late StreamController<List<int>> daemonController;
    late StreamController<List<int>> stderrController;
    late Completer<int> daemonExitCode;

    late Map<String, String> files;
    late bool fluttiumReady;
    late bool failStep;

    setUpAll(() {
      registerFallbackValue(_FakeDirectoryGeneratorTarget());
    });

    setUp(() {
      files = {};
      fluttiumReady = true;
      failStep = false;

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
            path: '/project_directory/.fluttium_test_launcher.dart',
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
- pressOn: Text
- expectVisible: Text
''');
      when(() => userFlowFile.path).thenReturn('flow.yaml');

      projectDirectory = _MockDirectory();
      when(() => projectDirectory.path).thenReturn('/project_directory');
      when(() => projectDirectory.uri)
          .thenReturn(Uri.parse('/project_directory/'));
      when(() => projectDirectory.absolute).thenReturn(projectDirectory);
      launcherFile = _MockFile();
      when(() => launcherFile.absolute).thenReturn(launcherFile);
      when(() => launcherFile.path)
          .thenReturn('/project_directory/.fluttium_test_launcher.dart');
      when(() => launcherFile.existsSync()).thenReturn(true);
      when(() => launcherFile.deleteSync()).thenAnswer((_) {});

      pubspecFile = _MockFile();
      when(() => pubspecFile.path)
          .thenReturn('/project_directory/pubspec.yaml');
      when(() => pubspecFile.readAsStringSync()).thenReturn('''
name: project_name
''');

      processManager = _MockProcessManager();

      daemonProcess = _MockProcess();
      daemonExitCode = Completer<int>();
      when(() => daemonProcess.exitCode)
          .thenAnswer((_) => daemonExitCode.future);

      daemonSink = _MockIOSink();
      when(() => daemonSink.writeln(any())).thenAnswer((_) {
        final requests = json.decode(_.positionalArguments.first as String);
        final request = (requests as List).first as Map<String, dynamic>;
        final params = request['params'] as Map<String, dynamic>?;

        final result = switch (request['method']) {
          'app.restart' => {'code': 0, 'message': ''},
          'app.stop' => true,
          'app.callServiceExtension' => <String, dynamic>{
              ...switch (params!['methodName']) {
                'ext.fluttium.ready' => <String, dynamic>{
                    'ready': fluttiumReady,
                    if (!fluttiumReady) 'reason': 'failedReason',
                  },
                'ext.fluttium.getActionDescription' => {
                    'description': 'Description'
                  },
                'ext.fluttium.executeAction' => {
                    'success': !failStep,
                    'files': files,
                  },
                _ => throw UnimplementedError(params['methodName'] as String)
              },
            },
          _ => throw UnimplementedError(request['method'] as String),
        };

        daemonController.write(
          json.encode([
            {'id': request['id'], 'result': result}
          ]),
        );
      });
      when(() => daemonProcess.stdin).thenReturn(daemonSink);

      daemonController = StreamController<List<int>>();
      when(() => daemonProcess.stdout)
          .thenAnswer((_) => daemonController.stream);
      stderrController = StreamController<List<int>>();
      when(() => daemonProcess.stderr)
          .thenAnswer((_) => stderrController.stream);
      when(() => daemonProcess.kill()).thenReturn(true);

      when(
        () => processManager.start(
          any(
            that: containsAllInOrder([
              'flutter',
              'run',
              '--machine',
              '/project_directory/.fluttium_test_launcher.dart',
              '-d',
              'deviceId',
              '--flavor',
              'development',
            ]),
          ),
          runInShell: any(named: 'runInShell'),
          workingDirectory: any(named: 'workingDirectory'),
        ),
      ).thenAnswer((_) async => daemonProcess);
    });

    FluttiumDriver createDriver({
      DirectoryWatcher? directoryWatcher,
      FileWatcher? fileWatcher,
      List<String> dartDefines = const [],
      Map<String, ActionLocation> actions = const {},
    }) {
      return FluttiumDriver(
        configuration: DriverConfiguration(
          deviceId: 'deviceId',
          dartDefines: dartDefines,
          flavor: 'development',
        ),
        actions: actions,
        projectDirectory: Directory('/project_directory'),
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
          } else if (path ==
              '/project_directory/.fluttium_test_launcher.dart') {
            return launcherFile;
          } else if (path == '/project_directory/pubspec.yaml') {
            return pubspecFile;
          }
          throw UnimplementedError(path);
        },
        createDirectory: (path) {
          if (path == '/temp/test') {
            return testRunnerDirectory;
          } else if (path == '/project_directory') {
            return projectDirectory;
          }
          throw UnimplementedError(path);
        },
        getSystemTempDirectory: () => tempDirectory,
      );
    }

    test('can run a flow test', () async {
      files = {
        'fileName': base64.encode([1, 2, 3]),
      };

      await runWithMocks(() async {
        var testStepStates = <UserFlowStepState>[];
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
        )
          ..steps.listen((steps) => testStepStates = steps)
          ..files.listen((file) {
            expect(file.path, equals('fileName'));
            expect(file.data, equals([1, 2, 3]));
          });

        verify(() => userFlowFile.readAsStringSync()).called(1);

        final future = driver.run();

        // Wait for the process to start.
        await Future<void>.delayed(Duration.zero);

        // Check if the start of the generated code is working correctly.
        verify(
          () =>
              logger.progress(any(that: equals('Setting up the test runner'))),
        ).called(1);
        verify(
          () => tempDirectory.createTempSync(any(that: equals('fluttium_'))),
        ).called(1);
        verify(() => settingUpTestRunner.complete()).called(1);
        verify(
          () => logger.progress(any(that: equals('Setting up the launcher'))),
        ).called(1);
        verify(() => pubspecFile.readAsStringSync()).called(1);
        verify(() => settingUpLauncher.complete()).called(1);

        // Check if the test runner generation is working correctly
        verify(() => userFlowFile.readAsStringSync()).called(1);
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

    path: /project_directory/path_action'''
                  }
                ],
                'steps': [
                  {
                    'step': json.encode({'pressOn': 'Text'})
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
        ).called(1);
        verify(
          () => testRunnerGeneratorHooks.postGen(
            workingDirectory: any(
              named: 'workingDirectory',
              that: equals('/tmp/fluttium_xxxxxxx'),
            ),
          ),
        ).called(1);

        // Verify that the rest of the test runner generation is working.
        verify(
          () => launcherGeneratorHooks.preGen(
            workingDirectory: any(
              named: 'workingDirectory',
              that: equals('/project_directory'),
            ),
            vars: any(
              named: 'vars',
              that: equals({
                'runner_id': 'fluttium_xxxxxxx',
                'project_name': 'project_name',
                'target': 'main.dart',
                'runner_path': '/tmp/fluttium_xxxxxxx',
              }),
            ),
          ),
        ).called(1);
        verify(
          () => launcherGenerator.generate(
            any(),
            vars: any(
              named: 'vars',
              that: equals({
                'runner_id': 'fluttium_xxxxxxx',
                'project_name': 'project_name',
                'target': 'main.dart',
                'runner_path': '/tmp/fluttium_xxxxxxx',
              }),
            ),
            logger: any(named: 'logger'),
            fileConflictResolution: any(named: 'fileConflictResolution'),
          ),
        ).called(1);

        // Verifying that the launching works correctly.
        verify(
          () => logger.progress(any(that: equals('Launching the test runner'))),
        ).called(1);
        verify(
          () => processManager.start(
            any(
              that: equals([
                'flutter',
                'run',
                '--machine',
                '/project_directory/.fluttium_test_launcher.dart',
                '-d',
                'deviceId',
                '--flavor',
                'development',
              ]),
            ),
            runInShell: any(named: 'runInShell', that: isTrue),
            workingDirectory: any(
              named: 'workingDirectory',
              that: equals('/project_directory'),
            ),
          ),
        ).called(1);

        // Ensure app start event is emitted.
        daemonController.appStart();
        await Future<void>.delayed(Duration.zero);
        verify(() => launchingTestRunner.complete()).called(1);

        // Allow the daemon to consume all the driver calls.
        await Future<void>.delayed(Duration.zero);
        daemonExitCode.complete(ExitCode.success.code);

        // Verify that the code clean is working correctly.
        verify(
          () => launcherGeneratorHooks.postGen(
            workingDirectory: any(
              named: 'workingDirectory',
              that: equals('/project_directory'),
            ),
          ),
        ).called(1);
        verify(() => launcherFile.existsSync()).called(1);
        verify(() => launcherFile.deleteSync()).called(1);
        verify(() => testRunnerDirectory.existsSync()).called(1);
        verify(
          () => testRunnerDirectory.deleteSync(
            recursive: any(named: 'recursive', that: isTrue),
          ),
        ).called(1);

        await future;

        // Verify all RCP calls were done correctly
        verifyInOrder([
          () => daemonSink.writeln(
                any(that: isRcpCall('ext.fluttium.ready', {})),
              ),
          () => daemonSink.writeln(
                any(
                  that: isRcpCall(
                    'ext.fluttium.getActionDescription',
                    {'name': 'pressOn', 'arguments': '"Text"'},
                  ),
                ),
              ),
          () => daemonSink.writeln(
                any(
                  that: isRcpCall(
                    'ext.fluttium.getActionDescription',
                    {'name': 'expectVisible', 'arguments': '"Text"'},
                  ),
                ),
              ),
          () => daemonSink.writeln(
                any(
                  that: isRcpCall(
                    'ext.fluttium.executeAction',
                    {'name': 'pressOn', 'arguments': '"Text"'},
                  ),
                ),
              ),
          () => daemonSink.writeln(
                any(
                  that: isRcpCall(
                    'ext.fluttium.executeAction',
                    {'name': 'expectVisible', 'arguments': '"Text"'},
                  ),
                ),
              ),
          () => daemonSink.writeln(any(that: isMethodCall('app.stop'))),
        ]);

        expect(
          testStepStates,
          equals([
            UserFlowStepState(
              UserFlowStep('pressOn', arguments: 'Text'),
              description: 'Description',
              status: StepStatus.done,
            ),
            UserFlowStepState(
              UserFlowStep('expectVisible', arguments: 'Text'),
              description: 'Description',
              status: StepStatus.done,
            ),
          ]),
        );
      });
    });

    test('fails to start driver if error occurred in building', () async {
      await runWithMocks(() async {
        var testStepStates = <UserFlowStepState>[];
        final driver = createDriver()
          ..steps.listen((steps) => testStepStates = steps);
        verify(userFlowFile.readAsStringSync).called(1);

        final future = driver.run();

        // Wait for the process to start.
        await Future<void>.delayed(Duration.zero);

        // Write an error to stderr
        stderrController.add(utf8.encode('fake failure'));
        await Future<void>.delayed(Duration.zero);

        // Close process and stderr controller.
        await stderrController.close();
        daemonExitCode.complete(ExitCode.unavailable.code);

        await Future<void>.delayed(Duration.zero);
        verifyNever(launchingTestRunner.complete);
        verify(
          () => launchingTestRunner
              .fail(any(that: equals('Failed to start test driver'))),
        ).called(1);
        verify(() => logger.err(any(that: equals('fake failure')))).called(1);

        await future;

        expect(testStepStates, equals([]));
      });
    });

    test('stops early if a step failed', () async {
      failStep = true;

      await runWithMocks(() async {
        var testStepStates = <UserFlowStepState>[];
        final driver = createDriver()
          ..steps.listen((steps) => testStepStates = steps);
        verify(userFlowFile.readAsStringSync).called(1);

        final future = driver.run();

        // Wait for the process to start.
        await Future<void>.delayed(Duration.zero);

        // Ensure app start event is emitted.
        daemonController.appStart();
        await Future<void>.delayed(Duration.zero);
        verify(() => launchingTestRunner.complete()).called(1);

        // Allow the daemon to consume all the driver calls.
        await Future<void>.delayed(Duration.zero);

        // Close process.
        daemonExitCode.complete(ExitCode.unavailable.code);

        await future;

        expect(
          testStepStates,
          equals([
            UserFlowStepState(
              UserFlowStep('pressOn', arguments: 'Text'),
              description: 'Description',
              status: StepStatus.failed,
            ),
            UserFlowStepState(
              UserFlowStep('expectVisible', arguments: 'Text'),
              description: 'Description',
            )
          ]),
        );
      });
    });

    test('fails early if driver does not get ready', () async {
      await fakeAsync((async) async {
        fluttiumReady = false;

        await runWithMocks(() async {
          var testStepStates = <UserFlowStepState>[];
          final driver = createDriver()
            ..steps.listen((steps) => testStepStates = steps);
          verify(userFlowFile.readAsStringSync).called(1);

          final future = driver.run();

          // Wait for the process to start.
          await Future<void>.delayed(Duration.zero);

          // Ensure app start event is emitted.
          daemonController.appStart();
          await Future<void>.delayed(Duration.zero);
          verify(() => launchingTestRunner.complete()).called(1);

          // Allow the daemon to consume all the driver calls.
          await Future<void>.delayed(Duration.zero);

          async.elapse(Duration(seconds: 31));

          // Close process.
          daemonExitCode.complete(ExitCode.unavailable.code);

          verify(
            () => logger.err(
              any(that: equals('Failed to get ready: failedReason')),
            ),
          ).called(1);

          await future;

          expect(testStepStates, equals([]));
        });
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
          var testStepStates = <UserFlowStepState>[];
          final driver = createDriver(
            directoryWatcher: directoryWatcher,
            fileWatcher: fileWatcher,
          )..steps.listen((steps) => testStepStates = steps);

          final future = driver.run(watch: true);
          // Wait for the process to start.
          await Future<void>.delayed(Duration.zero);

          // Ensure app start event is emitted.
          daemonController.appStart();
          await Future<void>.delayed(Duration.zero);
          verify(launchingTestRunner.complete).called(1);

          // Allow the daemon to consume all the driver calls.
          await Future<void>.delayed(Duration.zero);

          // Trigger a file change
          watchEventController.add(
            WatchEvent(ChangeType.MODIFY, 'project_directory/lib/main.dart'),
          );
          await Future<void>.delayed(Duration.zero);

          verify(
            () => daemonSink.writeln(
              any(
                that: isMethodCall('app.restart', {
                  'fullRestart': null,
                  'reason': null,
                  'pause': null,
                  'debounce': null,
                }),
              ),
            ),
          ).called(1);
          await Future<void>.delayed(Duration.zero);

          daemonExitCode.complete(ExitCode.success.code);
          await future;

          expect(
            testStepStates,
            equals([
              UserFlowStepState(
                UserFlowStep('pressOn', arguments: 'Text'),
                description: 'Description',
                status: StepStatus.done,
              ),
              UserFlowStepState(
                UserFlowStep('expectVisible', arguments: 'Text'),
                description: 'Description',
                status: StepStatus.done,
              )
            ]),
          );
        });
      });

      test('logs an error if it temporary cant watch a file', () async {
        await runWithMocks(() async {
          var testStepStates = <UserFlowStepState>[];
          final driver = createDriver(
            directoryWatcher: directoryWatcher,
            fileWatcher: fileWatcher,
          )..steps.listen((steps) => testStepStates = steps);

          final future = driver.run(watch: true);
          // Wait for the process to start.
          await Future<void>.delayed(Duration.zero);

          // Ensure app start event is emitted.
          daemonController.appStart();
          await Future<void>.delayed(Duration.zero);
          verify(launchingTestRunner.complete).called(1);

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
          verifyNever(
            () => daemonSink.writeln(
              any(
                that: isMethodCall('app.restart', {
                  'fullRestart': null,
                  'reason': null,
                  'pause': null,
                  'debounce': null,
                }),
              ),
            ),
          );

          daemonExitCode.complete(ExitCode.success.code);
          await future;

          expect(
            testStepStates,
            equals([
              UserFlowStepState(
                UserFlowStep('pressOn', arguments: 'Text'),
                description: 'Description',
                status: StepStatus.done,
              ),
              UserFlowStepState(
                UserFlowStep('expectVisible', arguments: 'Text'),
                description: 'Description',
                status: StepStatus.done,
              )
            ]),
          );
        });
      });

      test('regenerate test runner if the flow file change', () async {
        await runWithMocks(() async {
          var testStepStates = <UserFlowStepState>[];
          final driver = createDriver(
            directoryWatcher: directoryWatcher,
            fileWatcher: fileWatcher,
          )..steps.listen((steps) => testStepStates = steps);

          final future = driver.run(watch: true);
          // Wait for the process to start.
          await Future<void>.delayed(Duration.zero);

          verify(userFlowFile.readAsStringSync).called(2);

          // Ensure app start event is emitted.
          daemonController.appStart();
          await Future<void>.delayed(Duration.zero);
          verify(launchingTestRunner.complete).called(1);

          verifyNever(userFlowFile.readAsStringSync);
          fileWatchEventController.add(
            WatchEvent(ChangeType.MODIFY, 'flow.yaml'),
          );
          await Future<void>.delayed(Duration.zero);

          verify(userFlowFile.readAsStringSync).called(1);
          verify(
            () => daemonSink.writeln(
              any(
                that: isMethodCall('app.restart', {
                  'fullRestart': null,
                  'reason': null,
                  'pause': null,
                  'debounce': null,
                }),
              ),
            ),
          ).called(1);

          daemonExitCode.complete(ExitCode.success.code);
          await future;

          expect(
            testStepStates,
            equals([
              UserFlowStepState(
                UserFlowStep('pressOn', arguments: 'Text'),
                description: 'Description',
                status: StepStatus.done,
              ),
              UserFlowStepState(
                UserFlowStep('expectVisible', arguments: 'Text'),
                description: 'Description',
                status: StepStatus.done,
              )
            ]),
          );
        });
      });
    });

    test('creates a Fluttium version constraints correctly', () {
      expect(
        FluttiumDriver.fluttiumVersionConstraint,
        isA<VersionConstraint>(),
      );
    });

    test('creates a Flutter version constraints correctly', () {
      expect(
        FluttiumDriver.flutterVersionConstraint,
        isA<VersionConstraint>(),
      );
    });
  });
}

extension on StreamController<List<int>> {
  void write(String data) => add(utf8.encode('$data\n'));

  void appStart() {
    write(
      json.encode([
        {
          'event': 'app.started',
          'params': {'appId': '0000'}
        }
      ]),
    );
  }
}

Matcher isRcpCall(
  String methodName, [
  Map<String, dynamic> params = const {},
]) {
  final data = json.encode([
    {
      'method': 'app.callServiceExtension',
      'params': {
        'appId': '0000',
        'methodName': methodName,
        'params': params,
      }
    }
  ]);
  return contains(data.substring(2, data.length - 2));
}

Matcher isMethodCall(
  String methodName, [
  Map<String, dynamic> params = const {},
]) {
  final data = json.encode([
    {
      'method': methodName,
      'params': {
        'appId': '0000',
        ...params,
      }
    }
  ]);
  return contains(data.substring(2, data.length - 2));
}
