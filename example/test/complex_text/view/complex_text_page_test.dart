import 'package:example/complex_text/complex_text.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/helpers.dart';

void main() {
  group('ComplexTextPage', () {
    testWidgets('renders ComplexTextView', (tester) async {
      await tester.pumpApp(const ComplexTextPage());
      expect(find.byType(ComplexTextView), findsOneWidget);
    });
  });

  group('ComplexTextView', () {
    testWidgets('renders correctly', (tester) async {
      await tester.pumpApp(const ComplexTextView());

      expect(find.text('Simple text'), findsOneWidget);
      expect(find.text('Text with regexp syntax: (15) [a-z]'), findsOneWidget);
      expect(
        find.text('Text with special characters like: m², m³, m/s²'),
        findsOneWidget,
      );
    });
  });
}
