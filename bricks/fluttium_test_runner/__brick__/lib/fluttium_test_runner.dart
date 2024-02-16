import 'package:flutter/widgets.dart' hide Action;
import 'package:fluttium/fluttium.dart';
import 'package:fluttium_interfaces/fluttium_interfaces.dart';
{{#actions}}
import 'package:{{name.snakeCase()}}/{{name.snakeCase()}}.dart' as {{name.snakeCase()}};{{/actions}}

Future<Tester> run(WidgetsBinding binding) async {
  final registry = Registry();{{#actions}}
  {{name.snakeCase()}}.register(registry);{{/actions}}

  return Tester(binding, registry);
}
