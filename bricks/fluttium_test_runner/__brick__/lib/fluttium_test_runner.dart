import 'package:flutter/widgets.dart' hide Action;
import 'package:fluttium/fluttium.dart';
import 'package:fluttium_interfaces/fluttium_interfaces.dart';
{{#actions}}
import 'package:{{name}}/action.dart' as {{name.snakeCase()}};{{/actions}}

Future<void> run(WidgetsBinding binding) async{
  final registry = Registry();{{#actions}}
  {{name.snakeCase()}}.register(registry);{{/actions}}

  final tester = Tester(binding, registry);
  final actions = await tester.convert([{{#steps}}
    UserFlowStep.fromJson({{{step}}}),{{/steps}}
  ]);

  for (final action in actions) {
    await action();
  }
}
