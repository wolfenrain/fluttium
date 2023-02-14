import 'dart:io';

import 'package:fluttium_cli/src/command_runner.dart';
import 'package:fluttium_cli/src/version.dart';
import 'package:mason/mason.dart' hide packageVersion;
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as path;
import 'package:pub_updater/pub_updater.dart';
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

class _MockPubUpdater extends Mock implements PubUpdater {}

class _MockProgress extends Mock implements Progress {}

void main() {
  final cwd = Directory.current;

  group('init', () {
    late Logger logger;
    late PubUpdater pubUpdater;
    late FluttiumCommandRunner commandRunner;

    setUp(() {
      logger = _MockLogger();
      pubUpdater = _MockPubUpdater();

      when(() => logger.progress(any())).thenReturn(_MockProgress());
      when(
        () => pubUpdater.getLatestVersion(any()),
      ).thenAnswer((_) async => packageVersion);

      commandRunner = FluttiumCommandRunner(
        logger: logger,
        pubUpdater: pubUpdater,
      );
      setUpTestingEnvironment(cwd, suffix: '.init');
    });

    tearDown(() {
      Directory.current = cwd;
    });

    test(
      'help',
      withRunner((commandRunner, logger, printLogs, processManager) async {
        final result = await commandRunner.run(['init', '--help']);
        expect(printLogs, equals(expectedUsage));
        expect(result, equals(ExitCode.success.code));

        printLogs.clear();

        final resultAbbr = await commandRunner.run(['init', '-h']);
        expect(printLogs, equals(expectedUsage));
        expect(resultAbbr, equals(ExitCode.success.code));
      }),
    );

    test('exits with code 64 when fluttium.yaml already exists', () async {
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
    });

    test('initializes Fluttium when a fluttium.yaml does not exist', () async {
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
        () => logger.info('Run "fluttium new flow" to create your first flow.'),
      ).called(1);
    });
  });
}
