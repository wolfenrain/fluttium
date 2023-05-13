import 'dart:io';

import 'package:mason/mason.dart' hide packageVersion;
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import '../../../helpers/helpers.dart';

const expectedUsage = [
  // ignore: no_adjacent_strings_in_list
  'Create new actions and flows to use with Fluttium.\n'
      '\n'
      'Usage: fluttium new <subcommand> <name> [arguments]\n'
      '-h, --help    Print this usage information.\n'
      '\n'
      'Available subcommands:\n'
      '  action   Generate a new Fluttium action.\n'
      '  flow     Generate a new Fluttium flow file.\n'
      '\n'
      'Run "fluttium help" to see global options.'
];

class _MockLogger extends Mock implements Logger {}

class _MockProgress extends Mock implements Progress {}

void main() {
  final cwd = Directory.current;

  group('new', () {
    late Logger logger;
    late Progress generateProgress;

    setUp(() {
      logger = _MockLogger();
      generateProgress = _MockProgress();

      when(() => logger.progress(any())).thenReturn(generateProgress);

      setUpTestingEnvironment(cwd, suffix: '.new');
    });

    tearDown(() {
      Directory.current = cwd;
    });

    test(
      'help',
      withRunner((commandRunner, logger, printLogs, processManager) async {
        final result = await commandRunner.run(['new', '--help']);
        expect(printLogs, equals(expectedUsage));
        expect(result, equals(ExitCode.success.code));

        printLogs.clear();

        final resultAbbr = await commandRunner.run(['new', '-h']);
        expect(printLogs, equals(expectedUsage));
        expect(resultAbbr, equals(ExitCode.success.code));
      }),
    );

    test(
      'uses a custom directory output',
      withRunner(
        logger: () => logger,
        (commandRunner, logger, printLogs, processManager) async {
          final testDir = Directory(
            path.join(Directory.current.path, 'action'),
          )..createSync(recursive: true);
          Directory.current = testDir.path;

          final result = await commandRunner.run(
            ['new', 'action', 'my_action', '-o', 'test/fixtures/.new/action'],
          );
          expect(result, equals(ExitCode.success.code));
          final actual = Directory(
            path.join(testFixturesPath(cwd, suffix: '.new'), 'action'),
          );
          final expected = Directory(
            path.join(testFixturesPath(cwd, suffix: 'new'), 'action'),
          );
          expect(directoriesDeepEqual(actual, expected), isTrue);

          verify(
            () => logger.progress(
              any(
                that: equals(
                  'Generating a new action in "./test/fixtures/.new/action"',
                ),
              ),
            ),
          );
          verify(
            () => generateProgress.complete(
              any(
                that: equals(
                  'Generated a new action in "./test/fixtures/.new/action"',
                ),
              ),
            ),
          );
        },
      ),
    );

    test(
      'creates a new action',
      withRunner(
        logger: () => logger,
        (commandRunner, logger, printLogs, processManager) async {
          final testDir = Directory(
            path.join(Directory.current.path, 'action'),
          )..createSync(recursive: true);
          Directory.current = testDir.path;

          final result =
              await commandRunner.run(['new', 'action', 'my_action']);
          expect(result, equals(ExitCode.success.code));
          final actual = Directory(
            path.join(testFixturesPath(cwd, suffix: '.new'), 'action'),
          );
          final expected = Directory(
            path.join(testFixturesPath(cwd, suffix: 'new'), 'action'),
          );
          expect(directoriesDeepEqual(actual, expected), isTrue);

          verify(
            () => logger
                .progress(any(that: equals('Generating a new action in "."'))),
          );
          verify(
            () => generateProgress
                .complete(any(that: equals('Generated a new action in "."'))),
          );
        },
      ),
    );

    test(
      'creates a new flow',
      withRunner(
        logger: () => logger,
        (commandRunner, logger, printLogs, processManager) async {
          final testDir = Directory(
            path.join(Directory.current.path, 'flow'),
          )..createSync(recursive: true);
          Directory.current = testDir.path;

          final result = await commandRunner.run(['new', 'flow', 'my_flow']);
          expect(result, equals(ExitCode.success.code));
          final actual = Directory(
            path.join(testFixturesPath(cwd, suffix: '.new'), 'flow'),
          );
          final expected = Directory(
            path.join(testFixturesPath(cwd, suffix: 'new'), 'flow'),
          );
          expect(directoriesDeepEqual(actual, expected), isTrue);

          verify(
            () => logger
                .progress(any(that: equals('Generating a new flow in "."'))),
          );
          verify(
            () => generateProgress
                .complete(any(that: equals('Generated a new flow in "."'))),
          );
        },
      ),
    );
  });
}
