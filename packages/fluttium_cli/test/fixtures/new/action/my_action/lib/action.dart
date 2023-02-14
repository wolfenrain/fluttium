import 'package:fluttium/fluttium.dart';

/// {@template my_action}
/// A custom action for Fluttium.
/// 
/// An action is immutable and it represents a step in the user flow.
///
/// This action can be invoked either using the short-hand version:
/// 
/// ```yaml
/// - myAction: "Hello World"
/// ```
/// 
/// Or using the verbose version:
///
/// ```yaml
/// - myAction:
///   - text: "Hello World"
/// ```
/// {@endtemplate}
class MyAction extends Action {
  /// {@macro my_action}
  const MyAction({
    required this.text,
  });

  final String? text;

  /// Called when it executes the action in a flow file.
  @override
  Future<bool> execute(Tester tester) async {
    if (text == null) {
      return false;
    }

    if (!await ExpectVisible(text: text!).execute(tester)) {
      return false;
    }
    return true;
  }

  @override
  String description() => 'My action "$text"';
}

/// Will be executed by Fluttium on startup.
void register(Registry registry) {
  registry.registerAction(
    'myAction',
    MyAction.new,
    shortHandIs: #text,
  );
}
