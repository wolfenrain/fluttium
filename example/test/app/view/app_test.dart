import 'package:example/app/app.dart';
import 'package:example/complex_text/complex_text.dart';
import 'package:example/counter/counter.dart';
import 'package:example/drawer/drawer.dart';
import 'package:example/progress/progress.dart';
import 'package:example/scrollable_list/view/scrollable_list.dart';
import 'package:example/simple_menu/simple_menu.dart';
import 'package:example/text/text.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('$App', () {
    testWidgets('renders $AppView', (tester) async {
      await tester.pumpWidget(const App(environment: 'Testing'));
      expect(find.byType(AppView), findsOneWidget);
    });

    testWidgets('navigates to $CounterPage when Counter button is tapped',
        (tester) async {
      await tester.pumpWidget(const App(environment: 'Testing'));
      await tester.tap(find.text('Counter'));
      await tester.pumpAndSettle();

      expect(find.byType(CounterPage), findsOneWidget);
    });

    testWidgets('navigates to $DrawerPage when Drawer button is tapped',
        (tester) async {
      await tester.pumpWidget(const App(environment: 'Testing'));
      await tester.tap(find.text('Drawer'));
      await tester.pumpAndSettle();

      expect(find.byType(DrawerPage), findsOneWidget);
    });

    testWidgets('navigates to $TextPage when Text button is tapped',
        (tester) async {
      await tester.pumpWidget(const App(environment: 'Testing'));
      await tester.tap(find.text('Text'));
      await tester.pumpAndSettle();

      expect(find.byType(TextPage), findsOneWidget);
    });

    testWidgets('navigates to $ProgressPage when Progress button is tapped',
        (tester) async {
      await tester.pumpWidget(const App(environment: 'Testing'));
      await tester.tap(find.text('Progress'));
      await tester.pumpAndSettle();

      expect(find.byType(ProgressPage), findsOneWidget);
    });

    testWidgets(
        'navigates to $ComplexTextPage when Complex Text button is tapped',
        (tester) async {
      await tester.pumpWidget(const App(environment: 'Testing'));
      await tester.tap(find.text('Complex Text'));
      await tester.pumpAndSettle();

      expect(find.byType(ComplexTextPage), findsOneWidget);
    });

    testWidgets(
        'navigates to $SimpleMenuPage when Simple Menu button is tapped',
        (tester) async {
      await tester.pumpWidget(const App(environment: 'Testing'));
      await tester.tap(find.text('Simple Menu'));
      await tester.pumpAndSettle();

      expect(find.byType(SimpleMenuPage), findsOneWidget);
    });

    testWidgets(
        '''navigates to $ScrollableListPage when Scrollable List button is tapped''',
        (tester) async {
      await tester.pumpWidget(const App(environment: 'Testing'));
      await tester.tap(find.text('Scrollable List'));
      await tester.pumpAndSettle();

      expect(find.byType(ScrollableListPage), findsOneWidget);
    });
  });
}
