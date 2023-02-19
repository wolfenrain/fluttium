import 'package:flutter/gestures.dart';
import 'package:fluttium/fluttium.dart';

/// {@template long_tap_on}
/// Tap on a node that matches the arguments.
///
/// This action can be invoked either using the short-hand version:
///
/// ```yaml
/// - longTapOn: "Hello World"
/// ```
///
/// Or using the verbose version:
///
/// ```yaml
/// - longTapOn:
///     text: "Hello World"
/// - longTapOn:
///     offset: [0.5, 0.5]
/// ```
/// {@endtemplate}
class LongTapOn extends Action {
  /// {@macro long_tap_on}
  const LongTapOn({
    this.text,
    this.offset,
  });

  /// Optional text to search for.
  final String? text;

  /// Optional offset to tap on.
  final Offset? offset;

  static int _pointerId = 0;

  @override
  Future<bool> execute(Tester tester) async {
    final Offset center;
    if (text != null) {
      final node = await tester.find(text!);
      if (node == null) {
        return false;
      }
      center = node.center;
    } else if (offset != null) {
      center = offset!;
    } else {
      return false;
    }

    final pointer = _pointerId++;
    tester.emitPointerEvent(
      PointerDownEvent(pointer: pointer, position: center),
    );
    await tester.pump(duration: kLongPressTimeout + kPressTimeout);
    tester.emitPointerEvent(
      PointerUpEvent(pointer: pointer, position: center),
    );
    await tester.pumpAndSettle();

    return true;
  }

  @override
  String description() {
    if (text != null) {
      return 'Long tap on "$text"';
    } else if (offset != null) {
      return 'Long tap on [${offset!.dx}, ${offset!.dy}]';
    }
    throw UnsupportedError('LongTapOn must have either text or offset');
  }
}
