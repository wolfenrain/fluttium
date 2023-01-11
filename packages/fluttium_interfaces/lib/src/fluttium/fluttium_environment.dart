import 'package:equatable/equatable.dart';
import 'package:fluttium_interfaces/src/fluttium/fluttium.dart';

/// {@template fluttium_environment}
/// Represents the environment of a Fluttium configuration.
/// {@endtemplate}
class FluttiumEnvironment extends Equatable {
  /// {@macro fluttium_environment}
  const FluttiumEnvironment({
    required this.fluttium,
  });

  /// {@macro fluttium_environment}
  ///
  /// Converts a json map to a [FluttiumEnvironment].
  FluttiumEnvironment.fromJson(Map<String, dynamic> json)
      : fluttium = VersionConstraint.parse(json['fluttium'] as String);

  /// The version of Fluttium that is supported.
  final VersionConstraint fluttium;

  @override
  List<Object> get props => [fluttium];
}
