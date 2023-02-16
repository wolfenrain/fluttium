// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluttium/fluttium.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TapOn', () {
    late Tester tester;
    late SemanticsNode node;

    setUp(() {
      tester = MockTester();
      node = MockSemanticsNode();
      when(() => node.transform).thenReturn(Matrix4.identity());
      when(() => node.rect).thenReturn(
        Rect.fromCircle(center: Offset.zero, radius: 10),
      );

      when(() => tester.find(any(), timeout: any(named: 'timeout')))
          .thenAnswer((_) async => node);
      when(() => tester.pumpAndSettle(timeout: any(named: 'timeout')))
          .thenAnswer((_) async {});
      when(() => tester.emitPointerEvent(any())).thenAnswer((_) async {});
    });

    setUpAll(() {
      registerFallbackValue(FakePointerEvent());
    });

    test('returns false if no valid parameters are given', () {
      final action = TapOn();
      expect(action.execute(tester), completion(isFalse));
    });

    test('taps on offset when given given', () async {
      final tapOn = TapOn(offset: Offset.zero);

      expect(await tapOn.execute(tester), isTrue);

      verify(
        () => tester.emitPointerEvent(
          any(that: isPointerEvent<PointerDownEvent>(position: Offset.zero)),
        ),
      ).called(1);
      verify(
        () => tester.emitPointerEvent(
          any(that: isPointerEvent<PointerUpEvent>(position: Offset.zero)),
        ),
      ).called(1);
    });

    group('if text is given', () {
      test('and a node is found it taps on the center of the node', () async {
        final tapOn = TapOn(text: 'hello');

        expect(await tapOn.execute(tester), isTrue);

        verify(
          () => tester.emitPointerEvent(
            any(that: isPointerEvent<PointerDownEvent>(position: Offset.zero)),
          ),
        ).called(1);
        verify(
          () => tester.emitPointerEvent(
            any(that: isPointerEvent<PointerUpEvent>(position: Offset.zero)),
          ),
        ).called(1);
      });

      test('and a node is not found it returns false', () async {
        final tapOn = TapOn(text: 'hello');

        when(() => tester.find(any(), timeout: any(named: 'timeout')))
            .thenAnswer((_) async => null);

        expect(await tapOn.execute(tester), isFalse);

        verifyNever(
          () => tester.emitPointerEvent(
            any(that: isPointerEvent<PointerDownEvent>(position: Offset.zero)),
          ),
        );
        verifyNever(
          () => tester.emitPointerEvent(
            any(that: isPointerEvent<PointerUpEvent>(position: Offset.zero)),
          ),
        );
      });
    });

    group('Readable representation', () {
      test('with text', () {
        final tapOn = TapOn(text: 'hello');
        expect(tapOn.description(), 'Tap on "hello"');
      });

      test('with offset', () {
        final tapOn = TapOn(offset: Offset.zero);
        expect(tapOn.description(), 'Tap on [0.0, 0.0]');
      });

      test('with none', () {
        final tapOn = TapOn();

        expect(tapOn.description, throwsUnsupportedError);
      });
    });
  });
}
