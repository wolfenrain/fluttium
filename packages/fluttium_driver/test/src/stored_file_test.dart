// ignore_for_file: prefer_const_constructors

import 'package:fluttium_driver/fluttium_driver.dart';
import 'package:test/test.dart';

void main() {
  group('$StoredFile', () {
    test('can be instantiated', () {
      final storedFile = StoredFile('path', [1, 2, 3]);
      expect(storedFile, isNotNull);
    });
  });
}
