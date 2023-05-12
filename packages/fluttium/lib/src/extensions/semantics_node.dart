import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Extension methods for [SemanticsNode].
extension SemanticsNodeX on SemanticsNode {
  /// Returns the global center of the node.
  ///
  /// Based on: https://github.com/clickup/honey/blob/5cbc41e1440646bcef37cf8cffc428de13d9a7a9/honey/lib/src/semantics/semantics_extension.dart
  Offset get center {
    var paintBounds = rect;
    SemanticsNode? current = this;
    while (current != null) {
      final transform = current.transform;
      if (transform != null) {
        paintBounds = MatrixUtils.transformRect(transform, paintBounds);
      }
      current = current.parent;
    }

    final devicePixelRatio =
        WidgetsBinding.instance.platformDispatcher.views.first.devicePixelRatio;
    return MatrixUtils.transformRect(
      Matrix4.diagonal3Values(
        1.0 / devicePixelRatio,
        1.0 / devicePixelRatio,
        1.0 / devicePixelRatio,
      ),
      paintBounds,
    ).center;
  }
}
