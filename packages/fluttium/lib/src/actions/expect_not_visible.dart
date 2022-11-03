import 'package:fluttium/fluttium.dart';

/// {@template expect_not_visible}
/// Asserts that a node that matches the arguments is not visible.
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
  Future<bool> execute(FluttiumBinding worker) async {
    final node = await worker.find(
      text,
      timeout: Duration(milliseconds: timeout),
    );
    return node == null;
  }
}
