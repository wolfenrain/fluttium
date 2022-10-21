import 'package:example/app/app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('App', () {
    testWidgets('renders AppView', (tester) async {
      await tester.pumpWidget(const App(environment: 'Testing'));
      expect(find.byType(AppView), findsOneWidget);
    });
  });
}
