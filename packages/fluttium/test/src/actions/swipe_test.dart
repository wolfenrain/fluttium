import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluttium/fluttium.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('$Swipe', () {
    test('throws exception with unsupported direction', () {
      expect(
        () => Swipe(within: 'node', until: 'item', direction: AxisDirection.up),
        throwsUnsupportedError,
      );
    });

    test('Readable representation', () {
      final swipe = Swipe(
        within: 'node',
        until: 'item',
        direction: AxisDirection.right,
      );

      expect(
        swipe.description(),
        'Swipe right in "node" until "item" is found',
      );
    });
  });
}
