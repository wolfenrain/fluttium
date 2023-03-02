import 'package:fluttium_cli/src/commands/test_command/reporters/reporters.dart';
import 'package:fluttium_driver/fluttium_driver.dart';
import 'package:mason/mason.dart';

class CompactReporter extends Reporter {
  CompactReporter(super.driver, {required super.watch, required this.logger}) {
    if (!watch) return;
    throw UnsupportedError('The compact reporter does not support watch mode.');
  }

  final Logger logger;

  Progress? _progress;

  bool failed = false;

  @override
  void report(List<StepState> steps) {
    final currentStep = steps.lastWhere(
      (step) => step.status != StepStatus.initial,
      orElse: () => steps.first,
    );
    if (steps.every((e) => e.status == StepStatus.done)) return;
    _progress ??= logger.progress('');

    final index = steps.indexOf(currentStep) + 1;
    _progress?.update('$index/${steps.length} ${currentStep.description}');

    if (currentStep.status == StepStatus.failed) {
      failed = true;
      _progress?.fail();
    }
  }

  @override
  void done() {
    if (failed) return;
    _progress?.complete();
  }
}
