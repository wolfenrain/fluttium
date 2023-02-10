import 'dart:async';
import 'dart:convert';

import 'package:fluttium_protocol/fluttium_protocol.dart';

/// {@template listener}
/// Listens for [Message]s from the runner.
///
/// This is used by the driver, to listen for messages from the runner.
/// {@endtemplate}
class Listener {
  /// {@macro listener}
  ///
  /// The [stream] is the Process stdout of the runner, whoever supplies this
  /// stream has to ensure that Flutter's prefix is removed. The following regex
  /// can be used to remove the prefix:
  /// ```dart
  /// RegExp(r'^[I\/]*flutter[\s*\(\s*\d+\)]*: ');
  /// ```
  Listener(Stream<List<int>> stream)
      : _controller = StreamController<Message>() {
    messages = _controller.stream;

    final buffer = StringBuffer();
    var collectingMessageData = false;
    _subscription =
        stream.transform(utf8.decoder).transform(const LineSplitter()).listen(
      (event) {
        final data = event.trim();
        // Skip empty lines.
        if (data.isEmpty) return;

        // Skip if it doesn't start with a bracket.
        if (!data.startsWith('{')) return;

        try {
          final chunk = json.decode(data) as Map<String, dynamic>;
          if (!chunk.containsKey('type')) return;

          switch (chunk['type']) {
            case 'start':
              collectingMessageData = true;
              break;
            case 'data':
              if (!collectingMessageData) return;
              buffer.write(json.decode(chunk['data'] as String));
              break;
            case 'done':
              if (!collectingMessageData) return;
              collectingMessageData = false;

              _controller.add(
                Message.fromJson(
                  json.decode(buffer.toString()) as Map<String, dynamic>,
                ),
              );
              buffer.clear();
              break;
          }
        } catch (_) {}
      },
      onDone: close,
    );
  }

  final StreamController<Message> _controller;

  /// The stream of [Message]s emitted by the runner.
  late final Stream<Message> messages;

  late final StreamSubscription<String> _subscription;

  /// Closes the listener.
  Future<void> close() async {
    await _subscription.cancel();
    return _controller.close();
  }
}
