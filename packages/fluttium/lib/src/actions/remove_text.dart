import 'package:flutter/services.dart';
import 'package:fluttium/fluttium.dart';

/// {@template remove_text}
/// Remove text automatically.
///
/// This action can be invoked either using the short-hand version:
///
/// ```yaml
/// - removeText:
/// ```
///
/// Or using the verbose version:
///
/// ```yaml
/// - removeText:
///     amount: 10
/// ```
/// {@endtemplate}
class RemoveText extends Action {
  /// {@macro remove_text}
  const RemoveText({
    this.amount = 1,
  });

  /// The amount to remove
  final int amount;

  @override
  Future<bool> execute(Tester tester) async {
    for (var i = 0; i < amount; i++) {
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
  String description() =>
      'Remove text $amount ${amount == 1 ? 'time' : 'times'}';
}
