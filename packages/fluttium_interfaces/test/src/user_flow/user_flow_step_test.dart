// ignore_for_file: prefer_const_constructors

import 'package:fluttium_interfaces/fluttium_interfaces.dart';
import 'package:test/test.dart';

void main() {
  group('UserFlowStep', () {
    test('can be instantiated', () {
      final step = UserFlowStep(
        'tapOn',
        arguments: 'Increment',
      );

      expect(step.actionName, equals('tapOn'));
      expect(step.arguments, equals('Increment'));
    });

    test('fromJson', () {
      final step = UserFlowStep.fromJson(const {
        'expectVisible': {
          'text': 'findByText',
        }
      });

      expect(step.actionName, equals('expectVisible'));
      expect(step.arguments, equals({'text': 'findByText'}));
    });

    test('toJson', () {
      final step = UserFlowStep('tapOn', arguments: 'Increment');

      expect(
        step.toJson(),
        equals({
          'actionName': 'tapOn',
          'arguments': '"Increment"',
        }),
      );
    });

    test('equality', () {
      final step = UserFlowStep('tapOn', arguments: 'Increment');
      final otherStep = UserFlowStep('tapOn', arguments: 'Increment');

      expect(step, equals(otherStep));
    });
  });
}
