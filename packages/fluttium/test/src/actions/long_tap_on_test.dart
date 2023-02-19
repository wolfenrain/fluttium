// ignore_for_file: prefer_const_constructors

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluttium/fluttium.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LongTapOn', () {
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
      when(() => tester.pump(duration: any(named: 'duration')))
          .thenAnswer((_) async {});
    });

    setUpAll(() {
      registerFallbackValue(FakePointerEvent());
    });

    test('returns false if no valid parameters are given', () {
      final longTapOn = LongTapOn();
      expect(longTapOn.execute(tester), completion(isFalse));
    });

    test('taps on offset when given given', () async {
      final longTapOn = LongTapOn(offset: Offset.zero);

      expect(await longTapOn.execute(tester), isTrue);

      verify(
        () => tester.emitPointerEvent(
          any(that: isPointerEvent<PointerDownEvent>(position: Offset.zero)),
        ),
      ).called(1);
      verify(
        () => tester.pump(
          duration: any(
            named: 'duration',
            that: equals(kLongPressTimeout + kPressTimeout),
          ),
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
        final longTapOn = LongTapOn(text: 'hello');

        expect(await longTapOn.execute(tester), isTrue);

        verify(
          () => tester.emitPointerEvent(
            any(that: isPointerEvent<PointerDownEvent>(position: Offset.zero)),
          ),
        ).called(1);
        verify(
          () => tester.pump(
            duration: any(
              named: 'duration',
              that: equals(kLongPressTimeout + kPressTimeout),
            ),
          ),
        ).called(1);
        verify(
          () => tester.emitPointerEvent(
            any(that: isPointerEvent<PointerUpEvent>(position: Offset.zero)),
          ),
        ).called(1);
      });

      test('and a node is not found it returns false', () async {
        final longTapOn = LongTapOn(text: 'hello');

        when(() => tester.find(any(), timeout: any(named: 'timeout')))
            .thenAnswer((_) async => null);

        expect(await longTapOn.execute(tester), isFalse);

        verifyNever(
          () => tester.emitPointerEvent(
            any(that: isPointerEvent<PointerDownEvent>(position: Offset.zero)),
          ),
        );
        verifyNever(
          () => tester.pump(
            duration: any(
              named: 'duration',
              that: equals(kLongPressTimeout + kPressTimeout),
            ),
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
        final longTapOn = LongTapOn(text: 'hello');
        expect(longTapOn.description(), 'Long tap on "hello"');
      });

      test('with offset', () {
        final longTapOn = LongTapOn(offset: Offset.zero);
        expect(longTapOn.description(), 'Long tap on [0.0, 0.0]');
      });

      test('with none', () {
        final longTapOn = LongTapOn();
        expect(longTapOn.description, throwsUnsupportedError);
      });
    });
  });
}
