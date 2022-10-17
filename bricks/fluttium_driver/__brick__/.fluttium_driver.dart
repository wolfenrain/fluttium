import 'dart:async';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:{{{projectName}}}/{{{mainEntry}}}' as app;

late IntegrationTestWidgetsFlutterBinding binding;
late FluttiumManager manager;

void main() {
  manager = FluttiumManager();
  binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    '{{flowDescription}}',
    (tester) async {
      app.main();
      await tester.pumpAndSettle();
      {{#flowSteps}}
      {{{step}}}
      {{/flowSteps}}
    },
  );
}

extension on WidgetTester {
  Finder _findByText(String text) {
    final regexp = RegExp('^$text\$');
    var finder = find.bySemanticsLabel(regexp);
    if (finder.evaluate().isEmpty) {
      finder = find.byTooltip(text);
      if (finder.evaluate().isEmpty) {
        finder = find.textContaining(regexp);
      }
    }
    return finder;
  }

  Future<void> expectVisible(String text) async {
    await manager.start();
    if (_findByText(text).evaluate().isNotEmpty) {
      await manager.done();
    } else {
      await manager.fail();
    }
  }

  Future<void> expectNotVisible(String text) async {
    await manager.start();
    if (_findByText(text).evaluate().isEmpty) {
      await manager.done();
    } else {
      await manager.fail();
    }
  }

  Future<void> tapOn(String text) async {
    await manager.start();
    await tap(_findByText(text));
    await pumpAndSettle();
    await manager.done();
  }

  Future<void> takeScreenshot(String name) async {
    await manager.start();
    final RenderRepaintBoundary boundary =
        firstRenderObject(find.byType(RepaintBoundary));
    final image = await boundary.toImage();
    final byteData = await image.toByteData(format: ImageByteFormat.png);
    final pngBytes = byteData!.buffer.asUint8List();
    await manager.send('screenshot', pngBytes.join(','));
    await manager.done();
  }

  Future<void> inputText(String text) async {
    await manager.start();
    var chars = [];
    for (final char in text.split('')) {
      chars.add(char);
      testTextInput.enterText(chars.join());
      await pump(Duration(milliseconds: 100));
    }
    await manager.done();
  }
}

class FluttiumManager {
  bool _hasFailed = false;

  Future<void> start() => send('start');

  Future<void> done() => send('done');

  Future<void> fail() async {
    await send('fail');
    _hasFailed = true; 
  }

  Future<void> send(String action, [Object? data]) async {
    if (_hasFailed) {
      return Completer().future;
    }
    final message = 'fluttium:$action:$data;';

    final maxLength = 800;
    for (int i = 0; i < message.length; i += maxLength) {
      int offset = i + maxLength;
      final piece = message.substring(i, offset >= message.length ? message.length : offset);
      debugPrint(piece);
    }
  }
}