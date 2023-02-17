import 'package:fluttium/fluttium.dart';
import 'package:log_action/log_action.dart';

export 'src/log_action.dart';

/// Will be executed by Fluttium on startup.
void register(Registry registry) {
  registry.registerAction(
    'log',
    LogAction.new,
    shortHandIs: #text,
  );
}
