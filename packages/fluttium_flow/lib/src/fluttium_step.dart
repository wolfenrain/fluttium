import 'package:fluttium_flow/fluttium_flow.dart';
import 'package:yaml/yaml.dart';

/// {@template fluttium_step}
/// A [FluttiumStep] is a single step in a [FluttiumFlow].
///
/// The [action] is the action to perform. While the other properties are
/// optional and are used to configure the action.
/// {@endtemplate}
class FluttiumStep {
  /// {@macro fluttium_step}
  FluttiumStep(YamlNode step) {
    if (step is! YamlMap) {
      throw UnsupportedError('Step must be a map');
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

  /// The action to perform.
  late final FluttiumAction action;

  /// Depending on the action this is the text or label to select by or the
  /// text to type.
  late final String text;
}
