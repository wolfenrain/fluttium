import 'package:bloc_test/bloc_test.dart';
import 'package:example/drawer/drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/helpers.dart';

class _MockDrawerCubit extends MockCubit<String> implements DrawerCubit {}

void main() {
  group('DrawerPage', () {
    testWidgets('renders DrawerView', (tester) async {
      await tester.pumpApp(const DrawerPage());
      expect(find.byType(DrawerView), findsOneWidget);
    });
  });

  group('DrawerView', () {
    late DrawerCubit drawerCubit;

    setUp(() {
      drawerCubit = _MockDrawerCubit();
    });

    testWidgets('renders current value', (tester) async {
      const state = 'Value';
      when(() => drawerCubit.state).thenReturn(state);
      await tester.pumpApp(
        BlocProvider.value(
          value: drawerCubit,
          child: const DrawerView(),
        ),
      );

      expect(find.text('Clicked: $state'), findsOneWidget);
    });

    testWidgets('opens drawer when button is pressed', (tester) async {
      when(() => drawerCubit.state).thenReturn('None');
      await tester.pumpApp(
        BlocProvider.value(
          value: drawerCubit,
          child: const DrawerView(),
        ),
      );
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      expect(find.byType(Drawer), findsOneWidget);
      expect(find.text('Value 1'), findsOneWidget);
      expect(find.text('Value 2'), findsOneWidget);
      expect(find.text('Value 3'), findsOneWidget);
    });

    group('change value to one in the drawer', () {
      for (final value in ['Value 1', 'Value 2', 'Value 3']) {
        testWidgets(value, (tester) async {
          when(() => drawerCubit.state).thenReturn('None');
          await tester.pumpApp(
            BlocProvider.value(
              value: drawerCubit,
              child: const DrawerView(),
            ),
          );
          await tester.tap(find.byIcon(Icons.menu));
          await tester.pumpAndSettle();

          expect(find.text(value), findsOneWidget);
          await tester.tap(find.text(value));
          await tester.pumpAndSettle();

          verify(() => drawerCubit.change(any(that: equals(value)))).called(1);
        });
      }
    });
  });
}
