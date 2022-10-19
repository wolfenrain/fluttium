import 'package:example/app/app.dart';
import 'package:example/counter/counter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('App', () {
    testWidgets('renders CounterPage', (tester) async {
      await tester.pumpWidget(const App(environment: 'Testing'));
      expect(find.byType(CounterPage), findsOneWidget);
    });
  });
}
