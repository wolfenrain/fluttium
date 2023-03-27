import 'package:flutter/rendering.dart';
import 'package:fluttium/src/actions/scroll.dart';

/// {@template swipe}
/// Swipe left or right within a node until a child node is found.
///
/// This action can be invoked as followed:
/// ```yaml
/// - swipe:
///     within: "Your List View"
///     until: "Your List Item"
///     direction: right # Defaults to left
///     timeout: 5000 # In milliseconds, default is 10 seconds
///     speed: 10 # Defaults to 40
/// ```
/// {@endtemplate}
class Swipe extends Scroll {
  /// {@template swipe}
  Swipe({
    required super.within,
    required super.until,
    super.direction = AxisDirection.left,
    super.timeout,
    super.speed,
  }) {
    if ([AxisDirection.down, AxisDirection.up].contains(direction)) {
      throw UnsupportedError(
        'The direction "${direction.name}" is not supported for swiping',
      );
    }
  }

  @override
  String description() {
    return 'Swipe ${direction.name} in "$within" until "$until" is found';
  }
}
