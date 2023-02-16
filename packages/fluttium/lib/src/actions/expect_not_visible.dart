import 'package:fluttium/fluttium.dart';

/// {@template expect_not_visible}
/// Asserts that a node that matches the arguments is not visible.
///
/// This action can be invoked either using the short-hand version:
///
/// ```yaml
/// - expectNotVisible: "Hello World"
/// ```
///
/// Or using the verbose version:
///
/// ```yaml
/// - expectNotVisible:
///     text: "Hello World"
///     timeout: 1000
/// ```
/// {@endtemplate}
class ExpectNotVisible extends Action {
  /// {@macro expect_not_visible}
  const ExpectNotVisible({
    required this.text,
    this.timeout = 500,
  });

  /// The text to search for.
  final String text;

  /// The timeout to wait for the node to be not visible in milliseconds.
  final int timeout;

  @override
  Future<bool> execute(Tester tester) async {
    final node = await tester.find(
      text,
      timeout: Duration(milliseconds: timeout),
    );
    return node == null;
  }

  @override
  String description() => 'Expect not visible "$text"';
}
