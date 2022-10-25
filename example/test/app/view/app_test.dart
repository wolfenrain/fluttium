import 'package:example/app/app.dart';
import 'package:example/counter/counter.dart';
import 'package:example/progress/progress.dart';
import 'package:example/text/text.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('App', () {
    testWidgets('renders AppView', (tester) async {
      await tester.pumpWidget(const App(environment: 'Testing'));
      expect(find.byType(AppView), findsOneWidget);
    });

    testWidgets('navigates to CounterPage when Counter button is tapped',
        (tester) async {
      await tester.pumpWidget(const App(environment: 'Testing'));
      await tester.tap(find.text('Counter'));
      await tester.pumpAndSettle();

      expect(find.byType(CounterPage), findsOneWidget);
    });

    testWidgets('navigates to TextPage when Text button is tapped',
        (tester) async {
      await tester.pumpWidget(const App(environment: 'Testing'));
      await tester.tap(find.text('Text'));
      await tester.pumpAndSettle();

      expect(find.byType(TextPage), findsOneWidget);
    });

    testWidgets('navigates to ProgressPage when Progress button is tapped',
        (tester) async {
      await tester.pumpWidget(const App(environment: 'Testing'));
      await tester.tap(find.text('Progress'));
      await tester.pumpAndSettle();

      expect(find.byType(ProgressPage), findsOneWidget);
    });
  });
}
