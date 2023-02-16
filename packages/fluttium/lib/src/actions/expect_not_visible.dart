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
class ExpectNotVisible extends ExpectVisible {
  /// {@macro expect_not_visible}
  const ExpectNotVisible({
    required super.text,
    super.timeout = 500,
  });

  @override
  Future<bool> execute(Tester tester) async => !await super.execute(tester);

  @override
  String description() => 'Expect not visible "$text"';
}
