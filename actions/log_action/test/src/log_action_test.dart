import 'package:flutter_test/flutter_test.dart';
import 'package:fluttium/fluttium.dart';
import 'package:log_action/log_action.dart';
import 'package:mocktail/mocktail.dart';

class _MockTester extends Mock implements Tester {}

void main() {
  group('LogAction', () {
    late Tester tester;

    setUp(() {
      tester = _MockTester();
    });

    test('executes returns true', () async {
      final action = LogAction(text: 'Hello World');

      expect(await action.execute(tester), isTrue);
    });

    test('show correct description', () {
      final action = LogAction(text: 'Hello World');

      expect(action.description(), equals('Log: Hello World'));
    });
  });
}
