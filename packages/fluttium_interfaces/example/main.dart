import 'dart:io';

import 'package:fluttium_interfaces/fluttium_interfaces.dart';

void main() {
  final fluttium = FluttiumYaml(
    environment: FluttiumEnvironment(
      fluttium: VersionConstraint.parse('>=0.1.0 <0.2.0'),
    ),
  );

  stdout
    ..write('Supported fluttium version: ')
    ..writeln(fluttium.environment.fluttium);

  const flow = UserFlowYaml(
    description: 'A simple flow',
    steps: [
      UserFlowStep('pressOn', arguments: 'Increment'),
      UserFlowStep('expectVisible', arguments: {'text': '0'}),
    ],
  );

  stdout
    ..writeln()
    ..write('User flow: ')
    ..writeln(flow.description);

  for (final step in flow.steps) {
    stdout
      ..write('  Step: ')
      ..writeln(step.actionName)
      ..write('  Arguments: ')
      ..writeln(step.arguments);
  }
}
