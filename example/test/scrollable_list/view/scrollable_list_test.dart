import 'package:example/scrollable_list/view/scrollable_list.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/helpers.dart';

void main() {
  group('$ScrollableListPage', () {
    testWidgets('renders $ScrollableListPage', (tester) async {
      await tester.pumpApp(const ScrollableListPage());

      expect(find.byType(ScrollableListPage), findsOneWidget);
    });

    testWidgets('renders "List items"', (tester) async {
      await tester.pumpApp(const ScrollableListPage());

      expect(find.text('List item 1'), findsOneWidget);
      expect(find.text('List item 2'), findsOneWidget);
      expect(find.text('List item 3'), findsOneWidget);
    });
  });
}
