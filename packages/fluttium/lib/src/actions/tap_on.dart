import 'package:flutter/gestures.dart';
import 'package:fluttium/fluttium.dart';

/// {@template tap_on}
/// Tap on a node that matches the arguments.
///
/// tapOn: text
/// tapOn:
///   - offset: [0.5, 0.5]
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
    await Future<void>.delayed(kPressTimeout);
    tester.emitPointerEvent(
      PointerUpEvent(pointer: pointer, position: center),
    );
    await tester.pumpAndSettle();

    return true;
  }

  @override
  String description() {
    if (text != null) {
      return 'Tap on "$text"';
    } else if (offset != null) {
      return 'Tap on [${offset!.dx}, ${offset!.dy}]';
    }
    throw UnsupportedError('TapOn must have either text or offset');
  }
}
