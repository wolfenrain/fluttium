import 'dart:convert';

import 'package:equatable/equatable.dart';

/// {@template message}
/// A message that is sent from the Fluttium runner to the Fluttium driver.
/// {@endtemplate}
class Message extends Equatable {
  const Message._(this.type, this.data);

  /// {@macro message}
  ///
  /// Send when a [step] is announced.
  const Message.announce(String step) : this._(MessageType.announce, step);

  /// {@macro message}
  ///
  /// Send when a [step] has started.
  const Message.start(String step) : this._(MessageType.start, step);

  /// {@macro message}
  ///
  /// Send when a [step] has completed.
  const Message.done(String step) : this._(MessageType.done, step);

  /// {@macro message}
  ///
  /// Send when a [step] has failed with the given [reason].
  Message.fail(String step, {required String reason})
      : this._(MessageType.fail, [step, reason]);

  /// {@macro message}
  ///
  /// Send when a fatal exception has occurred.
  const Message.fatal(String reason) : this._(MessageType.fatal, reason);

  /// {@macro message}
  ///
  /// Send when some [data] is being stored with the given [fileName].
  Message.store(String fileName, List<int> bytes)
      : this._(MessageType.store, [fileName, bytes]);

  /// {@macro message}
  ///
  /// Create a [Message] from the given [data].
  Message.fromJson(Map<String, dynamic> data)
      : type = MessageType.values.firstWhere(
          (type) => type.name == data['type'],
          orElse: () => throw UnimplementedError(
            '${data['type']} is not implemented',
          ),
        ),
        data = data['data'] != null ? jsonDecode(data['data'] as String) : null;

  /// The type of the message.
  final MessageType type;

  /// The data of the message.
  ///
  /// Depending on the [type] this can be either:
  /// - start: [String]
  /// - done: [String]
  /// - fail: [List<String>] with the step and the reason
  /// - store: [List<dynamic>] with the file name and then list of bytes.
  final dynamic data;

  /// Convert the [Message] to a JSON map.
  Map<String, dynamic> toJson() => {
        'type': type.name,
        if (data != null) 'data': json.encode(data),
      };

  @override
  List<Object> get props => [type, data.toString()];
}

/// The different type of messages that can be sent from the user flow test.
enum MessageType {
  /// Announce a step.
  announce,

  /// A step has started.
  start,

  /// A step has completed.
  done,

  /// A step has failed.
  fail,

  /// A fatal message.
  fatal,

  /// Some data is being stored.
  store;
}
