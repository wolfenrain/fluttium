import 'dart:ui';

import 'package:flutter/rendering.dart';
import 'package:fluttium/fluttium.dart';

/// {@template take_screenshot}
/// Takes a screenshot of the current screen.
/// {@endtemplate}
class TakeScreenshot extends Action {
  /// {@macro take_screenshot}
  const TakeScreenshot({
    required this.fileName,
  });

  /// The file name to save the screenshot to.
  final String fileName;

  @override
  Future<bool> execute(Tester tester) async {
    RenderRepaintBoundary? boundary;
    void find(RenderObject element) {
      if (boundary != null) return;

      if (element is! RenderRepaintBoundary) {
        return element.visitChildren(find);
      }
      boundary = element;
    }

    if (tester.renderObject is! RenderRepaintBoundary) {
      tester.renderObject.visitChildren(find);
    } else {
      boundary = tester.renderObject as RenderRepaintBoundary;
    }

    if (boundary == null) {
      return false;
    }

    final image = await boundary!.toImage();
    final byteData = await image.toByteData(format: ImageByteFormat.png);
    final pngBytes = byteData!.buffer.asUint8List();
    await tester.storeFile('screenshots/$fileName.png', pngBytes);

    return true;
  }

  @override
  String description() => 'Screenshot "$fileName"';
}
