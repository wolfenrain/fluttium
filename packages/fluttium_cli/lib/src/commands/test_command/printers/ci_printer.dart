import 'package:fluttium_cli/src/commands/test_command/printers/printers.dart';
import 'package:fluttium_driver/fluttium_driver.dart';
import 'package:fluttium_interfaces/fluttium_interfaces.dart';
import 'package:mason/mason.dart';

class CIPrinter extends Printer {
  CIPrinter(super.logger);

  Progress? _progress;

  bool failed = false;

  @override
  void print(
    List<StepState> steps,
    UserFlowYaml userFlow, {
    required bool watch,
  }) {
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
