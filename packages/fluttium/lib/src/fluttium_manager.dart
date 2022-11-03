import 'dart:async';

import 'package:flutter/widgets.dart';

/// {@template fluttium_manager}
/// Communication layer between the Fluttium runner and the driver.
/// {@endtemplate}
class FluttiumManager {
  bool _hasFailed = false;

  /// Indicate that a step has started.
  Future<void> start() => send('start');

  /// Indicate that a step has completed.
  Future<void> done() => send('done');

  /// Indicate that a step has failed.
  Future<void> fail() async {
    await send('fail');
    _hasFailed = true;
  }

  /// Raw send method.
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
