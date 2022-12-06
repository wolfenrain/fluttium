import 'package:equatable/equatable.dart';

/// {@template step_state}
/// The state of a step in the user flow.
/// {@endtemplate}
class StepState extends Equatable {
  /// {@macro step_state}
  StepState(
    this.description, {
    this.status = StepStatus.initial,
    Map<String, List<int>> files = const {},
    this.failReason,
  }) : files = Map.unmodifiable(files);

  /// The readable description of the step.
  final String description;

  /// The current status of the step.
  final StepStatus status;

  /// If [status] is [StepStatus.failed] this will contain the reason.
  final String? failReason;

  /// A list of files that were stored by the step
  final Map<String, List<int>> files;

  @override
  List<Object?> get props => [description, status, failReason, files];

  /// Copy this [StepState] with optional parameters.
  StepState copyWith({
    StepStatus? status,
    Map<String, List<int>>? files,
    String? failReason,
  }) {
    return StepState(
      description,
      status: status ?? this.status,
      files: files ?? this.files,
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
