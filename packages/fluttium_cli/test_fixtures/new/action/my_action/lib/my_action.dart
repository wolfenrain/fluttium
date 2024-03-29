import 'package:fluttium/fluttium.dart';
import 'package:my_action/my_action.dart';

export 'src/my_action.dart';

/// Will be executed by Fluttium on startup.
void register(Registry registry) {
  registry.registerAction(
    'myAction',
    MyAction.new,
    shortHandIs: #text,
  );
}
