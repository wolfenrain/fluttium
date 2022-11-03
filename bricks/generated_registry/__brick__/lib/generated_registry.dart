import 'package:fluttium/fluttium.dart';
{{#actions}}
import 'package:{{action}}/action.dart' as {{action.snakeCase()}};{{/actions}}

FluttiumRegistry generatedRegistry() {
  final registry = FluttiumRegistry();
  {{#actions}}
  {{action.snakeCase()}}.register(registry);{{/actions}}
}
