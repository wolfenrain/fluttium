import 'dart:convert';
import 'dart:developer';

import 'package:clock/clock.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' hide Action;
import 'package:fluttium/fluttium.dart';

/// {@template tester}
/// The tester that is used to execute the actions in a flow file.
/// {@endtemplate}
class Tester {
  /// {@macro tester}
  Tester(this._binding, this._registry)
      : _semanticsHandle = _binding.ensureSemantics() {
    registerExtension(
      'ext.fluttium.ready',
      (method, parameters) async {
        try {
          // await ready();
          return ServiceExtensionResponse.result(
            json.encode({'ready': true}),
          );
        } catch (err) {
          return ServiceExtensionResponse.result(
            json.encode({'ready': false, 'reason': err}),
          );
        }
      },
    );

    registerExtension(
      'ext.fluttium.getActionDescription',
      (method, parameters) async {
        final action = _registry.getAction(
          parameters['name']!,
          json.decode(parameters['arguments']!),
        );
        return ServiceExtensionResponse.result(
          json.encode({'description': action.description()}),
        );
      },
    );

    registerExtension(
      'ext.fluttium.executeAction',
      (method, parameters) async {
        final action = _registry.getAction(
          parameters['name']!,
          json.decode(parameters['arguments']!),
        );
        try {
          _storedFiles.clear();
          final result = await action.execute(this);
          return ServiceExtensionResponse.result(
            json.encode({'success': result, 'files': _storedFiles}),
          );
        } catch (err) {
          return ServiceExtensionResponse.result(
            json.encode({'success': false, 'reason': err}),
          );
        }
      },
    );
  }

  final WidgetsBinding _binding;

  final SemanticsHandle _semanticsHandle;

  final Registry _registry;

  final Map<String, dynamic> _storedFiles = {};

  /// The files that were stored in the current action.
  Map<String, dynamic> get storedFiles => Map.unmodifiable(_storedFiles);

  SemanticsOwner get _semanticsOwner => _binding.pipelineOwner.semanticsOwner!;

  /// The current screen's media query information.
  MediaQueryData get mediaQuery =>
      MediaQueryData.fromView(_binding.platformDispatcher.views.first);

  /// Store binary data with the given [fileName].
  Future<void> storeFile(String fileName, List<int> bytes) async {
    _storedFiles[fileName] = base64.encode(bytes);
  }

  /// Dispatch an event to the targets found by a hit test on its position.
  void emitPointerEvent(PointerEvent event) {
    return _binding.handlePointerEvent(event);
  }

  /// Dispatch a message to the platform.
  void emitPlatformMessage(String channel, ByteData? data) {
    _binding.channelBuffers.push(channel, data, (data) {});
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
      ].any((value) => value == text || RegExp('^$text\$').hasMatch(value))) {
        nodes.add(n);
      }

      return true;
    });

    return nodes;
  }

  /// Retrieve the root repaint boundary.
  RenderRepaintBoundary? getRenderRepaintBoundary() {
    final renderObject = _binding.rootElement!.renderObject!;
    RenderRepaintBoundary? boundary;
    void find(RenderObject element) {
      if (boundary != null) return;

      if (element is! RenderRepaintBoundary) {
        return element.visitChildren(find);
      }
      boundary = element;
    }

    if (renderObject is! RenderRepaintBoundary) {
      renderObject.visitChildren(find);
    }
    return boundary;
  }

  /// Wait for the semantics tree to be fully build.
  Future<void> ready() async {
    while (_binding.pipelineOwner.semanticsOwner?.rootSemanticsNode == null) {
      await _binding.endOfFrame;
    }
  }

  /// Dispose the [Tester] and it's resources.
  void dispose() {
    _semanticsHandle.dispose();
  }
}
