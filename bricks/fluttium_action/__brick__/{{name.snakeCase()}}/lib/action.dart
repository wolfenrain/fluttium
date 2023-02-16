import 'package:fluttium/fluttium.dart';

/// {@template {{name.snakeCase()}}}
/// {{{description}}}
///
/// An action is immutable and it represents a step in the user flow.
///
/// This action can be invoked either using the short-hand version:
///
/// ```yaml
/// - {{name.camelCase()}}: "Hello World"
/// ```
///
/// Or using the verbose version:
///
/// ```yaml
/// - {{name.camelCase()}}:
///     text: "Hello World"
/// ```
/// {@endtemplate}
class {{name.pascalCase()}} extends Action {
  /// {@macro {{name.snakeCase()}}}
  const {{name.pascalCase()}}({
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
  String description() => '{{name.sentenceCase()}} "$text"';
}

/// Will be executed by Fluttium on startup.
void register(Registry registry) {
  registry.registerAction(
    '{{name.camelCase()}}',
    {{name.pascalCase()}}.new,
    shortHandIs: #text,
  );
}
