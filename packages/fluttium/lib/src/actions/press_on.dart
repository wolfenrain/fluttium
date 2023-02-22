import 'package:flutter/gestures.dart';
import 'package:fluttium/fluttium.dart';

/// {@template press_on}
/// Press on a node that matches the arguments.
///
/// This action can be invoked either using the short-hand version:
///
/// ```yaml
/// - pressOn: "Hello World"
/// ```
///
/// Or using the verbose version:
///
/// ```yaml
/// - pressOn:
///     text: "Hello World"
/// - pressOn:
///     offset: [0.5, 0.5]
/// ```
/// {@endtemplate}
class PressOn extends Action {
  /// {@macro press_on}
  const PressOn({
    this.text,
    this.offset,
  });

  /// Optional text to search for.
  final String? text;

  /// Optional offset to tap on.
  final List<double>? offset;

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
      center = Offset(offset!.first, offset!.last);
    } else {
      return false;
    }

    final pointer = _pointerId++;
    tester.emitPointerEvent(
      PointerDownEvent(pointer: pointer, position: center),
    );
    await tester.pump(duration: kPressTimeout);
    tester.emitPointerEvent(
      PointerUpEvent(pointer: pointer, position: center),
    );
    await tester.pumpAndSettle();

    return true;
  }

  @override
  String description() {
    if (text != null) {
      return 'Press on "$text"';
    } else if (offset != null) {
      return 'Press on [${offset!.first}, ${offset!.last}]';
    }
    throw UnsupportedError('PressOn must have either text or offset');
  }
}
