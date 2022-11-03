import 'package:flutter/gestures.dart';
import 'package:fluttium/fluttium.dart';

/// {@template tap_on}
/// Tap on a node that matches the arguments.
/// {@endtemplate}
class TapOn extends Action {
  /// {@macro tap_on}
  const TapOn({
    this.text,
    this.offset,
  });

  /// Optional text to search for.
  final String? text;

  /// Optional offset to tap on.
  final Offset? offset;

  @override
  Future<bool> execute(FluttiumTester tester) async {
    final Offset center;
    if (text != null) {
      final node = await tester.find(text!);
      if (node == null) {
        return false;
      }
      center = node.rect.center;
    } else if (offset != null) {
      center = offset!;
    } else {
      return false;
    }

    tester.emitPointerEvent(PointerDownEvent(position: center));
    await Future<void>.delayed(kPressTimeout);
    tester.emitPointerEvent(PointerUpEvent(position: center));
    await tester.pumpAndSettle();

    return true;
  }
}
