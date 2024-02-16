/// {@template fatal_driver_exception}
/// Exception thrown when there is a fatal exception
/// {@endtemplate}
@Deprecated('No longer being thrown by the driver')
class FatalDriverException implements Exception {
  /// {@macro fatal_driver_exception}
  @Deprecated('No longer being thrown by the driver')
  const FatalDriverException(this.reason);

  /// The reason of the exception.
  final String reason;

  @override
  String toString() => 'A fatal exception happened on the driver: $reason';
}
