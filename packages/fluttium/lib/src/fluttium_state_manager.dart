import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:fluttium_flow/fluttium_flow.dart';

/// {@template fluttium_state_manager}
/// Communication layer between the Fluttium runner and the driver.
/// {@endtemplate}
class FluttiumStateManager {
  bool _hasFailed = false;

  /// Indicate that a step has started.
  Future<void> start() => _emit(FluttiumMessageType.start);

  /// Indicate that a step has completed.
  Future<void> done() => _emit(FluttiumMessageType.done);

  /// Store binary data with the given [fileName].
  Future<void> store(String fileName, Uint8List bytes) {
    return _emit(FluttiumMessageType.store, bytes.join(','));
  }

  /// Indicate that a step has failed.
  Future<void> fail() async {
    await _emit(FluttiumMessageType.fail);
    _hasFailed = true;
  }

  Future<void> _emit(FluttiumMessageType messageType, [String? data]) async {
    if (_hasFailed) return Completer<void>().future;
    final message = 'fluttium:${messageType.name}:$data;';

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
