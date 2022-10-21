import 'package:bloc_test/bloc_test.dart';
import 'package:example/text/text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/helpers.dart';

class MockTextCubit extends MockCubit<String> implements TextCubit {}

void main() {
  group('TextPage', () {
    testWidgets('renders TextView', (tester) async {
      await tester.pumpApp(const TextPage());
      expect(find.byType(TextView), findsOneWidget);
    });
  });

  group('TextView', () {
    late TextCubit textCubit;

    setUp(() {
      textCubit = MockTextCubit();
    });

    testWidgets('renders current value', (tester) async {
      const state = 'value';
      when(() => textCubit.state).thenReturn(state);
      await tester.pumpApp(
        BlocProvider.value(
          value: textCubit,
          child: const TextView(),
        ),
      );
      expect(find.text('Result: $state'), findsOneWidget);
    });

    testWidgets('calls change when text field changes', (tester) async {
      when(() => textCubit.state).thenReturn('');
      await tester.pumpApp(
        BlocProvider.value(
          value: textCubit,
          child: const TextView(),
        ),
      );

      await tester.enterText(find.byType(TextField), 'value');
      verify(() => textCubit.change(any(that: equals('value')))).called(1);
    });
  });
}
