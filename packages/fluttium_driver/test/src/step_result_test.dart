import 'package:fluttium_driver/fluttium_driver.dart';
import 'package:test/test.dart';

void main() {
  group('StepState', () {
    test('can be instantiated', () {
      final state = StepState('description');

      expect(state.description, equals('description'));
      expect(state.status, equals(StepStatus.initial));
      expect(state.files, isEmpty);
      expect(state.failReason, isNull);
    });

    test('copyWith', () {
      final state = StepState('description');

      final copied = state.copyWith(
        status: StepStatus.done,
        files: {
          'file': [1, 2, 3]
        },
        failReason: 'failReason',
      );

      expect(copied.description, equals('description'));
      expect(copied.status, equals(StepStatus.done));
      expect(
        copied.files,
        equals({
          'file': [1, 2, 3]
        }),
      );
      expect(copied.failReason, equals('failReason'));

      expect(state.copyWith(), equals(state));
    });

    test('equality', () {
      final state = StepState('description');
      final otherState = StepState('description');

      expect(state, equals(otherState));
    });
  });
}
