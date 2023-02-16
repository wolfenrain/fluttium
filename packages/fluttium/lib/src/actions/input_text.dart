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
/// ```
/// {@endtemplate}
class InputText extends Action {
  /// {@macro input_text}
  const InputText({
    required this.text,
  });

  /// The text to input.
  final String text;

  Future<void> _enterText(Tester tester, String text) async {
    final value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );

    await tester.emitPlatformMessage(
      SystemChannels.textInput.name,
      SystemChannels.textInput.codec.encodeMethodCall(
        MethodCall(
          'TextInputClient.updateEditingState',
          <dynamic>[-1, value.toJSON()],
        ),
      ),
    );
  }

  @override
  Future<bool> execute(Tester tester) async {
    final chars = <String>[];
    for (final char in text.split('')) {
      chars.add(char);
      await _enterText(tester, chars.join());
      await tester.pumpAndSettle();
    }
    return true;
  }

  @override
  String description() => 'Input text "$text"';
}
