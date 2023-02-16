import 'package:fluttium/fluttium.dart';
import 'package:{{name.snakeCase()}}/src/register.dart';

export 'src/{{name.snakeCase()}}.dart';

/// Will be executed by Fluttium on startup.
void register(Registry registry) {
  registry.registerAction(
    '{{name.camelCase()}}',
    {{name.pascalCase()}}.new,
    shortHandIs: #text,
  );
}
