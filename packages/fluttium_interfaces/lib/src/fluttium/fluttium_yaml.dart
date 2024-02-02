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
    this.addons = const {},
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
      addons: {
        for (final entry in (yaml['addons'] as Map<String, dynamic>? ??
                yaml['actions'] as Map<String, dynamic>? ??
                {})
            .entries)
          entry.key: AddonLocation.fromJson(entry.value)
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

  /// The addons to install to run the flow.
  final Map<String, AddonLocation> addons;

  /// The addons to install to run the flow.
  @Deprecated('use addons instead')
  Map<String, AddonLocation> get actions => addons;

  @override
  List<Object?> get props => [environment, driver, addons];

  /// Copy the configuration to a new instance with optional overrides.
  FluttiumYaml copyWith({
    FluttiumEnvironment? environment,
    @Deprecated('use addons instead') Map<String, AddonLocation>? actions,
    Map<String, AddonLocation>? addons,
    DriverConfiguration? driver,
  }) {
    return FluttiumYaml(
      environment: environment ?? this.environment,
      addons: addons ?? this.addons,
      driver: driver ?? this.driver,
    );
  }

  /// Static constant for Fluttium configuration file name.
  static const file = 'fluttium.yaml';
}
