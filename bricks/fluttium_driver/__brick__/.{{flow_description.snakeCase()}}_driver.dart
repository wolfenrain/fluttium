import 'dart:async';

import 'package:{{{project_name}}}/{{{mainEntry}}}' as app;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

void main() async {
  final binding = WidgetsFlutterBinding.ensureInitialized()
    ..setSemanticsEnabled(true);

  app.main();
  await binding.endOfFrame;

  final worker = FluttiumWorker(
    binding,
    FluttiumManager(),
  );

  {{#flow_steps}}
  {{{step}}}{{/flow_steps}}
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

class FluttiumWorker {
  const FluttiumWorker(this.binding, this.manager);

  final FluttiumManager manager;

  final WidgetsBinding binding;

  SemanticsOwner get semanticsOwner => binding.pipelineOwner.semanticsOwner!;

  RenderObject get renderObject => binding.renderViewElement!.renderObject!;

  Future<void> tapOn(String text) async {
    await manager.start();
    try {
      final node = await _findOrWait(text);
      semanticsOwner.performAction(node.id, SemanticsAction.tap);
      await _pumpAndSettle();
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
      await _enterText(chars.join());
      await _pumpAndSettle();
    }
    await manager.done();
  }

  Future<void> expectVisible(String text) async {
    await manager.start();
    try {
      await _findOrWait(text);
      await manager.done();
    } catch (err) {
      await manager.fail();
    }
  }

  Future<void> expectNotVisible(String text) async {
    await manager.start();
    try {
      await _findOrWait(text);
      await manager.fail();
    } catch (err) {
      await manager.done();
    }
  }

  Future<void> takeScreenshot(String name) async {
    await manager.start();

    RenderRepaintBoundary? boundary;
    void find(RenderObject element) {
      if (boundary != null) return;

      if (element is! RenderRepaintBoundary) {
        return element.visitChildren(find);
      }
      boundary = element;
    }

    renderObject.visitChildren(find);

    final image = await boundary!.toImage();
    final byteData = await image.toByteData(format: ImageByteFormat.png);
    final pngBytes = byteData!.buffer.asUint8List();
    await manager.send('screenshot', pngBytes.join(','));
    await manager.done();
  }

  Future<void> _enterText(String text) async {
    final value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );

    await binding.defaultBinaryMessenger.handlePlatformMessage(
      SystemChannels.textInput.name,
      SystemChannels.textInput.codec.encodeMethodCall(
        MethodCall(
          'TextInputClient.updateEditingState',
          <dynamic>[-1, value.toJSON()],
        ),
      ),
      (ByteData? data) {},
    );
  }

  Future<void> _pumpAndSettle() async {
    final end = DateTime.now().add(const Duration(seconds: 10));
    do {
      if (DateTime.now().isAfter(end)) {
        throw Exception('_pumpAndSettle timed out');
      }
      await binding.endOfFrame;
    } while (binding.hasScheduledFrame);
  }

  Future<SemanticsNode> _findOrWait(String text) async {
    var nodes = _findNodes(semanticsOwner.rootSemanticsNode!, RegExp(text));

    final end = DateTime.now().add(const Duration(seconds: 10));
    while (nodes.isEmpty) {
      await binding.endOfFrame;
      if (DateTime.now().isAfter(end)) {
        throw Exception('Timeout waiting for $text');
      }
      nodes = _findNodes(semanticsOwner.rootSemanticsNode!, RegExp(text));
    }

    return nodes.first;
  }

  List<SemanticsNode> _findNodes(SemanticsNode node, RegExp pattern) {
    final nodes = <SemanticsNode>[];
    node.visitChildren((n) {
      // Add all descendants that match the pattern.
      if (!n.mergeAllDescendantsIntoThisNode) {
        nodes.addAll(_findNodes(n, pattern));
      }

      // If the node is invisible or has the hidden flag, don't add it.
      if (n.isInvisible || n.hasFlag(SemanticsFlag.isHidden)) {
        return true;
      }

      // Check if the current node matches the pattern on any semantic values.
      // If it does, add it to the list.
      final data = n.getSemanticsData();
      if ([
        data.label,
        data.value,
        data.hint,
        data.tooltip,
      ].any(pattern.hasMatch)) {
        nodes.add(n);
      }

      return true;
    });

    return nodes;
  }
}
