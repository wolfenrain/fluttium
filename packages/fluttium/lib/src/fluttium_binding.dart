import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' hide Action;
import 'package:fluttium/fluttium.dart';

/// {@template fluttium_binding}
/// TODO: Add documentation.
/// {@endtemplate}
class FluttiumBinding {
  /// {@macro fluttium_binding}
  const FluttiumBinding(this._binding, this._manager, this._registry);

  final FluttiumManager _manager;

  final WidgetsBinding _binding;

  final FluttiumRegistry _registry;

  SemanticsOwner get _semanticsOwner => _binding.pipelineOwner.semanticsOwner!;

  /// TODO: Add documentation.
  RenderObject get renderObject => _binding.renderViewElement!.renderObject!;

  /// Executes the step by creating an [Action] and passing the [arguments].
  Future<void> executeStep(String actionName, dynamic arguments) async {
    final action = _registry.getAction(actionName, arguments);

    await _manager.start();
    try {
      final result = await action.execute(this);
      if (result) {
        await _manager.done();
      } else {
        await _manager.fail();
      }
    } catch (err) {
      await _manager.fail();
    }
  }

  /// Store binary data.
  Future<void> storeFile(String fileName, Uint8List bytes) async {
    await _manager.send('store', bytes.join(','));
  }

  /// Dispatch an event to the targets found by a hit test on its position.
  void emitPointerEvent(PointerEvent event) =>
      _binding.handlePointerEvent(event);

  /// Dispatch a message to the platform.
  Future<void> emitPlatformMessage(String channel, ByteData? data) async {
    await _binding.defaultBinaryMessenger.handlePlatformMessage(
      channel,
      data,
      (ByteData? data) {},
    );
  }

  /// Pump the widget tree for a single frame.
  Future<void> pump({Duration? duration}) async {
    if (duration == null) {
      return _binding.endOfFrame;
    }

    final end = DateTime.now().add(duration);
    while (DateTime.now().isBefore(end)) {
      await _binding.endOfFrame;
    }
  }

  /// Pump the widget tree and wait for animations to complete.
  Future<void> pumpAndSettle({Duration? timeout}) async {
    final end = DateTime.now().add(timeout ?? const Duration(seconds: 10));
    do {
      if (DateTime.now().isAfter(end)) {
        throw Exception('_pumpAndSettle timed out');
      }
      await pump();
    } while (_binding.hasScheduledFrame);
  }

  /// Find a node that matches the given text.
  ///
  /// The [text] can be a [String] that can also be used as a [RegExp].
  Future<SemanticsNode?> find(String text, {Duration? timeout}) async {
    var nodes = _findNodes(_semanticsOwner.rootSemanticsNode!, text);

    final end = DateTime.now().add(timeout ?? const Duration(seconds: 10));
    while (nodes.isEmpty) {
      await pump();
      if (DateTime.now().isAfter(end)) {
        return null;
      }
      nodes = _findNodes(_semanticsOwner.rootSemanticsNode!, text);
    }

    return nodes.first;
  }

  List<SemanticsNode> _findNodes(SemanticsNode node, String text) {
    final nodes = <SemanticsNode>[];
    node.visitChildren((n) {
      // Add all descendants that match the pattern.
      if (!n.mergeAllDescendantsIntoThisNode) {
        nodes.addAll(_findNodes(n, text));
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
      ].any((value) => value == text || RegExp(text).hasMatch(value))) {
        nodes.add(n);
      }

      return true;
    });

    return nodes;
  }
}
