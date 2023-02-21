import 'package:flutter_test/flutter_test.dart';
import 'package:fluttium/src/text_input_controller.dart';

void main() {
  group('TextInputController', () {
    test('set editing state', () {
      final textInputController = TextInputController();
      const textEditingValue = TextEditingValue(text: 'Hello world');

      expect(textInputController.value, isNot(equals(textEditingValue)));

      textInputController.setEditingState(textEditingValue);
      expect(textInputController.value, equals(textEditingValue));
    });
  });
}
