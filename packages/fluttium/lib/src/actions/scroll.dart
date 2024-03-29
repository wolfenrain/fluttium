import 'package:clock/clock.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:fluttium/fluttium.dart';

/// {@template scroll}
/// Scroll within a node with a given direction until a child node is found.
///
/// This action can be invoked as followed:
/// ```yaml
/// - scroll:
///     within: "Your List View"
///     until: "Your List Item"
///     direction: up # Defaults to down
///     timeout: 5000 # In milliseconds, default is 10 seconds
///     speed: 10 # Defaults to 40
/// ```
/// {@endtemplate}
class Scroll extends Action {
  /// {@macro scroll}
  Scroll({
    required this.within,
    required this.until,
    this.speed = 40,
    int? timeout,
    this.direction = AxisDirection.down,
  }) : timeout = Duration(milliseconds: timeout ?? 100000);

  /// The string to find the semantic node, in which the scrolling will happen.
  final String within;

  /// Scroll until the given semantic node is found.
  final String until;

  /// The direction of the scrolling.
  final AxisDirection direction;

  /// The scrolling speed.
  final double speed;

  /// The time it will try to keep scrolling until it found the node.
  final Duration timeout;

  @override
  Future<bool> execute(Tester tester) async {
    final node = await tester.find(within);
    if (node == null) {
      return false;
    }

    final Offset scrollDelta;
    switch (direction) {
      case AxisDirection.up:
        scrollDelta = Offset(0, -speed);
        break;
      case AxisDirection.right:
        scrollDelta = Offset(speed, 0);
        break;
      case AxisDirection.down:
        scrollDelta = Offset(0, speed);
        break;
      case AxisDirection.left:
        scrollDelta = Offset(-speed, 0);
        break;
    }

    final end = clock.now().add(timeout);
    while ((await tester.find(until, timeout: Duration.zero)) == null) {
      tester.emitPointerEvent(
        PointerScrollEvent(
          position: node.center,
          scrollDelta: scrollDelta,
        ),
      );
      await tester.pump();
      if (clock.now().isAfter(end)) {
        return false;
      }
    }

    return true;
  }

  @override
  String description() {
    return 'Scroll ${direction.name} in "$within" until "$until" is found';
  }
}
