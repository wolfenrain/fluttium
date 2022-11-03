import 'package:flutter/services.dart';
import 'package:fluttium/fluttium.dart';

/// {@template input_text}
/// Input text automatically.
/// {@endtemplate}
class InputText extends Action {
  /// {@macro input_text}
  const InputText({
    required this.text,
  });

  /// The text to input.
  final String text;

  Future<void> _enterText(FluttiumBinding worker, String text) async {
    final value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );

    await worker.emitPlatformMessage(
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
  Future<bool> execute(FluttiumBinding worker) async {
    final chars = <String>[];
    for (final char in text.split('')) {
      chars.add(char);
      await _enterText(worker, chars.join());
      await worker.pumpAndSettle();
    }
    return true;
  }
}
