import 'package:clock/clock.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' hide Action;
import 'package:fluttium/fluttium.dart';

/// {@template fluttium_tester}
/// The tester that is used to execute the actions in a flow file.
/// {@endtemplate}
class FluttiumTester {
  /// {@macro fluttium_tester}
  const FluttiumTester(this._binding, this._stateManager, this._registry);

  final FluttiumStateManager _stateManager;

  final WidgetsBinding _binding;

  final FluttiumRegistry _registry;

  SemanticsOwner get _semanticsOwner => _binding.pipelineOwner.semanticsOwner!;

  /// TODO: Add documentation.
  RenderObject get renderObject => _binding.renderViewElement!.renderObject!;

  /// Executes the step by creating an [Action] and passing the [arguments].
  Future<void> executeStep(String actionName, dynamic arguments) async {
    try {
      await _stateManager.start();

      final action = _registry.getAction(actionName, arguments);
      if (await action.execute(this)) {
        return _stateManager.done();
      }
      return _stateManager.fail();
    } catch (err) {
      return _stateManager.fail();
    }
  }

  /// Store binary data with the given [fileName].
  Future<void> storeFile(String fileName, Uint8List bytes) async {
    await _stateManager.store(fileName, bytes);
  }

  /// Dispatch an event to the targets found by a hit test on its position.
  void emitPointerEvent(PointerEvent event) {
    return _binding.handlePointerEvent(event);
  }

  /// Dispatch a message to the platform.
  Future<void> emitPlatformMessage(String channel, ByteData? data) async {
    await _binding.defaultBinaryMessenger.handlePlatformMessage(
      channel,
      data,
      (ByteData? data) {},
    );
  }

  /// Pump the widget tree for the given [duration].
  ///
  /// If [duration] is null, it will pump for a single frame.
  Future<void> pump({Duration? duration}) async {
    if (duration == null) {
      return _binding.endOfFrame;
    }

    final end = clock.now().add(duration);
    while (clock.now().isBefore(end)) {
      await _binding.endOfFrame;
    }
  }

  /// Pump the widget tree and wait for animations to complete.
  Future<void> pumpAndSettle({Duration? timeout}) async {
    final end = clock.now().add(timeout ?? const Duration(seconds: 10));
    do {
      if (clock.now().isAfter(end)) {
        throw Exception('pumpAndSettle timed out');
      }
      await pump();
    } while (_binding.hasScheduledFrame);
  }

  /// Find a node that matches the given text.
  ///
  /// The [text] can be a [String] that can also be used as a [RegExp].
  Future<SemanticsNode?> find(String text, {Duration? timeout}) async {
    var nodes = _findNodes(_semanticsOwner.rootSemanticsNode!, text);

    final end = clock.now().add(timeout ?? const Duration(seconds: 10));
    while (nodes.isEmpty) {
      await pump();
      if (clock.now().isAfter(end)) {
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
