import 'package:equatable/equatable.dart';
import 'package:fluttium_interfaces/fluttium_interfaces.dart';

/// {@macro user_flow_step_state}
@Deprecated('Use UserFlowStepState instead')
typedef StepState = UserFlowStepState;

/// {@template user_flow_step_state}
/// The state of a step in the user flow.
/// {@endtemplate}
class UserFlowStepState extends Equatable {
  /// {@macro user_flow_step_state}
  UserFlowStepState(
    this.step, {
    this.status = StepStatus.initial,
    this.description = '',
    @Deprecated(
      'Use the FluttiumDriver.files stream to watch for files to store',
    )
    Map<String, List<int>> files = const {},
    this.failReason,
    // ignore: deprecated_member_use_from_same_package
  }) : files = Map.unmodifiable(files);

  /// The step for which this state is.
  final UserFlowStep step;

  /// The readable description of the step.
  final String description;

  /// The current status of the step.
  final StepStatus status;

  /// If [status] is [StepStatus.failed] this will contain the reason.
  final String? failReason;

  /// A list of files that were stored by the step
  @Deprecated('Use the FluttiumDriver.files stream to watch for files to store')
  final Map<String, List<int>> files;

  @override
  List<Object?> get props => [
        step,
        description,
        status,
        failReason,
        // ignore: deprecated_member_use_from_same_package
        files,
      ];

  /// Copy this [UserFlowStepState] with optional parameters.
  UserFlowStepState copyWith({
    StepStatus? status,
    String? description,
    @Deprecated(
      'Use the FluttiumDriver.files stream to watch for files to store',
    )
    Map<String, List<int>>? files,
    String? failReason,
  }) {
    return UserFlowStepState(
      step,
      status: status ?? this.status,
      description: description ?? this.description,
      failReason: failReason ?? this.failReason,
    );
  }
}

/// The status of a step in the user flow.
enum StepStatus {
  /// The step has not been executed yet.
  initial,

  /// The step is currently executing.
  running,

  /// The step has been executed successfully.
  done,

  /// The step has failed.
  failed,
}
