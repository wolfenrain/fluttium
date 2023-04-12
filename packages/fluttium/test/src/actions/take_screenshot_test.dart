// ignore_for_file: prefer_const_constructors

import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart' hide Image;
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluttium/fluttium.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/helpers.dart';

class _MockImage extends Mock implements Image {}

void main() {
  group('$TakeScreenshot', () {
    late Tester tester;
    late RenderObject renderObject;
    late RenderRepaintBoundary renderRepaintBoundary;
    late Image image;

    setUp(() {
      tester = MockTester();
      when(() => tester.storeFile(any(), any())).thenAnswer((_) async {});
      when(() => tester.mediaQuery).thenReturn(MediaQueryData());

      renderObject = MockRenderObject();

      image = _MockImage();
      when(() => image.toByteData(format: any(named: 'format'))).thenAnswer(
        (_) async => ByteData.sublistView(Uint8List.fromList([1, 2, 3, 4])),
      );

      renderRepaintBoundary = MockRenderRepaintBoundary();
      when(
        () => renderRepaintBoundary.toImage(
          pixelRatio: any(named: 'pixelRatio'),
        ),
      ).thenAnswer((_) async => image);
      when(() => tester.getRenderRepaintBoundary())
          .thenReturn(renderRepaintBoundary);
    });

    setUpAll(() {
      registerFallbackValue(ImageByteFormat.png);
      registerFallbackValue(Uint8List(0));
    });

    test('takes screenshot of root node', () async {
      final takeScreenshot = TakeScreenshot(path: 'fileName.png');

      expect(await takeScreenshot.execute(tester), isTrue);

      verifyNever(() => renderObject.visitChildren(any()));
      verify(
        () => renderRepaintBoundary.toImage(
          pixelRatio: any(named: 'pixelRatio'),
        ),
      ).called(1);
      verify(
        () => image.toByteData(
          format: any(named: 'format', that: equals(ImageByteFormat.png)),
        ),
      ).called(1);

      verify(
        () => tester.storeFile(
          'fileName.png',
          Uint8List.fromList([1, 2, 3, 4]),
        ),
      ).called(1);
      verify(() => tester.mediaQuery).called(1);
    });

    test('stops early if no repaint boundary was found', () async {
      when(() => tester.getRenderRepaintBoundary()).thenReturn(null);
      final takeScreenshot = TakeScreenshot(path: 'fileName.png');

      expect(await takeScreenshot.execute(tester), isFalse);

      verifyNever(
        () => renderRepaintBoundary.toImage(
          pixelRatio: any(named: 'pixelRatio'),
        ),
      );
      verifyNever(
        () => image.toByteData(
          format: any(named: 'format', that: equals(ImageByteFormat.png)),
        ),
      );

      verifyNever(
        () => tester.storeFile(
          'fileName.png',
          Uint8List.fromList([1, 2, 3, 4]),
        ),
      );
      verifyNever(() => tester.mediaQuery);
    });

    test('Readable representation', () {
      final takeScreenshot = TakeScreenshot(path: 'fileName.png');

      expect(takeScreenshot.description(), 'Screenshot "fileName.png"');
    });
  });
}
