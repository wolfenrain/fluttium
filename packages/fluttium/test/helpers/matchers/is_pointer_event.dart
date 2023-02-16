import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';

Matcher isPointerEvent<T extends PointerEvent>({
  Offset? position,
}) {
  var matcher = isA<T>();

  if (position != null) {
    matcher = matcher.having(
      (p0) => p0.position,
      'position',
      equals(position),
    );
  }
  return matcher;
}
