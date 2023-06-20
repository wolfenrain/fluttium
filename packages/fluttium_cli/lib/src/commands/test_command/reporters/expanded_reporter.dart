import 'package:fluttium_cli/src/commands/test_command/reporters/reporters.dart';
import 'package:fluttium_driver/fluttium_driver.dart';
import 'package:mason/mason.dart';

class ExpandedReporter extends Reporter {
  ExpandedReporter(super.driver, {required super.watch, required this.logger});

  final Stopwatch _stopwatch = Stopwatch();

  final Logger logger;

  bool failed = false;

  UserFlowStepState? previousStep;

  @override
  void report(List<UserFlowStepState> steps) {
    if (!_stopwatch.isRunning) {
      _stopwatch.start();
    }
    final duration = _stopwatch.elapsed;

    final currentStep = steps.lastWhere(
      (step) => step.status != StepStatus.initial,
      orElse: () => steps.first,
    );
    if (steps.every((e) => e.status == StepStatus.done)) return;
    if (currentStep.status == StepStatus.done || failed) return;

    final index = steps.indexOf(currentStep);
    final buffer = StringBuffer()
      ..writeAll(['${_timeString(duration)} ', green.wrap('+$index'), ': ']);

    if (currentStep.status == StepStatus.failed) {
      failed = true;
      buffer.write(red.wrap(currentStep.description));
    } else {
      buffer.write(currentStep.description);
    }
    logger.info(buffer.toString());
  }

  /// Returns a representation of [duration] as `MM:SS`.
  String _timeString(Duration duration) {
    return "${duration.inMinutes.toString().padLeft(2, '0')}:"
        "${(duration.inSeconds % 60).toString().padLeft(2, '0')}";
  }
}
