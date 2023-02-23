import 'package:args/args.dart';
import 'package:fluttium_cli/src/commands/new_command/new_bundle_command.dart';
import 'package:mason/mason.dart' hide packageVersion;
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockLogger extends Mock implements Logger {}

class _MockMasonGenerator extends Mock implements MasonGenerator {}

class _MockGeneratorHooks extends Mock implements GeneratorHooks {}

class _MockMasonBundle extends Mock implements MasonBundle {}

class _MockArgResults extends Mock implements ArgResults {}

class _MockProgress extends Mock implements Progress {}

class _FakeGeneratorTarget extends Fake implements GeneratorTarget {}

void main() {
  group('NewBundleCommand', () {
    setUp(() {
      registerFallbackValue(_FakeGeneratorTarget());
    });

    test('correct invocation', () {
      final bundle = _MockMasonBundle();
      when(() => bundle.name).thenReturn('fluttium_mock');
      when(() => bundle.vars).thenReturn({});

      final command = NewBundleCommand(
        logger: _MockLogger(),
        generatorFromBundle: (_) async => _MockMasonGenerator(),
        generatorFromBrick: (_) async => _MockMasonGenerator(),
        bundle: bundle,
      );

      expect(
        command.invocation,
        equals('fluttium new mock <name> [arguments]'),
      );
    });

    test('uses built-in bundle when retrieving fails', () async {
      final logger = _MockLogger();
      final generateProgress = _MockProgress();
      when(() => logger.progress(any())).thenReturn(generateProgress);

      final argsResult = _MockArgResults();
      when(() => argsResult.rest).thenReturn(['name']);

      final bundle = _MockMasonBundle();
      when(() => bundle.name).thenReturn('fluttium_mock');
      when(() => bundle.vars).thenReturn({});
      when(() => bundle.version).thenReturn('0.1.0');

      final generator = _MockMasonGenerator();
      final hooks = _MockGeneratorHooks();
      when(
        () => hooks.preGen(
          vars: any(named: 'vars'),
          onVarsChanged: any(named: 'onVarsChanged'),
        ),
      ).thenAnswer((_) async {});
      when(() => generator.hooks).thenReturn(hooks);
      when(
        () => generator.generate(
          any(),
          vars: any(named: 'vars'),
          logger: any(named: 'logger'),
        ),
      ).thenAnswer((_) async => []);

      final command = NewBundleCommand(
        logger: logger,
        generatorFromBundle: (_) async => generator,
        generatorFromBrick: (_) async => throw Exception(),
        bundle: bundle,
      )..argResultOverrides = argsResult;

      await command.run();

      verify(
        () => logger.detail(
          any(that: contains('Building generator from brick failed:')),
        ),
      );

      verify(
        () => logger.detail(
          any(that: contains('Building generator from bundle')),
        ),
      );

      expect(
        command.invocation,
        equals('fluttium new mock <name> [arguments]'),
      );
    });
  });
}
