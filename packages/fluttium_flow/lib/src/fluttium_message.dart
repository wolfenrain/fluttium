/// The different type of messages that can be sent from the user flow test.
enum FluttiumMessageType {
  /// A step has started.
  start,

  /// A step has completed.
  done,

  /// A step has failed.
  fail,

  /// Some data is being stored.
  store;

  /// Resolve the given [message] to a [FluttiumMessageType].
  static FluttiumMessageType resolve(String message) {
    return FluttiumMessageType.values.firstWhere(
      (msg) => msg.name == message,
      orElse: () => throw UnimplementedError('$message is not implemented'),
    );
  }
}
