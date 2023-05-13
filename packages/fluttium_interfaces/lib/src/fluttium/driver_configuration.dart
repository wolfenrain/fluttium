import 'package:equatable/equatable.dart';

/// {@template driver_configuration}
/// Configuration for a project that uses Fluttium.
/// {@endtemplate}
class DriverConfiguration extends Equatable {
  /// {@macro driver_configuration}
  const DriverConfiguration({
    this.target = 'lib/main.dart',
    this.flavor,
    this.dartDefines = const [],
    this.deviceId,
  });

  /// {@macro driver_configuration}
  ///
  /// Converts a json map to a [DriverConfiguration].
  factory DriverConfiguration.fromJson(Map<String, dynamic> json) {
    return DriverConfiguration(
      target: json['target'] as String? ??
          json['mainEntry'] as String? ??
          'lib/main.dart',
      flavor: json['flavor'] as String?,
      dartDefines: (json['dart_defines'] as List<dynamic>? ??
              json['dartDefines'] as List<dynamic>? ??
              [])
          .cast<String>(),
      deviceId: json['deviceId']?.toString(),
    );
  }

  /// The main entry-point of the application to use for the driver.
  final String target;

  /// The entrypoint of the application to use for the driver.
  @Deprecated('Use `target` instead')
  String get mainEntry => target;

  /// The flavor of the application to use for the driver.
  final String? flavor;

  /// The dart defines to use for the application.
  final List<String> dartDefines;

  /// The device id to use for the driver.
  final String? deviceId;

  @override
  List<Object?> get props => [target, flavor, dartDefines, deviceId];

  /// Copy the configuration to a new instance with optional overrides.
  DriverConfiguration copyWith({
    String? deviceId,
    String? target,
    @Deprecated('Use `target` instead') String? mainEntry,
    String? flavor,
    List<String>? dartDefines,
  }) {
    return DriverConfiguration(
      deviceId: deviceId ?? this.deviceId,
      target: target ?? mainEntry ?? this.target,
      flavor: flavor ?? this.flavor,
      dartDefines: dartDefines ?? this.dartDefines,
    );
  }
}
