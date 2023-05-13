import 'dart:io';

import 'package:mason/mason.dart' hide packageVersion;
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import '../../helpers/helpers.dart';

const expectedUsage = [
  // ignore: no_adjacent_strings_in_list
  'Initialize Fluttium in the current directory.\n'
      '\n'
      'Usage: fluttium init [arguments]\n'
      '-h, --help    Print this usage information.\n'
      '\n'
      'Run "fluttium help" to see global options.'
];

class _MockLogger extends Mock implements Logger {}

class _MockProgress extends Mock implements Progress {}

void main() {
  final cwd = Directory.current;

  group('init', () {
    late Logger logger;

    setUp(() {
      logger = _MockLogger();
      when(() => logger.progress(any())).thenReturn(_MockProgress());

      setUpTestingEnvironment(cwd, suffix: '.init');
    });

    tearDown(() {
      Directory.current = cwd;
    });

    test(
      'help',
      withRunner(
        (commandRunner, logger, processManager) async {
          final result = await commandRunner.run(['init', '--help']);
          expect(result, equals(ExitCode.success.code));

          final resultAbbr = await commandRunner.run(['init', '-h']);
          expect(resultAbbr, equals(ExitCode.success.code));
        },
        verifyPrints: (printLogs) {
          expect(printLogs, equals([...expectedUsage, ...expectedUsage]));
        },
      ),
    );

    test(
      'exits with code 64 when fluttium.yaml already exists',
      withRunner(
        logger: () => logger,
        (commandRunner, logger, processManager) async {
          final fluttiumYaml = File(
            path.join(Directory.current.path, 'fluttium.yaml'),
          );
          await fluttiumYaml.create(recursive: true);
          final result = await commandRunner.run(['init']);
          expect(result, equals(ExitCode.usage.code));
          verify(
            () => logger.err(
              '''There is already a "fluttium.yaml" in the current directory''',
            ),
          ).called(1);
        },
      ),
    );

    test(
      'initializes Fluttium when a fluttium.yaml does not exist',
      withRunner(
        logger: () => logger,
        (commandRunner, logger, processManager) async {
          final result = await commandRunner.run(['init']);
          expect(result, equals(ExitCode.success.code));
          final actual = Directory(
            path.join(testFixturesPath(cwd, suffix: '.init')),
          );
          final expected = Directory(
            path.join(testFixturesPath(cwd, suffix: 'init')),
          );
          expect(directoriesDeepEqual(actual, expected), isTrue);
          verify(() => logger.progress('Initializing')).called(1);
          verify(
            () => logger
                .info('Run "fluttium new flow" to create your first flow.'),
          ).called(1);
        },
      ),
    );
  });
}
