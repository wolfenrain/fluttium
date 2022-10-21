import 'package:bloc_test/bloc_test.dart';
import 'package:example/text/text.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TextCubit', () {
    test('initial state is empty', () {
      expect(TextCubit().state, equals(''));
    });

    blocTest<TextCubit, String>(
      'emits value when change is called',
      build: TextCubit.new,
      act: (cubit) => cubit.change('value'),
      expect: () => [equals('value')],
    );
  });
}
