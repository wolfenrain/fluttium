import 'package:fluttium/fluttium.dart';

/// {@template expect_environment_text}
/// Check if the environment text label is set on the main screen.
///
/// This action can be invoked using the short-hand version:
///
/// ```yaml
/// - expectEnvironmentText:
/// ```
/// {@endtemplate}
class ExpectEnvironmentText extends Action {
  /// {@macro expect_environment_text}
  const ExpectEnvironmentText();

  /// Called when it executes the action in a flow file.
  @override
  Future<bool> execute(Tester tester) async {
    if (!await ExpectVisible(
      text: "Environment: (Development|Staging|Production|None){1}",
    ).execute(tester)) {
      return false;
    }
    return true;
  }

  @override
  String description() => 'Expect environment label to be set';
}

/// Will be executed by Fluttium on startup.
void register(Registry registry) {
  registry.registerAction(
    'expectEnvironmentText',
    ExpectEnvironmentText.new,
  );
}
