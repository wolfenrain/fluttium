import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:fluttium_cli/src/commands/commands.dart';
import 'package:fluttium_cli/src/flutter_device.dart';
import 'package:fluttium_driver/fluttium_driver.dart';
import 'package:fluttium_interfaces/fluttium_interfaces.dart';
import 'package:mason/mason.dart';
import 'package:mocktail/mocktail.dart';
import 'package:process/process.dart';
import 'package:test/test.dart';

import '../../helpers/helpers.dart';

const expectedUsage = [
  // ignore: no_adjacent_strings_in_list
  'Run a FluttiumFlow test.\n'
      '\n'
      'Usage: fluttium test <flow.yaml>\n'
      '-h, --help                       Print this usage information.\n'
      '-w, --[no-]watch                 Watch for file changes.\n'
      '''-d, --device-id                  Target device id or name (prefixes allowed).\n'''
      '''    --flavor                     Build a custom app flavor as defined by platform-specific build setup.\n'''
      '''                                 This will be passed to the --flavor option of flutter run.\n'''
      '''-t, --target                     The main entry-point file of the application, as run on the device.\n'''
      '                                 (defaults to "lib/main.dart")\n'
      '''    --dart-define=<key=value>    Pass additional key-value pairs to the flutter run.\n'''
      '''                                 Multiple defines can be passed by repeating "--dart-define" multiple times.\n'''
      '\n'
      'Run "fluttium help" to see global options.'
];

FluttiumDriverCreator _runner(FluttiumDriver runner) {
  return ({
    required DriverConfiguration configuration,
    required Map<String, ActionLocation> actions,
    required Directory projectDirectory,
    required File userFlowFile,
    Logger? logger,
    ProcessManager? processManager,
  }) =>
      runner;
}

class _FakeLogger extends Fake implements Logger {}

class _MockArgResults extends Mock implements ArgResults {}

class _MockLogger extends Mock implements Logger {}

class _MockProgress extends Mock implements Progress {}

class _MockFluttiumDriver extends Mock implements FluttiumDriver {}

class _MockFile extends Mock implements File {}

class _MockDirectory extends Mock implements Directory {}

class _MockProcessManager extends Mock implements ProcessManager {}

class _MockProcessResult extends Mock implements ProcessResult {}

class _MockStdin extends Mock implements Stdin {}

class _MockUserFlowYaml extends Mock implements UserFlowYaml {}

class _MockStreamSubscription<T> extends Mock
    implements StreamSubscription<T> {}

