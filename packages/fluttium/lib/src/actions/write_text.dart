import 'package:flutter/services.dart';
import 'package:fluttium/fluttium.dart';
import 'package:fluttium/src/text_input_controller.dart';

/// {@template write_text}
/// Write text automatically.
///
/// This action can be invoked either using the short-hand version:
///
/// ```yaml
/// - writeText: "Hello World"
/// ```
///
/// Or using the verbose version:
///
/// ```yaml
/// - writeText:
///     text: "Hello World"
/// ```
/// {@endtemplate}
class WriteText extends Action {
  /// {@macro write_text}
  WriteText({
    required this.text,
  });

  /// The text to write.
  final String text;

  final _textInputController = TextInputController();

  Future<void> _enterText(Tester tester, String text) async {
    final fullText = _textInputController.value.text + text;
    _textInputController.value = _textInputController.value.copyWith(
      text: fullText,
      selection: TextSelection.collapsed(offset: fullText.length),
    );

    tester.emitPlatformMessage(
      SystemChannels.textInput.name,
      SystemChannels.textInput.codec.encodeMethodCall(
        MethodCall(
          'TextInputClient.updateEditingState',
          [-1, _textInputController.value.toJSON()],
        ),
      ),
    );
  }

  @override
  Future<bool> execute(Tester tester) async {
    TextInput.setInputControl(_textInputController);
    tester.emitPlatformMessage(
      SystemChannels.textInput.name,
      SystemChannels.textInput.codec.encodeMethodCall(
        const MethodCall('TextInputClient.requestExistingInputState'),
      ),
    );
    TextInput.restorePlatformInputControl();

    for (final char in text.split('')) {
      await _enterText(tester, char);
      await tester.pumpAndSettle();
    }
    return true;
  }

  @override
  String description() => 'Write text "$text"';
}
