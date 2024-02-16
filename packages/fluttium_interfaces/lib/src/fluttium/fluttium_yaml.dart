import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:fluttium_interfaces/src/fluttium/fluttium.dart';
import 'package:yaml/yaml.dart';

/// {@template fluttium_yaml}
/// Fluttium configuration yaml which contains information for the Fluttium CLI
/// that it uses to run user flows.
/// {@endtemplate}
class FluttiumYaml extends Equatable {
  /// {@macro fluttium_yaml}
  const FluttiumYaml({
    required this.environment,
    this.actions = const {},
    this.driver = const DriverConfiguration(),
  });

  /// {@macro fluttium_yaml}
  ///
  /// Loads the configuration from a `fluttium.yaml` file.
  factory FluttiumYaml.fromData(String data) {
    final yaml = json.decode(
      json.encode(loadYaml(data)),
    ) as Map<String, dynamic>;

    return FluttiumYaml(
      environment: FluttiumEnvironment.fromJson(
        yaml['environment'] as Map<String, dynamic>? ?? {},
      ),
      actions: {
        for (final entry
            in (yaml['actions'] as Map<String, dynamic>? ?? {}).entries)
          entry.key: ActionLocation.fromJson(entry.value),
      },
      driver: DriverConfiguration.fromJson(
        yaml['driver'] as Map<String, dynamic>? ?? {},
      ),
    );
  }

  /// The environment of the configuration.
  final FluttiumEnvironment environment;

  /// The configuration for the driver.
  final DriverConfiguration driver;

  /// The actions to install to run the flow.
  final Map<String, ActionLocation> actions;

  @override
  List<Object?> get props => [environment, driver, actions];

  /// Copy the configuration to a new instance with optional overrides.
  FluttiumYaml copyWith({
    FluttiumEnvironment? environment,
    Map<String, ActionLocation>? actions,
    DriverConfiguration? driver,
  }) {
    return FluttiumYaml(
      environment: environment ?? this.environment,
      actions: actions ?? this.actions,
      driver: driver ?? this.driver,
    );
  }

  /// Static constant for Fluttium configuration file name.
  static const file = 'fluttium.yaml';
}
