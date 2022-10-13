import 'dart:io';

import 'package:args/args.dart';
import 'package:fluttium_cli/src/commands/commands.dart';
import 'package:fluttium_flow/fluttium_flow.dart';
import 'package:mason/mason.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../helpers/helpers.dart';

const expectedUsage = [
  // ignore: no_adjacent_strings_in_list
  'Create a FluttiumFlow test.\n'
      '\n'
      'Usage: fluttium create <output.yaml>\n'
      '-h, --help    Print this usage information.\n'
      '-d, --desc    The description of the flow test.\n'
      '\n'
      'Run "fluttium help" to see global options.'
];

class _FakeDirectoryGeneratorTarget extends Fake
    implements DirectoryGeneratorTarget {}

class _FakeLogger extends Fake implements Logger {}

class _MockArgResults extends Mock implements ArgResults {}

class _MockLogger extends Mock implements Logger {}

class _MockMasonGenerator extends Mock implements MasonGenerator {}

class _MockFile extends Mock implements File {}

void main() {
  group('create', () {
    late Logger logger;

    setUpAll(() {
      registerFallbackValue(_FakeDirectoryGeneratorTarget());
      registerFallbackValue(_FakeLogger());
    });

    setUp(() {
      logger = _MockLogger();
    });

    test(
      'help',
      withRunner((commandRunner, logger, printLogs, processManager) async {
        final result = await commandRunner.run(['create', '--help']);
        expect(printLogs, equals(expectedUsage));
        expect(result, equals(ExitCode.success.code));

        printLogs.clear();

        final resultAbbr = await commandRunner.run(['create', '-h']);
        expect(printLogs, equals(expectedUsage));
        expect(resultAbbr, equals(ExitCode.success.code));
      }),
    );

    test('completes successfully with correct output', () async {
      final argResults = _MockArgResults();
      when(() => argResults.arguments).thenReturn(['test_flow.yaml']);
      when(() => argResults['desc']).thenReturn(null);

      final generator = _MockMasonGenerator();
      when(
        () => generator.generate(
          any(),
          vars: any(named: 'vars'),
          logger: any(named: 'logger'),
          fileConflictResolution: any(named: 'fileConflictResolution'),
        ),
      ).thenAnswer(
        (_) async => [const GeneratedFile.created(path: 'test.yaml')],
      );

      final command = CreateCommand(
        logger: logger,
        generator: (_) async => generator,
      )..testArgResults = argResults;

      when(
        () => logger.prompt(any(that: equals('Description:'))),
      ).thenReturn('test description');

      var firstAction = true;
      when(
        () => logger.prompt(
          any(that: equals('What is the search value (q to exit):')),
        ),
      ).thenAnswer((invocation) {
        if (firstAction) {
          firstAction = false;
          return 'some search value';
        }
        return 'q';
      });

      when(
        () => logger.chooseOne<FluttiumAction>(
          any(that: equals('What action should be executed?')),
          choices: any(named: 'choices'),
          display: any(named: 'display'),
        ),
      ).thenAnswer(
        (invocation) {
          expect(
            invocation.namedArguments[#display]!(FluttiumAction.expectVisible),
            equals('expectVisible'),
          );
          return FluttiumAction.expectVisible;
        },
      );

      final result = await command.run();
      expect(result, equals(ExitCode.success.code));

      verify(() => logger.prompt(any(that: equals('Description:')))).called(1);
      verify(
        () => logger.prompt(
          any(that: equals('What is the search value (q to exit):')),
        ),
      ).called(2);

      verify(
        () => logger.chooseOne<FluttiumAction>(
          any(that: equals('What action should be executed?')),
          choices: any(named: 'choices'),
          display: any(named: 'display'),
        ),
      ).called(2);

      verify(
        () => generator.generate(
          any(that: isA<DirectoryGeneratorTarget>()),
          vars: any(
            named: 'vars',
            that: equals(
              {
                'name': 'test_flow',
                'description': 'test description',
                'steps': [
                  {'action': 'expectVisible', 'text': 'some search value'}
                ]
              },
            ),
          ),
          logger: any(named: 'logger', that: equals(logger)),
          fileConflictResolution: any(
            named: 'fileConflictResolution',
            that: equals(FileConflictResolution.prompt),
          ),
        ),
      ).called(1);
    });

    test('completes successfully without prompting for description', () async {
      final argResults = _MockArgResults();
      when(() => argResults.arguments).thenReturn(['test_flow.yaml']);
      when(() => argResults['desc']).thenReturn('test description');

      final generator = _MockMasonGenerator();
      when(
        () => generator.generate(
          any(),
          vars: any(named: 'vars'),
          logger: any(named: 'logger'),
          fileConflictResolution: any(named: 'fileConflictResolution'),
        ),
      ).thenAnswer(
        (_) async => [const GeneratedFile.created(path: 'test.yaml')],
      );

      final command = CreateCommand(
        logger: logger,
        generator: (_) async => generator,
      )..testArgResults = argResults;

      var firstAction = true;
      when(
        () => logger.prompt(
          any(that: equals('What is the search value (q to exit):')),
        ),
      ).thenAnswer((invocation) {
        if (firstAction) {
          firstAction = false;
          return 'some search value';
        }
        return 'q';
      });

      when(
        () => logger.chooseOne<FluttiumAction>(
          any(that: equals('What action should be executed?')),
          choices: any(named: 'choices'),
          display: any(named: 'display'),
        ),
      ).thenReturn(FluttiumAction.expectVisible);

      final result = await command.run();
      expect(result, equals(ExitCode.success.code));

      verifyNever(() => logger.prompt(any(that: equals('Description:'))));
      verify(
        () => logger.info(any(that: contains('test description'))),
      ).called(1);

      verify(
        () => logger.prompt(
          any(that: equals('What is the search value (q to exit):')),
        ),
      ).called(2);

      verify(
        () => logger.chooseOne<FluttiumAction>(
          any(that: equals('What action should be executed?')),
          choices: any(named: 'choices'),
          display: any(named: 'display'),
        ),
      ).called(2);

      verify(
        () => generator.generate(
          any(that: isA<DirectoryGeneratorTarget>()),
          vars: any(
            named: 'vars',
            that: equals(
              {
                'name': 'test_flow',
                'description': 'test description',
                'steps': [
                  {'action': 'expectVisible', 'text': 'some search value'}
                ]
              },
            ),
          ),
          logger: any(named: 'logger', that: equals(logger)),
          fileConflictResolution: any(
            named: 'fileConflictResolution',
            that: equals(FileConflictResolution.prompt),
          ),
        ),
      ).called(1);
    });

    test('prompts if file exists and does not overwrite', () async {
      final outputFile = _MockFile();
      when(outputFile.existsSync).thenReturn(true);

      final argResults = _MockArgResults();
      when(() => argResults.arguments).thenReturn(['test_flow.yaml']);

      final command = CreateCommand(
        logger: logger,
        generator: (_) async => _MockMasonGenerator(),
      )..testArgResults = argResults;

      when(
        () => logger.confirm(
          any(that: equals('File already exists. Overwrite?')),
        ),
      ).thenReturn(false);

      await IOOverrides.runZoned(
        () async {
          final result = await command.run();
          expect(result, equals(ExitCode.cantCreate.code));

          verify(
            () => logger.confirm(
              any(that: equals('File already exists. Overwrite?')),
            ),
          ).called(1);

          verify(() => logger.err(any(that: equals('Aborting.')))).called(1);

          verifyNever(() => logger.prompt(any(that: equals('Description:'))));
          verifyNever(
            () => logger.prompt(
              any(that: equals('What is the search value (q to exit):')),
            ),
          );
          verifyNever(
            () => logger.chooseOne<FluttiumAction>(
              any(that: equals('What action should be executed?')),
              choices: any(named: 'choices'),
              display: any(named: 'display'),
            ),
          );
        },
        createFile: (path) => outputFile,
      );
    });

    test(
      'shows usage if file already exists',
      withRunner((commandRunner, logger, printLogs, processManager) async {
        final file = _MockFile();
        when(file.existsSync).thenReturn(false);

        await IOOverrides.runZoned(
          () async {
            final result = await commandRunner.run(['create xx']);

            expect(result, equals(ExitCode.usage.code));
          },
          createFile: (path) => file,
        );
      }),
    );

    test(
      'shows usage if no output file specified',
      withRunner((commandRunner, logger, printLogs, processManager) async {
        final result = await commandRunner.run(['create']);

        expect(result, equals(ExitCode.usage.code));
      }),
    );
  });
}
