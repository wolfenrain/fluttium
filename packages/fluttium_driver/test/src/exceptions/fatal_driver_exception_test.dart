// ignore_for_file: deprecated_member_use_from_same_package,
// ignore_for_file: prefer_const_constructors

import 'package:fluttium_driver/fluttium_driver.dart';
import 'package:test/test.dart';

void main() {
  group('FatalDriverException', () {
    test('can be created', () {
      expect(FatalDriverException(''), isNotNull);
    });

    test('toString', () {
      expect(
        FatalDriverException('').toString(),
        equals('A fatal exception happened on the driver: '),
      );
    });
  });
}
