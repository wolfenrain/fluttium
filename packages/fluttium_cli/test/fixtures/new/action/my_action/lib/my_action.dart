import 'package:fluttium/fluttium.dart';
import 'package:my_action/src/register.dart';

export 'src/my_action.dart';

/// Will be executed by Fluttium on startup.
void register(Registry registry) {
    'myAction',
    MyAction.new,
    shortHandIs: #text,
  );
}
