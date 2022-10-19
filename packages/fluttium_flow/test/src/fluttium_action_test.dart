// ignore_for_file: prefer_const_constructors

import 'package:fluttium_flow/fluttium_flow.dart';
import 'package:test/test.dart';

void main() {
  group('FluttiumAction', () {
    test('can resolve from a string', () {
      expect(
        FluttiumAction.resolve('expectNotVisible'),
        equals(FluttiumAction.expectNotVisible),
      );
    });

    test('throws exception when it can not resolve from a string', () {
      expect(
        () => FluttiumAction.resolve('expectToFail'),
        throwsUnimplementedError,
      );
    });

    test('is able to resolve all enum values', () {
      for (final action in FluttiumAction.values) {
        expect(FluttiumAction.resolve(action.name), equals(action));
      }
    });
  });
}
