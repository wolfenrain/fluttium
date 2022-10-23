import 'package:bloc_test/bloc_test.dart';
import 'package:example/progress/cubit/text_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProgressCubit', () {
    test('initial state is 0', () {
      expect(ProgressCubit().state, equals(0));
    });

    blocTest<ProgressCubit, int>(
      'emits progress from 0 to 100',
      build: ProgressCubit.new,
      act: (cubit) => cubit.start(),
      expect: () => [for (var i = 0; i <= 100; i++) equals(i)],
    );
  });
}
