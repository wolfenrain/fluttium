import 'package:equatable/equatable.dart';
import 'package:fluttium_interfaces/src/user_flow/user_flow.dart';

/// {@template user_flow_step}
/// A [UserFlowStep] is a single step in a [UserFlowYaml].
///
/// The [actionName] is the action to use and the [arguments] are the arguments
/// to pass to the action.
/// {@endtemplate}
class UserFlowStep extends Equatable {
  /// {@macro user_flow_step}
  const UserFlowStep(this.actionName, {required dynamic arguments})
      : arguments = arguments is num ? '$arguments' : arguments;

  /// {@macro user_flow_step}
  ///
  /// Converts a json map to a [UserFlowStep].
  factory UserFlowStep.fromJson(Map<String, dynamic> stepData) {
    final map = stepData;
    final actionName = map.keys.first;
    return UserFlowStep(actionName, arguments: map[actionName]);
  }

  /// The name of the action to use for this step.
  final String actionName;

  /// The arguments to pass to the action.
  final dynamic arguments;

  @override
  List<Object?> get props => [actionName, arguments];

  /// Converts [UserFlowStep] to a json map.
  Map<String, dynamic> toJson() => {actionName: arguments};
}
