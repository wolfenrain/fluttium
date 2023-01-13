// ignore_for_file: prefer_const_constructors

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:fluttium_runner/fluttium_runner.dart';
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
  group('FluttiumRunner', () {
    const vars = {
      'mainEntry': 'lib/main.dart',
      'project_name': 'project_name',
      'flow_description': 'test',
      'flow_steps': [
        {'step': "await worker.tapOn(r'Text');"},
        {'step': "await worker.expectVisible(r'Text');"},
        {'step': "await worker.expectNotVisible(r'Text');"},
        {'step': "await worker.inputText(r'Text');"},
        {'step': "await worker.wait(r'Text');"},
        {'step': "await worker.takeScreenshot(r'Text');"}
      ]
    };

    late File flowFile;
    late File mainEntry;
    late Directory projectDirectory;
    late File driver;
    late File pubspec;
    late Logger logger;
    late Progress startingUpTestDriverProgress;
    late ProcessManager processManager;
    late Process process;
    late IOSink sink;
    late StreamController<List<int>> stdoutController;
    late StreamController<List<int>> stderrController;
    late Completer<int> processExitCode;
    late MasonGenerator generator;
    late List<bool?> testStepStates;
    late File screenshot;

    setUpAll(() {
      registerFallbackValue(_FakeDirectoryGeneratorTarget());
    });

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
- wait: "Text"
''');
      when(() => flowFile.path).thenReturn('flow.yaml');

      projectDirectory = _MockDirectory();
      when(() => projectDirectory.path).thenReturn('project_directory');
      driver = _MockFile();
      when(() => driver.path).thenReturn('project_directory/.test_driver.dart');
      when(() => driver.existsSync()).thenReturn(true);

      pubspec = _MockFile();
      when(() => pubspec.path).thenReturn('project_directory/pubspec.yaml');
      when(() => pubspec.readAsStringSync()).thenReturn('''
name: project_name
''');

      logger = _MockLogger();
      startingUpTestDriverProgress = _MockProgress();
      when(() => startingUpTestDriverProgress.complete(any()))
          .thenAnswer((_) {});
      when(() => startingUpTestDriverProgress.fail(any())).thenAnswer((_) {});
      when(() => logger.progress(any(that: equals('Starting up test driver'))))
          .thenReturn(startingUpTestDriverProgress);

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
      ).thenAnswer((invocation) async => process);

      generator = _MockMasonGenerator();
      when(() => generator.generate(any(), vars: any(named: 'vars')))
          .thenAnswer(
        (invocation) async => [
          GeneratedFile.created(path: 'project_directory/.test_driver.dart')
        ],
      );
      screenshot = _MockFile();
      when(() => screenshot.createSync(recursive: any(named: 'recursive')))
          .thenAnswer((_) {});

      testStepStates = [];
    });

    FluttiumRunner createRunner({
      DirectoryWatcher? directoryWatcher,
      FileWatcher? fileWatcher,
      List<String> dartDefines = const [],
    }) {
      return FluttiumRunner(
        flowFile: File('flow.yaml'),
        projectDirectory: Directory('project_directory'),
        deviceId: 'deviceId',
        renderer: (flow, stepStates) => testStepStates = stepStates,
        mainEntry: mainEntry,
        dartDefines: dartDefines,
        logger: logger,
        processManager: processManager,
        generator: (_) async => generator,
        directoryWatcher: directoryWatcher != null
            ? (path, {Duration? pollingDelay}) => directoryWatcher
            : null,
        fileWatcher: fileWatcher != null
            ? (path, {Duration? pollingDelay}) => fileWatcher
            : null,
      );
    }

    test('can run a flow test', () async {
      await IOOverrides.runZoned(
        () async {
          final fluttiumRunner = createRunner();
          final future = fluttiumRunner.run();
          // Wait for the process to start.
          await Future<void>.delayed(Duration.zero);

          // Setup project
          verify(() => mainEntry.existsSync()).called(1);
          verify(() => pubspec.readAsStringSync()).called(1);
          verify(() => mainEntry.path).called(1);

          // Generate driver
          verify(() => flowFile.readAsStringSync()).called(1);
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

    test('attaches on web as well', () async {
      await IOOverrides.runZoned(
        () async {
          final fluttiumRunner = createRunner();
          final future = fluttiumRunner.run();
          // Wait for the process to start.
          await Future<void>.delayed(Duration.zero);

          // Setup project
          verify(() => mainEntry.existsSync()).called(1);
          verify(() => pubspec.readAsStringSync()).called(1);
          verify(() => mainEntry.path).called(1);

          // Generate driver
          verify(() => flowFile.readAsStringSync()).called(1);
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
          stdoutController.add(utf8.encode('Flutter Web Bootstrap: auto'));
          await Future<void>.delayed(Duration.zero);
          verify(() => startingUpTestDriverProgress.complete()).called(1);

          processExitCode.complete(ExitCode.success.code);
          await future;

          verifyNever(
            () => startingUpTestDriverProgress
                .fail('Failed to start test driver'),
          );
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

    test('runs with custom dart defines', () async {
      await IOOverrides.runZoned(
        () async {
          final fluttiumRunner = createRunner(
            dartDefines: [
              'FLUTTER_WEB_USE_SKIA=true',
              'FLUTTER_WEB_AUTO_DETECT=true',
            ],
          );
          final future = fluttiumRunner.run();
          // Wait for the process to start.
          await Future<void>.delayed(Duration.zero);

          // Setup project
          verify(() => mainEntry.existsSync()).called(1);
          verify(() => pubspec.readAsStringSync()).called(1);
          verify(() => mainEntry.path).called(1);

          // Generate driver
          verify(() => flowFile.readAsStringSync()).called(1);
          verify(
            () => generator.generate(
              any(),
              vars: any(named: 'vars', that: equals(vars)),
            ),
          ).called(1);

          // Validate that it was called with the correct dart defines
          verify(
            () => processManager.start(
              any(
                that: equals(
                  [
                    'flutter',
                    'run',
                    'project_directory/.test_driver.dart',
                    '-d',
                    'deviceId',
                    '--dart-define',
                    'FLUTTER_WEB_USE_SKIA=true',
                    '--dart-define',
                    'FLUTTER_WEB_AUTO_DETECT=true',
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

          processExitCode.complete(ExitCode.success.code);
          await future;
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

    test('quit early if a step failed', () async {
      await IOOverrides.runZoned(
        () async {
          final fluttiumRunner = createRunner();
          final future = fluttiumRunner.run();
          // Wait for the process to start.
          await Future<void>.delayed(Duration.zero);

          // Trigger the attach
          stdoutController.add(utf8.encode('flutter: fake message'));
          await Future<void>.delayed(Duration.zero);

          // Trigger the first step
          stdoutController.add(utf8.encode('flutter: fluttium:start:null;'));
          await Future<void>.delayed(Duration.zero);
          expect(testStepStates.length, 1);
          expect(testStepStates[0], null);

          // Fail the first step
          stdoutController.add(utf8.encode('flutter: fluttium:fail:null;'));
          await Future<void>.delayed(Duration.zero);
          expect(testStepStates.length, 1);
          expect(testStepStates[0], false);
          await future;

          verifyNever(
            () => startingUpTestDriverProgress
                .fail('Failed to start test driver'),
          );
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

    test('triggers screenshot action', () async {
      await IOOverrides.runZoned(
        () async {
          final fluttiumRunner = createRunner();
          final future = fluttiumRunner.run();
          // Wait for the process to start.
          await Future<void>.delayed(Duration.zero);

          // Trigger the attach
          stdoutController.add(utf8.encode('flutter: fake message'));
          await Future<void>.delayed(Duration.zero);

          // Trigger the first step
          stdoutController.add(utf8.encode('flutter: fluttium:start:null;'));
          await Future<void>.delayed(Duration.zero);

          // Trigger screenshot action
          stdoutController
              .add(utf8.encode('flutter: fluttium:screenshot:1,2,3;'));
          await Future<void>.delayed(Duration.zero);

          processExitCode.complete(ExitCode.success.code);
          await future;

          verify(
            () => screenshot.createSync(recursive: any(named: 'recursive')),
          ).called(1);
          verify(
            () => screenshot.writeAsBytesSync(
              any(that: equals(<int>[1, 2, 3])),
            ),
          ).called(1);
        },
        createFile: (path) {
          if (path == 'flow.yaml') {
            return flowFile;
          } else if (path == 'project_directory/.test_driver.dart') {
            return driver;
          } else if (path == 'project_directory/pubspec.yaml') {
            return pubspec;
          } else if (path == 'project_directory/screenshots/Text.png') {
            return screenshot;
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

    test('fails if never attached', () async {
      await IOOverrides.runZoned(
        () async {
          final fluttiumRunner = createRunner();
          final future = fluttiumRunner.run();
          // Wait for the process to start.
          await Future<void>.delayed(Duration.zero);

          // Setup project
          verify(() => mainEntry.existsSync()).called(1);
          verify(() => pubspec.readAsStringSync()).called(1);
          verify(() => mainEntry.path).called(1);

          // Generate driver
          verify(() => flowFile.readAsStringSync()).called(1);
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

          processExitCode.complete(ExitCode.success.code);
          await future;

          verify(
            () => startingUpTestDriverProgress
                .fail('Failed to start test driver'),
          ).called(1);
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

    test('fails if main entry does not exists', () async {
      when(mainEntry.existsSync).thenReturn(false);

      await IOOverrides.runZoned(
        () async {
          final fluttiumRunner = FluttiumRunner(
            flowFile: File('flow.yaml'),
            projectDirectory: Directory('project_directory'),
            deviceId: 'deviceId',
            renderer: (flow, stepStates) {},
            mainEntry: mainEntry,
            logger: logger,
            processManager: processManager,
            generator: (_) async => generator,
          );

          await expectLater(fluttiumRunner.run, throwsException);

          // Setup project
          verify(() => mainEntry.existsSync());
          verifyNever(() => pubspec.readAsStringSync());
          verifyNever(() => mainEntry.path);

          // Generate driver
          verifyNever(() => flowFile.readAsStringSync());
          verifyNever(
            () => generator.generate(
              any(),
              vars: any(named: 'vars', that: equals(vars)),
            ),
          );

          // Rest of the run
          verifyNever(
            () => logger.progress(any(that: equals('Starting up test driver'))),
          );
          verifyNever(
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
          );

          verifyNever(
            () => startingUpTestDriverProgress
                .fail('Failed to start test driver'),
          );
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

      test('restarts if a project file changes', () async {
        await IOOverrides.runZoned(
          () async {
            final fluttiumRunner = createRunner(
              directoryWatcher: directoryWatcher,
              fileWatcher: fileWatcher,
            );
            final future = fluttiumRunner.run(watch: true);
            // Wait for the process to start.
            await Future<void>.delayed(Duration.zero);

            // Trigger the attach
            stdoutController.add(utf8.encode('flutter: fake message'));
            await Future<void>.delayed(Duration.zero);

            // Trigger a file change
            watchEventController.add(
              WatchEvent(ChangeType.MODIFY, 'project_directory/lib/main.dart'),
            );
            await Future<void>.delayed(Duration.zero);

            verify(() => process.stdin.write(any(that: equals('R')))).called(1);

            processExitCode.complete(ExitCode.success.code);
            await future;
          },
          createFile: (path) {
            if (path == 'flow.yaml') {
              return flowFile;
            } else if (path == 'project_directory/.test_driver.dart') {
              return driver;
            } else if (path == 'project_directory/pubspec.yaml') {
              return pubspec;
            } else if (path == 'project_directory/screenshots/Text.png') {
              return screenshot;
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

      test('logs an error if it temporary cant watch a file', () async {
        await IOOverrides.runZoned(
          () async {
            final fluttiumRunner = createRunner(
              directoryWatcher: directoryWatcher,
              fileWatcher: fileWatcher,
            );
            final future = fluttiumRunner.run(watch: true);
            // Wait for the process to start.
            await Future<void>.delayed(Duration.zero);

            // Trigger the attach
            stdoutController.add(utf8.encode('flutter: fake message'));
            await Future<void>.delayed(Duration.zero);

            // Trigger a file change
            watchEventController.addError(
              FileSystemException('Failed to watch'),
            );
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
          },
          createFile: (path) {
            if (path == 'flow.yaml') {
              return flowFile;
            } else if (path == 'project_directory/.test_driver.dart') {
              return driver;
            } else if (path == 'project_directory/pubspec.yaml') {
              return pubspec;
            } else if (path == 'project_directory/screenshots/Text.png') {
              return screenshot;
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

      test('regenerate driver if flow file changes', () async {
        await IOOverrides.runZoned(
          () async {
            final fluttiumRunner = createRunner(
              directoryWatcher: directoryWatcher,
              fileWatcher: fileWatcher,
            );
            final future = fluttiumRunner.run(watch: true);
            // Wait for the process to start.
            await Future<void>.delayed(Duration.zero);

            verify(() => flowFile.readAsStringSync()).called(1);

            // Trigger the attach
            stdoutController.add(utf8.encode('flutter: fake message'));
            await Future<void>.delayed(Duration.zero);

            verifyNever(() => flowFile.readAsStringSync());
            fileWatchEventController.add(
              WatchEvent(ChangeType.MODIFY, 'flow.yaml'),
            );
            await Future<void>.delayed(Duration.zero);
            verify(() => flowFile.readAsStringSync()).called(1);
            verify(() => process.stdin.write(any(that: equals('R')))).called(1);

            processExitCode.complete(ExitCode.success.code);
            await future;
          },
          createFile: (path) {
            if (path == 'flow.yaml') {
              return flowFile;
            } else if (path == 'project_directory/.test_driver.dart') {
              return driver;
            } else if (path == 'project_directory/pubspec.yaml') {
              return pubspec;
            } else if (path == 'project_directory/screenshots/Text.png') {
              return screenshot;
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
  });
}
