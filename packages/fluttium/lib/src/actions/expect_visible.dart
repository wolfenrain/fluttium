import 'package:fluttium/fluttium.dart';

/// {@template expect_visible}
/// Asserts that a node that matches the arguments is visible.
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
  Future<bool> execute(FluttiumBinding worker) async {
    final node = await worker.find(
      text,
      timeout: timeout != null ? Duration(milliseconds: timeout!) : null,
    );
    return node != null;
  }
}
