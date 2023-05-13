import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:fluttium_cli/src/commands/commands.dart';
import 'package:fluttium_cli/src/commands/test_command/reporters/reporters.dart';
import 'package:fluttium_cli/src/flutter_device.dart';
import 'package:fluttium_driver/fluttium_driver.dart';
import 'package:fluttium_interfaces/fluttium_interfaces.dart';
import 'package:mason/mason.dart';
import 'package:mocktail/mocktail.dart';
import 'package:process/process.dart';
import 'package:test/test.dart';

import '../../../helpers/helpers.dart';

const expectedUsage = [
  // ignore: no_adjacent_strings_in_list
  'Run a user flow test.\n'
      '\n'
      'Usage: fluttium test <flow.yaml> [arguments]\n'
      '-h, --help                        Print this usage information.\n'
      '-w, --watch                       Watch for file changes.\n'
      // ignore: lines_longer_than_80_chars
      '-d, --device-id                   Target device id or name (prefixes allowed).\n'
      // ignore: lines_longer_than_80_chars
      '    --flavor                      Build a custom app flavor as defined by platform-specific build setup.\n'
      // ignore: lines_longer_than_80_chars
      '                                  This will be passed to the --flavor option of flutter run.\n'
      // ignore: lines_longer_than_80_chars
      '-t, --target                      The main entry-point file of the application, as run on the device.\n'
      // ignore: lines_longer_than_80_chars
      '                                  (defaults to "lib/main.dart")\n'
      // ignore: lines_longer_than_80_chars
      '    --dart-define=<key=value>     Pass additional key-value pairs to the flutter run.\n'
      // ignore: lines_longer_than_80_chars
      '                                  Multiple defines can be passed by repeating "--dart-define" multiple times.\n'
      '-r, --reporter                    \n'
      // ignore: lines_longer_than_80_chars
      '          [compact]               A single line that updates dynamically.\n'
      // ignore: lines_longer_than_80_chars
      '          [expanded] (default)    A separate line for each update.\n'
      // ignore: lines_longer_than_80_chars
      '          [pretty]                A nicely formatted output that works nicely with --watch.\n'
      '\n'
      'Run "fluttium help" to see global options.'
];

class _FakeLogger extends Fake implements Logger {}

class _MockFluttiumDriver extends Mock implements FluttiumDriver {}

class _MockLogger extends Mock implements Logger {}

class _MockProgress extends Mock implements Progress {}

class _MockProcessManager extends Mock implements ProcessManager {}

class _MockArgResults extends Mock implements ArgResults {}

class _MockFile extends Mock implements File {}

class _MockDirectory extends Mock implements Directory {}

class _MockStdin extends Mock implements Stdin {}

class _MockUserFlowYaml extends Mock implements UserFlowYaml {}

class _MockStreamSubscription<T> extends Mock
    implements StreamSubscription<T> {}

