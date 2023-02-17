import 'package:fluttium/fluttium.dart';

/// {@template log_action}
/// A simple log action for Fluttium.
///
/// An action is immutable and it represents a step in the user flow.
///
/// This action can be invoked either using the short-hand version:
///
/// ```yaml
/// - logAction: "Hello World"
/// ```
///
/// Or using the verbose version:
///
/// ```yaml
/// - logAction:
///     text: "Hello World"
/// ```
/// {@endtemplate}
class LogAction extends Action {
  /// {@macro log_action}
  const LogAction({
    required this.text,
  });

  final String text;

  @override
  Future<bool> execute(Tester tester) async {
    // It is no-op method as it main focus is to just log to the step state.
    return true;
  }

  @override
  String description() => 'Log: $text';
}
