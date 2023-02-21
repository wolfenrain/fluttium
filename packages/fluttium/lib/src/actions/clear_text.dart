import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:fluttium/fluttium.dart';
import 'package:fluttium/src/text_input_controller.dart';

/// {@template clear_text}
/// Clear text automatically.
///
/// This action can be invoked either using the short-hand version:
///
/// ```yaml
/// - clearText:
/// ```
///
/// Or using the verbose version:
///
/// ```yaml
/// - clearText:
///     characters: 10
/// ```
/// {@endtemplate}
class ClearText extends Action {
  /// {@macro clear_text}
  ClearText({
    this.characters = 1 << 31,
  });

  /// The amount of characters to clear.
  final int characters;

  /// Holds a reference to the text input value.
  @visibleForTesting
  final textInputController = TextInputController();

  @override
  Future<bool> execute(Tester tester) async {
    for (var i = 0; i < characters; i++) {
      TextInput.setInputControl(textInputController);
      await tester.emitPlatformMessage(
        SystemChannels.textInput.name,
        SystemChannels.textInput.codec.encodeMethodCall(
          const MethodCall('TextInputClient.requestExistingInputState'),
        ),
      );
      TextInput.restorePlatformInputControl();

      // If the current text field is empty, we can skip the rest
      if (textInputController.value.text.isEmpty) {
        return true;
      }

      await tester.emitPlatformMessage(
        SystemChannels.textInput.name,
        SystemChannels.textInput.codec.encodeMethodCall(
          const MethodCall('TextInputClient.performSelectors', [
            -1,
            ['deleteBackward:']
          ]),
        ),
      );
      await tester.pumpAndSettle();
    }

    return true;
  }

  @override
  String description() => 'Clear text';
}
