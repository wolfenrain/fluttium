import 'package:fluttium_driver/fluttium_driver.dart';
import 'package:fluttium_interfaces/fluttium_interfaces.dart';
import 'package:mason/mason.dart';

/// {@template printer}
/// Wrapper around [logger] to allow for different printing outputs of the test
/// command.
/// {@endtemplate}
abstract class Printer {
  /// {@macro printer}
  Printer(this.logger);

  final Logger logger;

  void print(
    List<StepState> steps,
    UserFlowYaml userFlow, {
    required bool watch,
  });

  void done();
}
