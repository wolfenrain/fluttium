import 'package:fluttium_driver/fluttium_driver.dart';
import 'package:test/test.dart';

void main() {
  group('FatalDriverException', () {
    test('can be created', () {
      expect(FatalDriverException(''), isNotNull);
    });
  });
}
