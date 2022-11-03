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
  Future<bool> execute(FluttiumBinding worker) async {
    RenderRepaintBoundary? boundary;
    void find(RenderObject element) {
      if (boundary != null) return;

      if (element is! RenderRepaintBoundary) {
        return element.visitChildren(find);
      }
      boundary = element;
    }

    worker.renderObject.visitChildren(find);

    final image = await boundary!.toImage();
    final byteData = await image.toByteData(format: ImageByteFormat.png);
    final pngBytes = byteData!.buffer.asUint8List();
    await worker.storeFile('screenshots/$fileName.png', pngBytes);

    return true;
  }
}
