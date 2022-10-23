import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:{{{project_name}}}/{{{mainEntry}}}' as app;

late IntegrationTestWidgetsFlutterBinding binding;
late FluttiumManager manager;

void main() {
  manager = FluttiumManager();
  binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    '{{flow_description}}',
    (tester) async {
      app.main();
      await tester.pumpAndSettle();
      {{#flow_steps}}
      {{{step}}}
      {{/flow_steps}}
    },
  );
}

extension on WidgetTester {
  Future<void> takeScreenshot(String name) async {
    await manager.start();
    final boundary = firstRenderObject(find.byType(RepaintBoundary))
        as RenderRepaintBoundary;
    final image = await boundary.toImage();
    final byteData = await image.toByteData(format: ImageByteFormat.png);
    final pngBytes = byteData!.buffer.asUint8List();
    await manager.send('screenshot', pngBytes.join(','));
    await manager.done();
  }

  Future<void> expectVisible(String text) async {
    await manager.start();
    try {
      final finder = await _findOrWait(text);
      if (finder.evaluate().isEmpty) {
        throw Exception('Could not find $text');
      }
      await manager.done();
    } catch (err) {
      await manager.fail();
    }
  }

  Future<void> expectNotVisible(String text) async {
    await manager.start();
    try {
      final finder = await _findOrWait(text);
      if (finder.evaluate().isNotEmpty) {
        throw Exception('Found $text');
      }
      await manager.done();
    } catch (err) {
      await manager.fail();
    }
  }

  Future<void> tapOn(String text) async {
    await manager.start();
    try {
      await tap(await _findOrWait(text));
      await pumpAndSettle();
      await manager.done();
    } catch (err) {
      await manager.fail();
    }
  }

  Future<void> inputText(String text) async {
    await manager.start();
    final chars = <String>[];
    for (final char in text.split('')) {
      chars.add(char);
      testTextInput.enterText(chars.join());
      await pumpAndSettle();
    }
    await manager.done();
  }

  Future<Finder> _findOrWait(
    String text, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    return TestAsyncUtils.guard(() async {
      final regexp = RegExp(text);
      final finder = find.bySemanticOrText(regexp);

      // "Borrowed" from Patrol:
      // https://github.com/leancodepl/patrol/blob/56cdba8a9abbfa76fe5603c82fbbb2143cf8e79c/packages/patrol/lib/src/custom_finders/patrol_tester.dart#L276
      final end = binding.clock.now().add(timeout);
      while (finder.hitTestable().evaluate().isEmpty) {
        final now = binding.clock.now();
        if (now.isAfter(end)) {
          throw Exception('Timeout waiting for $text');
        }

        await pump(const Duration(milliseconds: 100));
      }

      return finder;
    });
  }
}

extension on CommonFinders {
  Finder bySemanticOrText(RegExp pattern, {bool skipOffstage = true}) {
    if (WidgetsBinding.instance.pipelineOwner.semanticsOwner == null) {
      throw StateError(
        'Semantics are not enabled. '
        'Make sure to call tester.ensureSemantics() before using '
        'this finder, and call dispose on its return value after.',
      );
    }

    return _FindBySemanticOrText(pattern, skipOffstage: skipOffstage);
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
      return Completer<void>().future;
    }
    final message = 'fluttium:$action:$data;';

    const maxLength = 800;
    for (var i = 0; i < message.length; i += maxLength) {
      final offset = i + maxLength;
      final piece = message.substring(
        i,
        offset >= message.length ? message.length : offset,
      );
      debugPrint(piece);
    }
  }
}

class _FindBySemanticOrText extends Finder {
  _FindBySemanticOrText(
    this.pattern, {
    super.skipOffstage,
  });

  final RegExp pattern;

  @override
  String get description => 'semantic or text containing $pattern';

  @override
  Iterable<Element> apply(Iterable<Element> candidates) {
    var foundMatch = false;

    return candidates.where((Element element) {
      // If we've already found a match, we can skip the rest of the elements.
      if (foundMatch) return false;

      // Multiple elements can have the same renderObject, we want the "owner"
      // of the renderObject, i.e. the RenderObjectElement.
      if (element is! RenderObjectElement) return false;

      var text = element.renderObject.debugSemantics?.label;
      if (text == null) {
        final widget = element.widget;
        if (widget is Tooltip) {
          text = widget.message;
        } else if (widget is EditableText) {
          text = widget.controller.text;
        } else if (widget is Text) {
          if (widget.data != null) {
            text = widget.data;
          } else {
            assert(
              widget.textSpan != null,
              'Text widget must have data or textSpan',
            );
            text = widget.textSpan!.toPlainText();
          }
        } else if (widget is RichText) {
          text = widget.text.toPlainText();
        }

        if (text == null) return false;
      }

      return foundMatch = pattern.hasMatch(text);
    });
  }
}
