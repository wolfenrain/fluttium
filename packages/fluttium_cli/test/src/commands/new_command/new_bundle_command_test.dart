import 'package:fluttium_cli/src/commands/new_command/new_bundle_command.dart';
import 'package:mason/mason.dart' hide packageVersion;
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockLogger extends Mock implements Logger {}

class _MockMasonGenerator extends Mock implements MasonGenerator {}

class _MockMasonBundle extends Mock implements MasonBundle {}

void main() {
  group('NewBundleCommand', () {
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
  });
}
