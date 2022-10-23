import 'package:bloc_test/bloc_test.dart';
import 'package:example/progress/progress.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/helpers.dart';

class MockProgressCubit extends MockCubit<int> implements ProgressCubit {}

void main() {
  group('ProgressPage', () {
    testWidgets('renders ProgressView', (tester) async {
      await tester.pumpApp(const ProgressPage());
      expect(find.byType(ProgressView), findsOneWidget);
    });
  });

  group('ProgressView', () {
    late ProgressCubit progressCubit;

    setUp(() {
      progressCubit = MockProgressCubit();
    });

    testWidgets('renders start button when state is 0', (tester) async {
      when(() => progressCubit.state).thenReturn(0);
      await tester.pumpApp(
        BlocProvider.value(
          value: progressCubit,
          child: const ProgressView(),
        ),
      );

      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('starts progress when start button is pressed', (tester) async {
      when(() => progressCubit.state).thenReturn(0);
      when(() => progressCubit.start()).thenAnswer((_) async {});
      await tester.pumpApp(
        BlocProvider.value(
          value: progressCubit,
          child: const ProgressView(),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      verify(() => progressCubit.start()).called(1);
    });

    testWidgets('shows progress when set', (tester) async {
      when(() => progressCubit.state).thenReturn(50);
      await tester.pumpApp(
        BlocProvider.value(
          value: progressCubit,
          child: const ProgressView(),
        ),
      );

      expect(find.text('Progress: 50%'), findsOneWidget);
    });

    testWidgets('shows done when state is 100', (tester) async {
      when(() => progressCubit.state).thenReturn(100);
      await tester.pumpApp(
        BlocProvider.value(
          value: progressCubit,
          child: const ProgressView(),
        ),
      );

      expect(find.text('Done'), findsOneWidget);
    });
  });
}
