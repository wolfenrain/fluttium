import 'package:bloc_test/bloc_test.dart';
import 'package:example/drawer/drawer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DrawerCubit', () {
    test('initial state is None', () {
      expect(DrawerCubit().state, equals('None'));
    });

    blocTest<DrawerCubit, String>(
      'emits value when change is called',
      build: DrawerCubit.new,
      act: (cubit) => cubit.change('value'),
      expect: () => [equals('value')],
    );
  });
}