void main() {
  group('test', () {
    late List<String> progressLogs;
    late Logger logger;
    late Progress progress;
    late ProcessManager processManager;
    late ProcessResult flutterDevicesResult;
    late Directory projectDirectory;
    late File flowFile;
    late File targetFile;
    late Directory platformDirectory;
    late Stdin stdin;
    late ArgResults argResults;

    setUpAll(() {
      registerFallbackValue(_FakeLogger());
    });

    setUp(() {
      argResults = _MockArgResults();
      when(() => argResults.arguments).thenReturn(['test_flow.yaml']);
      when(() => argResults['watch']).thenReturn(false);
      when(() => argResults['target']).thenReturn('lib/main.dart');
      when(() => argResults['dart-define']).thenReturn(<String>[]);

      progressLogs = <String>[];

      logger = _MockLogger();
      progress = _MockProgress();
      when(() => progress.complete(any())).thenAnswer((_) {
        if (_.positionalArguments.isEmpty) {
          return;
        }
        if (_.positionalArguments[0] != null) {
          progressLogs.add(_.positionalArguments[0] as String);
        }
      });
      when(() => logger.progress(any())).thenReturn(progress);

      processManager = _MockProcessManager();
      flutterDevicesResult = _MockProcessResult();
      when(() => flutterDevicesResult.stdout).thenReturn(
        json.encode([
          {
            'name': 'macOS',
            'id': 'macos',
            'isSupported': true,
            'targetPlatform': 'darwin',
          }
        ]),
      );

      when(
        () => processManager.run(
          any(
            that: equals(
              [
                'flutter',
                '--no-version-check',
                'devices',
                '--machine',
              ],
            ),
          ),
          runInShell: any(named: 'runInShell'),
          workingDirectory: any(named: 'workingDirectory'),
        ),
      ).thenAnswer((invocation) async => flutterDevicesResult);

      final pubspecFile = _MockFile();
      when(() => pubspecFile.path).thenReturn('pubspec.yaml');
      projectDirectory = _MockDirectory();
      when(projectDirectory.listSync).thenReturn([pubspecFile]);
      when(() => projectDirectory.absolute).thenReturn(projectDirectory);
      when(() => projectDirectory.path).thenReturn('project');

      flowFile = _MockFile();
      when(flowFile.existsSync).thenReturn(true);
      when(() => flowFile.parent).thenReturn(projectDirectory);
      when(() => flowFile.path).thenReturn('project/test_flow.yaml');

      targetFile = _MockFile();
      when(targetFile.existsSync).thenReturn(true);
      when(() => targetFile.path).thenReturn('project/lib/main.dart');

      platformDirectory = _MockDirectory();
      when(platformDirectory.existsSync).thenReturn(true);

      stdin = _MockStdin();
    });

    test(
      'help',
      withRunner((commandRunner, logger, printLogs, processManager) async {
        final result = await commandRunner.run(['test', '--help']);
        expect(printLogs, equals(expectedUsage));
        expect(result, equals(ExitCode.success.code));

        printLogs.clear();

        final resultAbbr = await commandRunner.run(['test', '-h']);
        expect(printLogs, equals(expectedUsage));
        expect(resultAbbr, equals(ExitCode.success.code));
      }),
    );

    test('completes running the fluttium runner', () async {
      final driver = _MockFluttiumDriver();
      when(driver.run).thenAnswer((invocation) async {});

      final command = TestCommand(
        logger: logger,
        processManager: processManager,
        driver: _runner(driver),
      )..testArgResults = argResults;

      await IOOverrides.runZoned(
        () async {
          final result = await command.run();
          expect(result, equals(ExitCode.success.code));
        },
        createFile: (path) => path.endsWith('.dart') ? targetFile : flowFile,
        createDirectory: (path) {
          if (path.endsWith('macos')) {
            return platformDirectory;
          }
          return projectDirectory;
        },
      );
    });

    test('bubbles up until it fits a pubspec', () async {
      final driver = _MockFluttiumDriver();
      when(driver.run).thenAnswer((invocation) async {});

      final childDirectory = _MockDirectory();
      when(childDirectory.listSync).thenReturn([]);
      when(() => childDirectory.absolute).thenReturn(childDirectory);
      when(() => childDirectory.parent).thenReturn(projectDirectory);

      when(() => flowFile.parent).thenReturn(childDirectory);

      final command = TestCommand(
        logger: logger,
        processManager: processManager,
        driver: _runner(driver),
      )..testArgResults = argResults;

      await IOOverrides.runZoned(
        () async {
          final result = await command.run();
          expect(result, equals(ExitCode.success.code));
        },
        createFile: (path) => path.endsWith('.dart') ? targetFile : flowFile,
        createDirectory: (path) {
          if (path.endsWith('macos')) {
            return platformDirectory;
          }
          return childDirectory;
        },
      );
    });

    group('exits early', () {
      test(
        'if no flow file is given',
        withRunner((commandRunner, logger, printLogs, processManager) async {
          final result = await commandRunner.run(['test']);

          expect(result, equals(ExitCode.usage.code));
        }),
      );

      test('if the given flow file does not exists', () async {
        final driver = _MockFluttiumDriver();
        when(driver.run).thenAnswer((invocation) async {});

        when(flowFile.existsSync).thenReturn(false);

        final command = TestCommand(
          logger: logger,
          processManager: processManager,
          driver: _runner(driver),
        )..testArgResults = argResults;

        await IOOverrides.runZoned(
          () async {
            final result = await command.run();
            expect(result, equals(ExitCode.unavailable.code));

            verify(
              () => logger.err(
                any(
                  that: equals('Flow file "project/test_flow.yaml" not found.'),
                ),
              ),
            ).called(1);
          },
          createFile: (path) => path.endsWith('.dart') ? targetFile : flowFile,
          createDirectory: (path) {
            if (path.endsWith('macos')) {
              return platformDirectory;
            }
            return projectDirectory;
          },
        );
      });

      test('if no pubspec was found in parent directories', () async {
        final driver = _MockFluttiumDriver();
        when(driver.run).thenAnswer((invocation) async {});

        when(() => projectDirectory.listSync()).thenReturn([]);
        when(() => projectDirectory.parent).thenReturn(projectDirectory);

        final command = TestCommand(
          logger: logger,
          processManager: processManager,
          driver: _runner(driver),
        )..testArgResults = argResults;

        await IOOverrides.runZoned(
          () async {
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
          },
          createFile: (path) => path.endsWith('.dart') ? targetFile : flowFile,
          createDirectory: (path) {
            if (path.endsWith('macos')) {
              return platformDirectory;
            }
            return projectDirectory;
          },
        );
      });

      test('if the target file does not exist', () async {
        final driver = _MockFluttiumDriver();
        when(driver.run).thenAnswer((invocation) async {});

        when(targetFile.existsSync).thenReturn(false);

        final command = TestCommand(
          logger: logger,
          processManager: processManager,
          driver: _runner(driver),
        )..testArgResults = argResults;

        await IOOverrides.runZoned(
          () async {
            final result = await command.run();
            expect(result, equals(ExitCode.unavailable.code));

            verify(
              () => logger.err(
                any(
                  that: equals('Target file "lib/main.dart" not found.'),
                ),
              ),
            ).called(1);
          },
          createFile: (path) => path.endsWith('.dart') ? targetFile : flowFile,
          createDirectory: (path) {
            if (path.endsWith('macos')) {
              return platformDirectory;
            }
            return projectDirectory;
          },
        );
      });
    });

    test('validates all platforms', () async {
      final driver = _MockFluttiumDriver();
      when(driver.run).thenAnswer((invocation) async {});

      for (final platform in [
        const MapEntry('web', 'web'),
        const MapEntry('macos', 'darwin'),
        const MapEntry('android', 'android'),
        const MapEntry('ios', 'ios'),
        const MapEntry('windows', 'windows'),
        const MapEntry('linux', 'linux'),
      ]) {
        when(() => flutterDevicesResult.stdout).thenReturn(
          json.encode([
            {
              'name': platform.value,
              'id': platform.value,
              'isSupported': true,
              'targetPlatform': platform.value,
            }
          ]),
        );

        final command = TestCommand(
          logger: logger,
          processManager: processManager,
          driver: _runner(driver),
        )..testArgResults = argResults;

        await IOOverrides.runZoned(
          () async {
            final result = await command.run();

            verify(
              () => logger.progress(any(that: equals('Retrieving devices'))),
            ).called(1);
            verify(() => progress.complete()).called(1);
            verifyNever(() => progress.cancel());
            verifyNever(
              () => logger.chooseOne<FlutterDevice>(
                any(that: equals('Choose a device:')),
                choices: any(named: 'choices'),
                display: any(named: 'display'),
              ),
            );

            expect(result, equals(ExitCode.success.code));
          },
          createFile: (path) => path.endsWith('.dart') ? targetFile : flowFile,
          createDirectory: (path) {
            if (path.endsWith(platform.key)) {
              return platformDirectory;
            }
            return projectDirectory;
          },
        );
      }
    });

    group('retrieving device data', () {
      test('run on specified device', () async {
        when(() => argResults['device-id']).thenReturn('macos');

        final driver = _MockFluttiumDriver();
        when(driver.run).thenAnswer((invocation) async {});

        when(() => flutterDevicesResult.stdout).thenReturn(
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
        );

        final command = TestCommand(
          logger: logger,
          processManager: processManager,
          driver: _runner(driver),
        )..testArgResults = argResults;

        await IOOverrides.runZoned(
          () async {
            final result = await command.run();
            expect(result, equals(ExitCode.success.code));

            verify(
              () => logger.progress(any(that: equals('Retrieving devices'))),
            ).called(1);
            verify(() => progress.complete()).called(1);
            verifyNever(() => progress.cancel());
            verifyNever(
              () => logger.chooseOne<FlutterDevice>(
                any(that: equals('Choose a device:')),
                choices: any(named: 'choices'),
                display: any(named: 'display'),
              ),
            );
          },
          createFile: (path) => path.endsWith('.dart') ? targetFile : flowFile,
          createDirectory: (path) {
            if (path.endsWith('macos') || path.endsWith('ios')) {
              return platformDirectory;
            }
            return projectDirectory;
          },
        );
      });

      test('prompts user which device to run on', () async {
        final driver = _MockFluttiumDriver();
        when(driver.run).thenAnswer((invocation) async {});

        when(() => flutterDevicesResult.stdout).thenReturn(
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
        );

        final command = TestCommand(
          logger: logger,
          processManager: processManager,
          driver: _runner(driver),
        )..testArgResults = argResults;

        await IOOverrides.runZoned(
          () async {
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

            final result = await command.run();
            expect(result, equals(ExitCode.success.code));

            verify(
              () => logger.progress(any(that: equals('Retrieving devices'))),
            ).called(1);
            verify(() => progress.cancel()).called(1);
            verifyNever(() => progress.complete());
            verifyNever(() => progress.fail());
            verify(
              () => logger.chooseOne<FlutterDevice>(
                any(that: equals('Choose a device:')),
                choices: any(named: 'choices'),
                display: any(named: 'display'),
              ),
            ).called(1);
          },
          createFile: (path) => path.endsWith('.dart') ? targetFile : flowFile,
          createDirectory: (path) {
            if (path.endsWith('macos') || path.endsWith('ios')) {
              return platformDirectory;
            }
            return projectDirectory;
          },
        );
      });

      test('exits early if no devices are found', () async {
        final driver = _MockFluttiumDriver();
        when(driver.run).thenAnswer((invocation) async {});

        when(() => flutterDevicesResult.stdout).thenReturn(
          json.encode([]),
        );

        final command = TestCommand(
          logger: logger,
          processManager: processManager,
          driver: _runner(driver),
        )..testArgResults = argResults;

        await IOOverrides.runZoned(
          () async {
            final result = await command.run();
            expect(result, equals(ExitCode.unavailable.code));

            verify(
              () => logger.progress(any(that: equals('Retrieving devices'))),
            ).called(1);
            verifyNever(() => progress.complete());
            verify(() => progress.fail()).called(1);
            verifyNever(() => progress.cancel());
            verifyNever(
              () => logger.chooseOne<FlutterDevice>(
                any(that: equals('Choose a device:')),
                choices: any(named: 'choices'),
                display: any(named: 'display'),
              ),
            );

            verify(
              () => logger.err(any(that: equals('No devices found.'))),
            ).called(1);
          },
          createFile: (path) => path.endsWith('.dart') ? targetFile : flowFile,
          createDirectory: (path) {
            if (path.endsWith('macos')) {
              return platformDirectory;
            }
            return projectDirectory;
          },
        );
      });
    });

    test('renders as expected for all steps', () async {
      final driver = _MockFluttiumDriver();
      when(driver.run).thenAnswer((invocation) async {});

      final userFlow = _MockUserFlowYaml();
      when(() => userFlow.description).thenReturn('description');
      when(() => driver.userFlow).thenReturn(userFlow);

      final stepsController = StreamController<List<StepState>>();
      when(() => driver.steps).thenAnswer((_) => stepsController.stream);

      final command = TestCommand(
        logger: logger,
        processManager: processManager,
        driver: _runner(driver),
      )..testArgResults = argResults;

      await IOOverrides.runZoned(
        () async {
          final future = command.run();

          final step1 = StepState('Expect visible "text"');
          final step2 = StepState('Expect not visible "text"');
          final step3 = StepState('Tap on "text"');

          stepsController.add([step1, step2, step3]);

          verify(() => logger.info('  🔲  Expect visible "text"')).called(1);
          verify(() => logger.info('  🔲  Expect not visible "text"'))
              .called(1);
          verify(() => logger.info('  🔲  Tap on "text"')).called(1);

          stepsController
              .add([step1.copyWith(status: StepStatus.running), step2]);
          verify(() => logger.info('  ✅  Expect visible "text"')).called(1);
          verify(() => logger.info('  ⏳  Expect not visible "text"')).called(1);
          verify(() => logger.info('  🔲  Tap on "text"')).called(1);

          stepsController.add([
            step1.copyWith(status: StepStatus.done),
            step2.copyWith(status: StepStatus.failed),
            step3,
          ]);

          verify(() => logger.info('  ✅  Expect visible "text"')).called(1);
          verify(() => logger.info('  ❌  Expect not visible "text"')).called(1);
          verify(() => logger.info('  🔲  Tap on "text"')).called(1);

          verify(
            () => logger.info(any(that: contains('description'))),
          ).called(3);

          expect(await future, equals(ExitCode.success.code));
        },
        createFile: (path) => path.endsWith('.dart') ? targetFile : flowFile,
        createDirectory: (path) {
          if (path.endsWith('macos')) {
            return platformDirectory;
          }
          return projectDirectory;
        },
      );
    });

    group('watch mode', () {
      setUp(() {
        when(() => argResults['watch']).thenReturn(true);

        when(() => stdin.listen(any())).thenAnswer((invocation) {
          return _MockStreamSubscription();
        });
      });

      // test('trigger short cuts', () async {
      //   when(() => stdin.listen(any())).thenAnswer((invocation) {
      //     final onData = invocation.positionalArguments[0] as void Function(
      //       List<int> event,
      //     );
      //     onData(utf8.encode('r'));
      //     onData(utf8.encode('q'));

      //     return _MockStreamSubscription();
      //   });

      //   final driver = _MockFluttiumDriver();
      //   when(() => driver.run(watch: any(named: 'watch')))
      //       .thenAnswer((invocation) async {});
      //   when(driver.restart).thenAnswer((invocation) async {});
      //   when(driver.quit).thenAnswer((invocation) async {});

      //   final command = TestCommand(
      //     logger: logger,
      //     processManager: processManager,
      //     driver: _runner(driver),
      //     driver: ({
      //       required DriverConfiguration configuration,
      //       required Map<String, ActionLocation> actions,
      //       required Directory projectDirectory,
      //       required File userFlowFile,
      //       Logger? logger,
      //       ProcessManager? processManager,
      //     }) {
      //       final flow = _MockUserFlowYaml();
      //       when(() => flow.description).thenReturn('description');
      //       when(() => flow.steps).thenReturn([]);

      //       renderer(flow, []);

      //       verify(
      //         () => logger!.info(
      //           any(that: contains('restart')),
      //         ),
      //       ).called(1);

      //       return driver;
      //     },
      //   )..testArgResults = argResults;

      //   await IOOverrides.runZoned(
      //     () async {
      //       final result = await command.run();
      //       expect(result, equals(ExitCode.success.code));

      //       verify(driver.restart).called(1);
      //       verify(driver.quit).called(1);
      //     },
      //     createFile: (path) => path.endsWith('.dart') ? targetFile : flowFile,
      //     createDirectory: (path) {
      //       if (path.endsWith('macos')) {
      //         return platformDirectory;
      //       }
      //       return projectDirectory;
      //     },
      //     stdin: () => stdin,
      //   );
      // });

      // test('renders with short cuts', () async {
      //   final driver = _MockFluttiumDriver();
      //   when(() => driver.run(watch: any(named: 'watch')))
      //       .thenAnswer((invocation) async {});

      //   final command = TestCommand(
      //     logger: logger,
      //     processManager: processManager,
      //     driver: ({
      //       required File flowFile,
      //       required Directory projectDirectory,
      //       required String deviceId,
      //       required fluttium.FlowRenderer renderer,
      //       required File mainEntry,
      //       String? flavor,
      //       List<String> dartDefines = const [],
      //       Logger? logger,
      //       ProcessManager? processManager,
      //     }) {
      //       final flow = _MockUserFlowYaml();
      //       when(() => flow.description).thenReturn('description');
      //       when(() => flow.steps).thenReturn([]);

      //       renderer(flow, []);

      //       verify(
      //         () => logger!.info(
      //           any(that: contains('restart')),
      //         ),
      //       ).called(1);

      //       return driver;
      //     },
      //   )..testArgResults = argResults;

      //   await IOOverrides.runZoned(
      //     () async {
      //       final result = await command.run();
      //       expect(result, equals(ExitCode.success.code));
      //     },
      //     createFile: (path) => path.endsWith('.dart') ? targetFile : flowFile,
      //     createDirectory: (path) {
      //       if (path.endsWith('macos')) {
      //         return platformDirectory;
      //       }
      //       return projectDirectory;
      //     },
      //     stdin: () => stdin,
      //   );
      // });
    });
  });
}
