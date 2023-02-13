import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:fluttium_interfaces/src/user_flow/user_flow.dart';
import 'package:yaml/yaml.dart';

/// {@template user_flow_yaml}
/// User flow yaml which contains information on the steps to run.
/// {@endtemplate}
class UserFlowYaml extends Equatable {
  /// {@macro user_flow_yaml}
  const UserFlowYaml({
    required this.description,
    required this.steps,
  });

  /// {@macro user_flow_yaml}
  ///
  /// Converts a json map to a [UserFlowYaml].
  factory UserFlowYaml.fromData(String data) {
    final documents = json.decode(
      json.encode(loadYamlDocuments(data).map((e) => e.contents).toList()),
    ) as List<dynamic>;
    final metaData = documents.first as Map<String, dynamic>;
    final stepData = documents.last as List<dynamic>;

    return UserFlowYaml(
      description: metaData['description'] as String? ?? '',
      steps: [
        for (final step in stepData.cast<Map<String, dynamic>>())
          UserFlowStep.fromJson(step)
      ],
    );
  }

  /// The description of the flow.
  final String description;

  /// The steps of the flow.
  final List<UserFlowStep> steps;

  @override
  List<Object> get props => [description, steps];
}
