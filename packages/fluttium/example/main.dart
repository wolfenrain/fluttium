import 'package:fluttium/fluttium.dart';

/// {@template custom_action}
/// A custom action for Fluttium.
///
/// An action is immutable and an instance of an action represents a step in
/// the user flow.
///
/// The syntax for this action is as followed:
///
/// ```yaml
/// - customAction:
///   - text: "Hello World"
/// ```
class CustomAction extends Action {
  const CustomAction({
    required this.text,
  });

  final String? text;

  /// Called when it executes the action in a flow file.
  @override
  Future<bool> execute(FluttiumBinding worker) async {
    if (text == null) {
      return false;
    }

    if (await ExpectVisible(text: text!).execute(worker)) {
      return TapOn(text: text).execute(worker);
    }
    return false;
  }
}

/// Will be executed by Fluttium on startup.
void register(FluttiumRegistry registry) {
  registry.registerAction(
    'customAction',
    CustomAction.new,
    shortHandIs: #text,
  );
}
