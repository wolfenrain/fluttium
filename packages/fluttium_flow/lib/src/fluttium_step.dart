import 'package:fluttium_flow/src/fluttium_action.dart';
import 'package:yaml/yaml.dart';

/// {@template fluttium_step}
/// TODO:
/// {@endtemplate}
class FluttiumStep {
  /// {@macro fluttium_step}
  FluttiumStep(YamlNode step) {
    if (step is! YamlMap) {
      throw Exception('Step must be a map');
    }
    final map = step;
    final actionName = map.keys.first;
    final actionData = map[actionName];

    action = FluttiumAction.resolve(actionName as String);
    if (actionData is! YamlNode) {
      text = actionData.toString();
    } else {
      final data = actionData as YamlMap;
      text = data['text'] as String? ?? '';
    }
  }

  late final FluttiumAction action;

  late final String text;
}
