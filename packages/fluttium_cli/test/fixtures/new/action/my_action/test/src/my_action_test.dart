// ignore_for_file: prefer_const_constructors

import 'package:flutter_test/flutter_test.dart';
import 'package:fluttium/fluttium.dart';
import 'package:my_action/my_action.dart';
import 'package:mocktail/mocktail.dart';

class _MockTester extends Mock implements Tester {}

class _MockSemanticsNode extends Mock implements SemanticsNode {
  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return super.toString();
  }
}

void main() {
  group('MyAction', () {
    late Tester tester;
    late SemanticsNode node;

    setUp(() {
      tester = _MockTester();
      node = _MockSemanticsNode();

      when(() => tester.find(any())).thenAnswer((_) async => node);
    });

    test('executes returns true if node was found', () async {
      final action = MyAction(text: 'Hello World');

      expect(await action.execute(tester), isTrue);
    });

    test('executes returns false if node was not found', () async {
      when(() => tester.find(any())).thenAnswer((_) async => null);

      final action = MyAction(text: 'Hello World');

      expect(await action.execute(tester), isFalse);
    });

    test('show correct description', () {
      final action = MyAction(text: 'Hello World');

      expect(
        action.description(),
        equals('My action: "Hello World"'),
      );
    });
  });
}
