import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';

TypeMatcher<T> isPointerEvent<T extends PointerEvent>({
  Offset? position,
}) {
  var matcher = isA<T>();

  if (position != null) {
    matcher = matcher.having((p0) => p0.position, 'position', equals(position));
  }
  return matcher;
}

Matcher isPointerScollEvent({
  required Offset scrollDelta,
  Offset? position,
}) {
  final matcher = isPointerEvent<PointerScrollEvent>(position: position).having(
    (p0) => p0.scrollDelta,
    'scrollDelta',
    equals(scrollDelta),
  );

  return matcher;
}
