// ignore_for_file: prefer_const_constructors

import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluttium/fluttium.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/helpers.dart';

void main() {
  group('ExpectNotVisible', () {
    late Tester tester;
    late SemanticsNode node;

    setUp(() {
      tester = MockTester();
      node = MockSemanticsNode();
    });

    test('returns true if nothing was found', () async {
      final expectNotVisible = ExpectNotVisible(text: 'hello');

      when(() => tester.find(any(), timeout: any(named: 'timeout')))
          .thenAnswer((_) async => null);

      expect(await expectNotVisible.execute(tester), isTrue);

      verify(
        () => tester.find(
          any(that: equals('hello')),
          timeout: any(
            named: 'timeout',
            that: equals(Duration(milliseconds: 500)),
          ),
        ),
      ).called(1);
    });

    test('returns false if something was found', () async {
      final expectNotVisible = ExpectNotVisible(text: 'hello');

      when(() => tester.find(any(), timeout: any(named: 'timeout')))
          .thenAnswer((_) async => node);

      expect(await expectNotVisible.execute(tester), isFalse);

      verify(
        () => tester.find(
          any(that: equals('hello')),
          timeout: any(
            named: 'timeout',
            that: equals(Duration(milliseconds: 500)),
          ),
        ),
      ).called(1);
    });

    test('Readable representation', () {
      final expectNotVisible = ExpectNotVisible(text: 'hello');

      expect(expectNotVisible.description(), 'Expect not visible "hello"');
    });
  });
}
