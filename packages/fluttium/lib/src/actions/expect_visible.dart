import 'package:fluttium/fluttium.dart';

/// {@template expect_visible}
/// Asserts that a node that matches the arguments is visible.
///
/// This action can be invoked either using the short-hand version:
///
/// ```yaml
/// - expectVisible: "Hello World"
/// ```
///
/// Or using the verbose version:
///
/// ```yaml
/// - expectVisible:
///     text: "Hello World"
///     timeout: 1000
/// ```
/// {@endtemplate}
class ExpectVisible extends Action {
  /// {@macro expect_visible}
  const ExpectVisible({
    required this.text,
    this.timeout,
  });

  /// The text to search for.
  final String text;

  /// The timeout to wait for the node to be visible in milliseconds.
  final int? timeout;

  @override
  Future<bool> execute(Tester tester) async {
    final node = await tester.find(
      text,
      timeout: timeout != null ? Duration(milliseconds: timeout!) : null,
    );
    return node != null;
  }

  @override
  String description() => 'Expect visible "$text"';
}
