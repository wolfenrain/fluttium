import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:fluttium/fluttium.dart';

/// {@template input_text}
/// Input text automatically.
///
/// This action can be invoked either using the short-hand version:
///
/// ```yaml
/// - inputText: "Hello World"
/// ```
///
/// Or using the verbose version:
///
/// ```yaml
/// - inputText:
///     text: "Hello World"
///     replaceCurrentText: true
/// ```
/// {@endtemplate}
class InputText extends Action {
  /// {@macro input_text}
  InputText({
    required this.text,
    this.replaceCurrentText = false,
  });

  /// The text to input.
  final String text;

  /// If the text should replace the current text
  final bool replaceCurrentText;

  final _textInputController = TextInputController();

  Future<void> _enterText(Tester tester, String text) async {
    final fullText = _textInputController.value.text + text;
    _textInputController.value = _textInputController.value.copyWith(
      text: fullText,
      selection: TextSelection.collapsed(offset: fullText.length),
    );

    await tester.emitPlatformMessage(
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
    if (!replaceCurrentText) {
      TextInput.setInputControl(_textInputController);
      await tester.emitPlatformMessage(
        SystemChannels.textInput.name,
        SystemChannels.textInput.codec.encodeMethodCall(
          const MethodCall('TextInputClient.requestExistingInputState'),
        ),
      );
      TextInput.restorePlatformInputControl();
    }

    for (final char in text.split('')) {
      await _enterText(tester, char);
      await tester.pumpAndSettle();
    }
    return true;
  }

  @override
  String description() => 'Input text "$text"';
}

/// {@template text_input_controller}
/// Used to retrieve the current editing state of an input
/// {@endtemplate}
@visibleForTesting
class TextInputController with TextInputControl {
  /// The current editing state.
  TextEditingValue value = TextEditingValue.empty;

  @override
  void setEditingState(TextEditingValue value) {
    this.value = value;
  }
}
