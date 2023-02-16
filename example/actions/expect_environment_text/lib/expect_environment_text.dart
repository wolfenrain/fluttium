import 'package:expect_environment_text/expect_environment_text.dart';
import 'package:fluttium/fluttium.dart';

export 'src/expect_environment_text.dart';

/// Will be executed by Fluttium on startup.
void register(Registry registry) {
  registry.registerAction(
    'expectEnvironmentText',
    ExpectEnvironmentText.new,
  );
}
