import 'package:flutter_test/flutter_test.dart';
import 'package:fluttium/fluttium.dart';
import 'package:{{name.snakeCase()}}/{{name.snakeCase()}}.dart';
import 'package:mocktail/mocktail.dart';

class _MockRegister extends Mock implements Registry {}

void main() {
  test('can be registered', () {
    final registry = _MockRegister();
    when(
      () => registry.registerAction(
        any(),
        any(),
        shortHandIs: any(named: 'shortHandIs'),
      ),
    ).thenAnswer((_) {});

    register(registry);

    verify(
      () => registry.registerAction(
        any(that: equals('{{name.camelCase()}}')),
        any(that: equals({{name.pascalCase()}}.new)),
        shortHandIs: any(named: 'shortHandIs', that: equals(#text)),
      ),
    ).called(1);
  });
}