void main() {
  group('test', () {
    late FluttiumDriver driver;
    late Logger logger;
    late Progress retrievingDevices;
    late ProcessManager processManager;
    late ProcessResult flutterDevicesResult;
    late ArgResults argResults;
    late File userFlowFile;
    late Directory projectDirectory;
    late Directory platformDirectory;
    late File pubspecFile;
    late File fluttiumFile;
    late File targetFile;
    late StreamController<List<StepState>> stepStateController;
    late Stdin stdin;
    late File testFile;
    late Completer<void> runCompleter;

    setUpAll(() {
      registerFallbackValue(_FakeLogger());
    });

    setUp(() {
      driver = _MockFluttiumDriver();
      runCompleter = Completer();
      when(driver.run).thenAnswer((_) => runCompleter.future);

      final userFlow = _MockUserFlowYaml();
      when(() => userFlow.description).thenReturn('description');
      when(() => driver.userFlow).thenReturn(userFlow);

      stepStateController = StreamController();
      when(() => driver.steps).thenAnswer((_) => stepStateController.stream);

      logger = _MockLogger();

      retrievingDevices = _MockProgress();
      when(() => logger.progress(any(that: equals('Retrieving devices'))))
          .thenReturn(retrievingDevices);

      processManager = _MockProcessManager();

      flutterDevicesResult = ProcessResult(
        0,
        0,
        json.encode([
          {
            'name': 'macOS',
            'id': 'macos',
            'isSupported': true,
            'targetPlatform': 'darwin',
          }
        ]),
        '',
      );
      when(
        () => processManager.run(
          any(
            that: equals(
              ['flutter', '--no-version-check', 'devices', '--machine'],
            ),
          ),
          runInShell: any(named: 'runInShell'),
          workingDirectory: any(named: 'workingDirectory'),
        ),
      ).thenAnswer((_) async => flutterDevicesResult);

      argResults = _MockArgResults();
      when(() => argResults.rest).thenReturn(['test_flow.yaml']);
      when(() => argResults['watch']).thenReturn(false);
      when(() => argResults['target']).thenReturn('lib/main.dart');
      when(() => argResults['dart-define']).thenReturn(<String>[]);
      when(() => argResults['reporter']).thenReturn('pretty');
      when(() => argResults.wasParsed(any())).thenReturn(false);

      pubspecFile = _MockFile();
      when(() => pubspecFile.path).thenReturn('pubspec.yaml');

      projectDirectory = _MockDirectory();
      when(() => projectDirectory.absolute).thenReturn(projectDirectory);
      when(() => projectDirectory.listSync()).thenReturn([pubspecFile]);
      when(() => projectDirectory.path).thenReturn('project_directory');

      platformDirectory = _MockDirectory();
      when(() => platformDirectory.existsSync()).thenReturn(true);

      userFlowFile = _MockFile();
      when(() => userFlowFile.path)
          .thenReturn('project_directory/test_flow.yaml');
      when(() => userFlowFile.existsSync()).thenReturn(true);
      when(() => userFlowFile.parent).thenReturn(projectDirectory);

      fluttiumFile = _MockFile();
      when(() => fluttiumFile.existsSync()).thenReturn(true);
      when(() => fluttiumFile.readAsStringSync()).thenReturn('''
environment:
  fluttium: ">=0.1.0 <0.2.0"
''');

      targetFile = _MockFile();
      when(() => targetFile.existsSync()).thenReturn(true);
      when(() => targetFile.path).thenReturn('project_directory/lib/main.dart');

      testFile = _MockFile();
      when(() => testFile.createSync(recursive: any(named: 'recursive')))
          .thenAnswer((_) {});
      when(() => testFile.writeAsBytesSync(any())).thenAnswer((_) {});

      stdin = _MockStdin();
      when(() => stdin.hasTerminal).thenReturn(true);
      when(() => stdin.echoMode).thenReturn(true);
      when(() => stdin.lineMode).thenReturn(true);
    });

    test(
      'help',
      withRunner(
        (commandRunner, logger, processManager) async {
          final result = await commandRunner.run(['test', '--help']);
          expect(result, equals(ExitCode.success.code));

          final resultAbbr = await commandRunner.run(['test', '-h']);
          expect(resultAbbr, equals(ExitCode.success.code));
        },
        verifyPrints: (printLogs) {
          expect(printLogs, equals([...expectedUsage, ...expectedUsage]));
        },
      ),
    );

    Future<void> runWithMocks(
      Future<void> Function() callback, {
      Map<String, File> customFiles = const {},
    }) async {
      await IOOverrides.runZoned(
        callback,
        createFile: (path) {
          if (path.endsWith('test_flow.yaml')) {
            return userFlowFile;
          } else if (path.endsWith('fluttium.yaml')) {
            return fluttiumFile;
          } else if (path.endsWith('main.dart')) {
            return targetFile;
          } else if (path.endsWith('test_file')) {
            return testFile;
          }
          if (customFiles.containsKey(path)) {
            return customFiles[path]!;
          }
          throw UnimplementedError(path);
        },
        createDirectory: (path) {
          if (path.endsWith('project_directory')) {
            return projectDirectory;
          }
          return platformDirectory;
        },
        stdin: () => stdin,
      );
    }

    test('completes running the fluttium driver', () async {
      final command = TestCommand(
        logger: logger,
        processManager: processManager,
        driver: _driver(driver),
      )..testArgResults = argResults;

      await runWithMocks(() async {
        final future = command.run();

        final step =
            StepState('Expect visible "text"', status: StepStatus.done);
        stepStateController.add([step]);
        await Future<void>.delayed(Duration.zero);

        await stepStateController.close();
        runCompleter.complete();
        expect(await future, equals(ExitCode.success.code));
      });
    });

    test('completes running the fluttium driver without a fluttium.yaml file',
        () async {
      when(() => fluttiumFile.existsSync()).thenReturn(false);

      final command = TestCommand(
        logger: logger,
        processManager: processManager,
        driver: _driver(driver),
      )..testArgResults = argResults;

      await runWithMocks(() async {
        final future = command.run();

        final step =
            StepState('Expect visible "text"', status: StepStatus.done);
        stepStateController.add([step]);
        await Future<void>.delayed(Duration.zero);

        await stepStateController.close();
        runCompleter.complete();
        expect(await future, equals(ExitCode.success.code));
      });
    });

    test('exits when a fatal exception occurred', () async {
      when(driver.quit).thenAnswer((_) async {});

      final command = TestCommand(
        logger: logger,
        processManager: processManager,
        driver: _driver(driver),
      )..testArgResults = argResults;

      await runWithMocks(() async {
        final future = command.run();

        final step = StepState('Expect visible "text"');
        stepStateController.add([step]);
        await Future<void>.delayed(Duration.zero);

        stepStateController.addError(FatalDriverException('fatal reason'));
        await Future<void>.delayed(Duration.zero);

        await stepStateController.close();
        runCompleter.complete();
        expect(await future, equals(ExitCode.tempFail.code));

        verify(
          () => logger.err(
            any(
              that: equals(' Fatal driver exception occurred: fatal reason'),
            ),
          ),
        ).called(1);
        verify(driver.quit).called(1);
      });
    });

    test('logs when an unknown exception occurred', () async {
      when(driver.quit).thenAnswer((_) async {});

      final command = TestCommand(
        logger: logger,
        processManager: processManager,
        driver: _driver(driver),
      )..testArgResults = argResults;

      await runWithMocks(() async {
        final future = command.run();

        final step = StepState('Expect visible "text"');
        stepStateController.add([step]);
        await Future<void>.delayed(Duration.zero);

        stepStateController.addError('unknown reason');
        await Future<void>.delayed(Duration.zero);

        await stepStateController.close();
        runCompleter.complete();
        expect(await future, equals(ExitCode.tempFail.code));

        verify(
          () => logger.err(
            any(that: equals('Unknown exception occurred: unknown reason')),
          ),
        ).called(1);
      });
    });

    group('exits early', () {
      test(
        'exits early if no flow file was specified',
        withRunner((commandRunner, logger, processManager) async {
          final result = await commandRunner.run(['test']);

          expect(result, equals(ExitCode.usage.code));
        }),
      );

      test('if the given flow file does not exists', () async {
        when(userFlowFile.existsSync).thenReturn(false);

        final command = TestCommand(
          logger: logger,
          processManager: processManager,
          driver: _driver(driver),
        )..testArgResults = argResults;

        await runWithMocks(() async {
          final result = await command.run();
          expect(result, equals(ExitCode.unavailable.code));

          verify(
            () => logger.err(
              any(
                that: equals(
                  'Flow file "project_directory/test_flow.yaml" not found.',
                ),
              ),
            ),
          ).called(1);
        });
      });

      test('if fluttium version does not fit constraints', () async {
        when(() => fluttiumFile.readAsStringSync()).thenReturn('''
environment:
  fluttium: ">=999.999.998 <999.999.999"
''');

        final command = TestCommand(
          logger: logger,
          processManager: processManager,
          driver: _driver(driver),
        )..testArgResults = argResults;

        await runWithMocks(() async {
          final result = await command.run();
          expect(result, equals(ExitCode.unavailable.code));

          verify(
            () => logger.err(
              any(
                that: equals(
                  '''
Version solving failed:
  The Fluttium CLI uses "${FluttiumDriver.fluttiumVersionConstraint}" as the version constraint.
  The current project uses ">=999.999.998 <999.999.999" as defined in the fluttium.yaml.

Either adjust the constraint in the Fluttium configuration or update the CLI to a compatible version.''',
                ),
              ),
            ),
          ).called(1);
        });
      });

      test('if no pubspec was found in parent directories', () async {
        final parentDirectory = _MockDirectory();
        when(parentDirectory.listSync).thenReturn([]);
        when(() => parentDirectory.parent).thenReturn(parentDirectory);

        when(() => projectDirectory.listSync()).thenReturn([]);
        when(() => projectDirectory.parent).thenReturn(parentDirectory);

        final command = TestCommand(
          logger: logger,
          processManager: processManager,
          driver: _driver(driver),
        )..testArgResults = argResults;

        await runWithMocks(() async {
          final result = await command.run();
          expect(result, equals(ExitCode.unavailable.code));

          verify(
            () => logger.err(
              any(
                that: equals(
                  'Could not find pubspec.yaml in parent directories.',
                ),
              ),
            ),
          ).called(1);
        });
      });

      test('if the target file does not exist', () async {
        when(targetFile.existsSync).thenReturn(false);

        final command = TestCommand(
          logger: logger,
          processManager: processManager,
          driver: _driver(driver),
        )..testArgResults = argResults;

        await runWithMocks(() async {
          final result = await command.run();
          expect(result, equals(ExitCode.unavailable.code));

          verify(
            () => logger.err(
              any(
                that: equals('Target file "lib/main.dart" not found.'),
              ),
            ),
          ).called(1);
        });
      });
    });

    test('validates all platforms', () async {
      for (final platform in [
        const MapEntry('web', 'web'),
        const MapEntry('macos', 'darwin'),
        const MapEntry('android', 'android'),
        const MapEntry('ios', 'ios'),
        const MapEntry('windows', 'windows'),
        const MapEntry('linux', 'linux'),
      ]) {
        flutterDevicesResult = ProcessResult(
          0,
          0,
          json.encode([
            {
              'name': platform.value,
              'id': platform.value,
              'isSupported': true,
              'targetPlatform': platform.value,
            }
          ]),
          '',
        );

        // Recreate the controller
        stepStateController = StreamController();

        // Recreate the completer.
        runCompleter = Completer();
        when(() => driver.run()).thenAnswer((_) => runCompleter.future);

        final command = TestCommand(
          logger: logger,
          processManager: processManager,
          driver: _driver(driver),
        )..testArgResults = argResults;

        await runWithMocks(
          () async {
            final future = command.run();

            final step =
                StepState('Expect visible "text"', status: StepStatus.done);
            stepStateController.add([step]);
            await Future<void>.delayed(Duration.zero);

            await stepStateController.close();
            runCompleter.complete();
            expect(await future, equals(ExitCode.success.code));

            verify(
              () => logger.progress(any(that: equals('Retrieving devices'))),
            ).called(1);
            verify(retrievingDevices.complete).called(1);
            verifyNever(retrievingDevices.cancel);
            verifyNever(
              () => logger.chooseOne<FlutterDevice>(
                any(that: equals('Choose a device:')),
                choices: any(named: 'choices'),
                display: any(named: 'display'),
              ),
            );
          },
        );
      }
    });

    group('retrieving device data', () {
      test('run on specified device', () async {
        when(() => argResults['device-id']).thenReturn('macos');

        flutterDevicesResult = ProcessResult(
          0,
          0,
          json.encode([
            {
              'name': 'macOS',
              'id': 'macos',
              'isSupported': true,
              'targetPlatform': 'darwin',
            },
            {
              'name': 'iOS',
              'id': 'ios',
              'isSupported': true,
              'targetPlatform': 'ios',
            }
          ]),
          '',
        );

        final command = TestCommand(
          logger: logger,
          processManager: processManager,
          driver: _driver(driver),
        )..testArgResults = argResults;

        await runWithMocks(() async {
          final future = command.run();

          final step =
              StepState('Expect visible "text"', status: StepStatus.done);
          stepStateController.add([step]);
          await Future<void>.delayed(Duration.zero);

          await stepStateController.close();
          runCompleter.complete();
          expect(await future, equals(ExitCode.success.code));

          verifyNever(
            () => logger.progress(any(that: equals('Retrieving devices'))),
          );
          verifyNever(retrievingDevices.cancel);
          verifyNever(
            () => logger.chooseOne<FlutterDevice>(
              any(that: equals('Choose a device:')),
              choices: any(named: 'choices'),
              display: any(named: 'display'),
            ),
          );
        });
      });

      test('prompts user which device to run on', () async {
        flutterDevicesResult = ProcessResult(
          0,
          0,
          json.encode([
            {
              'name': 'macOS',
              'id': 'macos',
              'isSupported': true,
              'targetPlatform': 'darwin',
            },
            {
              'name': 'iOS',
              'id': 'ios',
              'isSupported': true,
              'targetPlatform': 'ios',
            }
          ]),
          '',
        );

        final command = TestCommand(
          logger: logger,
          processManager: processManager,
          driver: _driver(driver),
        )..testArgResults = argResults;

        await runWithMocks(() async {
          when(
            () => logger.chooseOne<FlutterDevice>(
              any(that: equals('Choose a device:')),
              choices: any(named: 'choices'),
              display: any(named: 'display'),
            ),
          ).thenAnswer(
            (invocation) {
              final device = FlutterDevice({
                'name': 'macOS',
                'id': 'macos',
                'isSupported': true,
                'targetPlatform': 'darwin',
              });
              final display =
                  (invocation.namedArguments[#display] as String Function(
                FlutterDevice,
              ))(device);
              expect(display, equals('macOS (macos)'));

              return device;
            },
          );

          final future = command.run();

          final step =
              StepState('Expect visible "text"', status: StepStatus.done);
          stepStateController.add([step]);
          await Future<void>.delayed(Duration.zero);

          await stepStateController.close();
          runCompleter.complete();
          expect(await future, equals(ExitCode.success.code));

          verify(
            () => logger.progress(any(that: equals('Retrieving devices'))),
          ).called(1);
          verify(retrievingDevices.cancel).called(1);
          verifyNever(retrievingDevices.complete);
          verifyNever(retrievingDevices.fail);
          verify(
            () => logger.chooseOne<FlutterDevice>(
              any(that: equals('Choose a device:')),
              choices: any(named: 'choices'),
              display: any(named: 'display'),
            ),
          ).called(1);
        });
      });

      test('exits early if no devices are found', () async {
        flutterDevicesResult = ProcessResult(0, 0, json.encode([]), '');

        final command = TestCommand(
          logger: logger,
          processManager: processManager,
          driver: _driver(driver),
        )..testArgResults = argResults;

        await runWithMocks(() async {
          final future = command.run();

          final step =
              StepState('Expect visible "text"', status: StepStatus.done);
          stepStateController.add([step]);
          await Future<void>.delayed(Duration.zero);

          runCompleter.complete();
          expect(await future, equals(ExitCode.unavailable.code));

          verify(
            () => logger.progress(any(that: equals('Retrieving devices'))),
          ).called(1);
          verifyNever(retrievingDevices.complete);
          verify(retrievingDevices.fail).called(1);
          verifyNever(retrievingDevices.cancel);
          verifyNever(
            () => logger.chooseOne<FlutterDevice>(
              any(that: equals('Choose a device:')),
              choices: any(named: 'choices'),
              display: any(named: 'display'),
            ),
          );

          verify(() => logger.err(any(that: equals('No devices found.'))))
              .called(1);
        });
      });
    });

    test('exits when unknown reporter is used', () async {
      // Fun fact: this test is only for line coverage, command parser never
      // allows us to pass an unknown reporter as a user of the CLI.
      when(() => argResults['reporter']).thenReturn('unknown');

      final command = TestCommand(
        logger: logger,
        processManager: processManager,
        driver: _driver(driver),
      )..testArgResults = argResults;

      await runWithMocks(() async {
        final future = command.run();
        expect(await future, equals(ExitCode.usage.code));

        verify(() => logger.err(any(that: equals('Unknown reporter: unknown'))))
            .called(1);
      });
    });

    test('stores received files', () async {
      final userFlow = _MockUserFlowYaml();
      when(() => userFlow.description).thenReturn('description');
      when(() => driver.userFlow).thenReturn(userFlow);

      final receivedFile = _MockFile();
      when(() => receivedFile.createSync(recursive: any(named: 'recursive')))
          .thenAnswer((invocation) {});
      when(() => receivedFile.writeAsBytesSync(any()))
          .thenAnswer((invocation) {});

      final command = TestCommand(
        logger: logger,
        processManager: processManager,
        driver: _driver(driver),
      )..testArgResults = argResults;

      await runWithMocks(
        () async {
          final future = command.run();

          final step = StepState('Storing file: "file.txt"');

          stepStateController.add([step]);
          await Future<void>.delayed(Duration.zero);

          verify(() => logger.info('  🔲  Storing file: "file.txt"')).called(1);

          stepStateController.add([
            step.copyWith(
              status: StepStatus.done,
              files: {
                'file.txt': [1, 2, 3]
              },
            )
          ]);
          await Future<void>.delayed(Duration.zero);

          verify(() => logger.detail('Writing 3 bytes to "file.txt"'))
              .called(1);
          verify(() => logger.info('  ✅  Storing file: "file.txt"')).called(1);
          verify(
            () => receivedFile.createSync(
              recursive: any(named: 'recursive', that: isTrue),
            ),
          ).called(1);
          verify(
            () => receivedFile.writeAsBytesSync(any(that: equals([1, 2, 3]))),
          ).called(1);

          await stepStateController.close();
          runCompleter.complete();
          expect(await future, equals(ExitCode.success.code));
        },
        customFiles: {
          'file.txt': receivedFile,
        },
      );
    });

    test('renders using the $PrettyReporter for all steps', () async {
      final userFlow = _MockUserFlowYaml();
      when(() => userFlow.description).thenReturn('description');
      when(() => driver.userFlow).thenReturn(userFlow);

      final command = TestCommand(
        logger: logger,
        processManager: processManager,
        driver: _driver(driver),
      )..testArgResults = argResults;

      await runWithMocks(() async {
        final future = command.run();

        final step1 = StepState('Expect visible "text"');
        final step2 = StepState('Expect not visible "text"');
        final step3 = StepState('Tap on "text"');

        stepStateController.add([step1, step2, step3]);
        await Future<void>.delayed(Duration.zero);

        verify(() => logger.info('  🔲  Expect visible "text"')).called(1);
        verify(() => logger.info('  🔲  Expect not visible "text"')).called(1);
        verify(() => logger.info('  🔲  Tap on "text"')).called(1);

        stepStateController
            .add([step1.copyWith(status: StepStatus.running), step2, step3]);
        await Future<void>.delayed(Duration.zero);

        verify(() => logger.info('  ⏳  Expect visible "text"')).called(1);
        verify(() => logger.info('  🔲  Expect not visible "text"')).called(1);
        verify(() => logger.info('  🔲  Tap on "text"')).called(1);

        stepStateController.add([
          step1.copyWith(status: StepStatus.done),
          step2.copyWith(status: StepStatus.running),
          step3
        ]);
        await Future<void>.delayed(Duration.zero);

        verify(() => logger.info('  ✅  Expect visible "text"')).called(1);
        verify(() => logger.info('  ⏳  Expect not visible "text"')).called(1);
        verify(() => logger.info('  🔲  Tap on "text"')).called(1);

        stepStateController.add([
          step1.copyWith(status: StepStatus.done),
          step2.copyWith(status: StepStatus.failed),
          step3
        ]);
        await Future<void>.delayed(Duration.zero);

        verify(() => logger.info('  ✅  Expect visible "text"')).called(1);
        verify(() => logger.info('  ❌  Expect not visible "text"')).called(1);
        verify(() => logger.info('  🔲  Tap on "text"')).called(1);

        verify(
          () => logger.info(any(that: contains('description'))),
        ).called(4);

        await stepStateController.close();
        runCompleter.complete();
        expect(await future, equals(ExitCode.tempFail.code));
      });
    });

    group('renders using the $CompactReporter', () {
      late Progress progress;

      setUp(() {
        final userFlow = _MockUserFlowYaml();
        when(() => userFlow.description).thenReturn('description');
        when(() => driver.userFlow).thenReturn(userFlow);
        when(() => argResults['reporter']).thenReturn('compact');

        progress = _MockProgress();
        when(() => logger.progress(any())).thenReturn(progress);
      });

      test('until all done', () async {
        final command = TestCommand(
          logger: logger,
          processManager: processManager,
          driver: _driver(driver),
        )..testArgResults = argResults;

        await runWithMocks(() async {
          final future = command.run();

          final step1 = StepState('Expect visible "text"');
          final step2 = StepState('Expect not visible "text"');
          final step3 = StepState('Tap on "text"');

          stepStateController.add([step1, step2, step3]);
          await Future<void>.delayed(Duration.zero);
          verify(() => logger.progress(any(that: equals('')))).called(1);

          verify(
            () =>
                progress.update(any(that: equals('1/3 Expect visible "text"'))),
          ).called(1);

          stepStateController
              .add([step1.copyWith(status: StepStatus.running), step2, step3]);
          await Future<void>.delayed(Duration.zero);

          verify(
            () =>
                progress.update(any(that: equals('1/3 Expect visible "text"'))),
          ).called(1);

          stepStateController.add([
            step1.copyWith(status: StepStatus.done),
            step2.copyWith(status: StepStatus.running),
            step3
          ]);
          await Future<void>.delayed(Duration.zero);

          verify(
            () => progress
                .update(any(that: equals('2/3 Expect not visible "text"'))),
          ).called(1);

          stepStateController.add([
            step1.copyWith(status: StepStatus.done),
            step2.copyWith(status: StepStatus.done),
            step3.copyWith(status: StepStatus.done)
          ]);
          await Future<void>.delayed(Duration.zero);

          verify(progress.complete).called(1);

          await stepStateController.close();
          runCompleter.complete();
          expect(await future, equals(ExitCode.success.code));
        });
      });

      test('with a failure', () async {
        final command = TestCommand(
          logger: logger,
          processManager: processManager,
          driver: _driver(driver),
        )..testArgResults = argResults;

        await runWithMocks(() async {
          final future = command.run();

          final step1 = StepState('Expect visible "text"');
          final step2 = StepState('Expect not visible "text"');
          final step3 = StepState('Tap on "text"');

          stepStateController.add([step1, step2, step3]);
          await Future<void>.delayed(Duration.zero);
          verify(() => logger.progress(any(that: equals('')))).called(1);

          verify(
            () =>
                progress.update(any(that: equals('1/3 Expect visible "text"'))),
          ).called(1);

          stepStateController
              .add([step1.copyWith(status: StepStatus.running), step2, step3]);
          await Future<void>.delayed(Duration.zero);

          verify(
            () =>
                progress.update(any(that: equals('1/3 Expect visible "text"'))),
          ).called(1);

          stepStateController.add([
            step1.copyWith(status: StepStatus.done),
            step2.copyWith(status: StepStatus.running),
            step3
          ]);
          await Future<void>.delayed(Duration.zero);

          verify(
            () => progress
                .update(any(that: equals('2/3 Expect not visible "text"'))),
          ).called(1);

          stepStateController.add([
            step1.copyWith(status: StepStatus.done),
            step2.copyWith(status: StepStatus.failed),
            step3
          ]);
          await Future<void>.delayed(Duration.zero);

          verify(progress.fail).called(1);

          await stepStateController.close();
          runCompleter.complete();
          expect(await future, equals(ExitCode.tempFail.code));
        });
      });

      test('exits when a fatal exception occurred', () async {
        when(driver.quit).thenAnswer((_) async {});

        final command = TestCommand(
          logger: logger,
          processManager: processManager,
          driver: _driver(driver),
        )..testArgResults = argResults;

        await runWithMocks(() async {
          final future = command.run();

          final step = StepState('Expect visible "text"');
          stepStateController.add([step]);
          await Future<void>.delayed(Duration.zero);

          stepStateController.addError(FatalDriverException('fatal reason'));
          await Future<void>.delayed(Duration.zero);

          await stepStateController.close();
          runCompleter.complete();
          expect(await future, equals(ExitCode.tempFail.code));
          verify(driver.quit).called(1);
        });
      });

      test('throws exception if running with watch', () async {
        when(() => argResults['reporter']).thenReturn('compact');
        when(() => argResults['watch']).thenReturn(true);

        final command = TestCommand(
          logger: logger,
          processManager: processManager,
          driver: _driver(driver),
        )..testArgResults = argResults;

        await runWithMocks(() async {
          final future = command.run();

          expect(await future, equals(ExitCode.usage.code));

          verify(
            () => logger.err(
              any(
                that:
                    equals('The compact reporter does not support watch mode.'),
              ),
            ),
          ).called(1);
        });
      });
    });

    group('renders using the $ExpandedReporter', () {
      setUp(() {
        final userFlow = _MockUserFlowYaml();
        when(() => userFlow.description).thenReturn('description');
        when(() => driver.userFlow).thenReturn(userFlow);
        when(() => argResults['reporter']).thenReturn('expanded');
      });

      test('until all done', () async {
        final command = TestCommand(
          logger: logger,
          processManager: processManager,
          driver: _driver(driver),
        )..testArgResults = argResults;

        await runWithMocks(() async {
          final future = command.run();

          final step1 = StepState('Expect visible "text"');
          final step2 = StepState('Expect not visible "text"');
          final step3 = StepState('Tap on "text"');

          stepStateController.add([step1, step2, step3]);
          await Future<void>.delayed(Duration.zero);

          verify(
            () => logger.info(any(that: contains('Expect visible "text"'))),
          ).called(1);

          stepStateController
              .add([step1.copyWith(status: StepStatus.running), step2, step3]);
          await Future<void>.delayed(Duration.zero);

          verify(
            () => logger.info(any(that: contains('Expect visible "text"'))),
          ).called(1);

          stepStateController.add([
            step1.copyWith(status: StepStatus.done),
            step2.copyWith(status: StepStatus.running),
            step3
          ]);
          await Future<void>.delayed(Duration.zero);

          verify(
            () => logger.info(any(that: contains('Expect not visible "text"'))),
          ).called(1);

          stepStateController.add([
            step1.copyWith(status: StepStatus.done),
            step2.copyWith(status: StepStatus.done),
            step3.copyWith(status: StepStatus.done),
          ]);
          await Future<void>.delayed(Duration.zero);

          await stepStateController.close();
          runCompleter.complete();
          expect(await future, equals(ExitCode.success.code));
        });
      });

      test('with a failure', () async {
        final command = TestCommand(
          logger: logger,
          processManager: processManager,
          driver: _driver(driver),
        )..testArgResults = argResults;

        await runWithMocks(() async {
          final future = command.run();

          final step1 = StepState('Expect visible "text"');
          final step2 = StepState('Expect not visible "text"');
          final step3 = StepState('Tap on "text"');

          stepStateController.add([step1, step2, step3]);
          await Future<void>.delayed(Duration.zero);

          stepStateController
              .add([step1.copyWith(status: StepStatus.running), step2, step3]);
          await Future<void>.delayed(Duration.zero);

          stepStateController.add([
            step1.copyWith(status: StepStatus.done),
            step2.copyWith(status: StepStatus.running),
            step3
          ]);
          await Future<void>.delayed(Duration.zero);

          verify(
            () => logger.info(any(that: contains('Expect not visible "text"'))),
          ).called(1);

          stepStateController.add([
            step1.copyWith(status: StepStatus.done),
            step2.copyWith(status: StepStatus.failed),
            step3
          ]);
          await Future<void>.delayed(Duration.zero);

          verify(
            () => logger.info(
              any(that: contains(red.wrap('Expect not visible "text"'))),
            ),
          ).called(1);

          await stepStateController.close();
          runCompleter.complete();
          expect(await future, equals(ExitCode.tempFail.code));
        });
      });
    });

    group('watch mode', () {
      setUp(() {
        final userFlow = _MockUserFlowYaml();
        when(() => userFlow.description).thenReturn('description');
        when(() => driver.userFlow).thenReturn(userFlow);

        when(() => argResults['watch']).thenReturn(true);

        when(() => stdin.listen(any())).thenAnswer((_) {
          return _MockStreamSubscription();
        });
      });

      test('throws exception if there is no terminal', () async {
        when(() => stdin.hasTerminal).thenReturn(false);

        final command = TestCommand(
          logger: logger,
          processManager: processManager,
          driver: _driver(driver),
        )..testArgResults = argResults;

        await runWithMocks(() async {
          final future = command.run();

          expect(await future, equals(ExitCode.usage.code));

          verify(
            () => logger.err(
              any(that: equals('Watch provided but no terminal was attached.')),
            ),
          ).called(1);
        });
      });

      test('trigger short cuts', () async {
        when(() => stdin.listen(any())).thenAnswer((invocation) {
          final onData = invocation.positionalArguments[0] as void Function(
            List<int> event,
          );
          onData(utf8.encode('r'));
          onData(utf8.encode('q'));

          return _MockStreamSubscription();
        });

        when(() => driver.run(watch: any(named: 'watch')))
            .thenAnswer((_) async {});
        when(driver.restart).thenAnswer((_) async {});
        when(driver.quit).thenAnswer((_) async {});

        final command = TestCommand(
          logger: logger,
          processManager: processManager,
          driver: _driver(driver),
        )..testArgResults = argResults;

        await runWithMocks(() async {
          final future = command.run();

          final step1 = StepState('Expect visible "text"');
          final step2 = StepState('Expect not visible "text"');
          final step3 = StepState('Tap on "text"');

          stepStateController.add([step1, step2, step3]);
          await Future<void>.delayed(Duration.zero);

          verify(
            () => logger.info(any(that: contains('restart'))),
          ).called(1);

          stepStateController.add([
            step1.copyWith(
              status: StepStatus.done,
              files: {
                'test_file': [1, 2, 3]
              },
            ),
            step2,
            step3
          ]);
          await Future<void>.delayed(Duration.zero);

          verify(
            () => testFile.createSync(
              recursive: any(named: 'recursive', that: isTrue),
            ),
          ).called(1);

          verify(
            () => testFile.writeAsBytesSync(any(that: equals([1, 2, 3]))),
          ).called(1);

          await stepStateController.close();
          runCompleter.complete();
          expect(await future, equals(ExitCode.tempFail.code));

          verify(driver.restart).called(1);
          verify(driver.quit).called(1);
        });
      });
    });
  });
}

FluttiumDriverCreator _driver(FluttiumDriver driver) {
  return ({
    required DriverConfiguration configuration,
    required Map<String, ActionLocation> actions,
    required Directory projectDirectory,
    required File userFlowFile,
    Logger? logger,
    ProcessManager? processManager,
  }) =>
      driver;
}
