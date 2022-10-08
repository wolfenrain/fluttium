import 'package:fluttium_flow/fluttium_flow.dart';
import 'package:yaml/yaml.dart';

/// {@template fluttium_flow}
/// TODO:
/// {@endtemplate}
class FluttiumFlow {
  /// {@macro fluttium_flow}
  FluttiumFlow(String content) {
    final documents = content.split(RegExp(r'^---\s*$', multiLine: true));
    final metaData = loadYaml(documents.first) as YamlMap;
    description = metaData['description'] as String? ?? '';

    final rawSteps = loadYaml(documents.last) as YamlList;
    steps = [for (final step in rawSteps) FluttiumStep(step as YamlNode)];
  }

  late final String description;

  late final List<FluttiumStep> steps;
}
