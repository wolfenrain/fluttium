import 'package:flutter/services.dart';
import 'package:fluttium/fluttium.dart';

/// {@template press_key}
/// TODO: docs
/// {@endtemplate}
class PressKey extends Action {
  /// {@macro press_key}
  const PressKey({
    required this.key,
    this.downFor = 1,
  });

  /// The key that is being pressed.
  final String key;

  /// For how long the key will be down.
  final int downFor;

  @override
  Future<bool> execute(Tester tester) async {
    final logicalKey = LogicalKeyboardKey.knownLogicalKeys.firstWhere((key) {
      return key.debugName?.toLowerCase() == this.key.toLowerCase();
    });

    final physicalKey = PhysicalKeyboardKey.knownPhysicalKeys.firstWhere((key) {
      return logicalKey.debugName == key.debugName;
    });

    tester.emitKeyEvent(
      KeyDownEvent(
        physicalKey: physicalKey,
        logicalKey: logicalKey,
        timeStamp: Duration.zero,
      ),
    );

    await tester.pump(duration: Duration(milliseconds: downFor));

    tester.emitKeyEvent(
      KeyUpEvent(
        physicalKey: physicalKey,
        logicalKey: logicalKey,
        timeStamp: Duration.zero,
      ),
    );

    return true;
  }

  @override
  String description() => 'Press key: $key';
}
