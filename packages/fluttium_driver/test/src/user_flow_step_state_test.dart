import 'package:fluttium_driver/fluttium_driver.dart';
import 'package:fluttium_interfaces/fluttium_interfaces.dart';
import 'package:test/test.dart';

void main() {
  group('$UserFlowStepState', () {
    const step = UserFlowStep('action', arguments: 'arguments');

    test('can be instantiated', () {
      final state = UserFlowStepState(step);

      expect(state.description, equals(''));
      expect(state.status, equals(StepStatus.initial));
      expect(state.failReason, isNull);
    });

    test('copyWith', () {
      final state = UserFlowStepState(step);

      final copied = state.copyWith(
        description: 'description',
        status: StepStatus.done,
        failReason: 'failReason',
      );

      expect(copied.description, equals('description'));
      expect(copied.status, equals(StepStatus.done));
      expect(copied.failReason, equals('failReason'));

      expect(state.copyWith(), equals(state));
    });

    test('equality', () {
      final state = UserFlowStepState(step);
      final otherState = UserFlowStepState(step);

      expect(state, equals(otherState));
    });
  });
}
