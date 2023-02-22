import 'package:flutter_test/flutter_test.dart';
import 'package:fluttium/fluttium.dart';
import 'package:my_action/my_action.dart';
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
        any(that: equals('myAction')),
        any(that: equals(MyAction.new)),
        shortHandIs: any(named: 'shortHandIs', that: equals(#text)),
      ),
    ).called(1);
  });
}
