import 'dart:ui';

import 'package:fluttium/fluttium.dart';

/// {@template take_screenshot}
/// Takes a screenshot of the current screen.
///
/// This action can be invoked either using the short-hand version:
///
/// ```yaml
/// - takeScreenshot: "my_screenshot.png"
/// ```
///
/// Or using the verbose version:
///
/// ```yaml
/// - takeScreenshot:
///     path: "my_screenshot.png"
///     pixelRatio: 1.5
/// ```
/// {@endtemplate}
class TakeScreenshot extends Action {
  /// {@macro take_screenshot}
  const TakeScreenshot({
    required this.path,
    this.pixelRatio,
  });

  /// The file path to save the screenshot to.
  final String path;

  /// Optional pixel ratio to take screenshot with, defaults to device pixel
  /// ratio.
  final double? pixelRatio;

  @override
  Future<bool> execute(Tester tester) async {
    final boundary = tester.getRenderRepaintBoundary();
    if (boundary == null) {
      return false;
    }

    final image = await boundary.toImage(
      pixelRatio: pixelRatio ?? tester.mediaQuery.devicePixelRatio,
    );
    final byteData = await image.toByteData(format: ImageByteFormat.png);
    final pngBytes = byteData!.buffer.asUint8List();
    await tester.storeFile(path, pngBytes);

    return true;
  }

  @override
  String description() => 'Screenshot "$path"';
}
