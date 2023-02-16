import 'package:fluttium/fluttium.dart';

/// {@template custom_action}
/// A custom action for Fluttium.
///
/// An action is immutable and it represents a step in the user flow.
///
/// This action can be invoked either using the short-hand version:
///
/// ```yaml
/// - customAction: "Hello World"
/// ```
///
/// Or using the verbose version:
///
/// ```yaml
/// - customAction:
///   - text: "Hello World"
/// ```
/// {@endtemplate}
class CustomAction extends Action {
  /// {@macro custom_action}
  const CustomAction({
    required this.text,
  });

  final String? text;

  /// Called when it executes the action in a flow file.
  @override
  Future<bool> execute(Tester tester) async {
    if (text == null) {
      return false;
    }

    if (await ExpectVisible(text: text!).execute(tester)) {
      return TapOn(text: text).execute(tester);
    }
    return false;
  }

  @override
  String description() => 'Custom action "$text"';
}

/// Will be executed by Fluttium on startup.
void register(Registry registry) {
  registry.registerAction(
    'customAction',
    CustomAction.new,
    shortHandIs: #text,
  );
}
