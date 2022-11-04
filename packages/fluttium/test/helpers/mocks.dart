import 'package:flutter/rendering.dart';
import 'package:fluttium/fluttium.dart';
import 'package:mocktail/mocktail.dart';

mixin DiagnosticableToStringMixin on Object {
  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return super.toString();
  }
}

class MockFluttiumTester extends Mock implements FluttiumTester {}

class MockSemanticsNode extends Mock
    with DiagnosticableToStringMixin
    implements SemanticsNode {}

class FakePointerEvent extends Fake
    with DiagnosticableToStringMixin
    implements PointerEvent {}

class MockRenderRepaintBoundary extends Mock
    with DiagnosticableToStringMixin
    implements RenderRepaintBoundary {}

class MockRenderObject extends Mock
    with DiagnosticableToStringMixin
    implements RenderObject {}
