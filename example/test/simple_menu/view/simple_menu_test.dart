import 'package:bloc_test/bloc_test.dart';
import 'package:example/counter/counter.dart';
import 'package:example/simple_menu/simple_menu.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/helpers.dart';

class MockCounterCubit extends MockCubit<int> implements CounterCubit {}

void main() {
  group('SimpleMenuPage', () {
    testWidgets('renders SimpleMenuPage', (tester) async {
      await tester.pumpApp(const SimpleMenuPage());
      expect(find.byType(SimpleMenuPage), findsOneWidget);
    });

    testWidgets('renders "Show Menu"', (tester) async {
      await tester.pumpApp(const SimpleMenuPage());
      expect(find.text('Show Menu'), findsOneWidget);
    });

    testWidgets('shows simple menu', (tester) async {
      await tester.pumpApp(const SimpleMenuPage());
      await tester.longPress(find.text('Show Menu'));

      expect(find.text('Menu Item 1'), findsOneWidget);
    });
  });
}
