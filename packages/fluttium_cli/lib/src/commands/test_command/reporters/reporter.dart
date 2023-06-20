import 'dart:async';

import 'package:fluttium_driver/fluttium_driver.dart';

/// {@template reporter}
/// Reporter class for the output of the test command.
/// {@endtemplate}
abstract class Reporter {
  /// {@macro reporter}
  Reporter(this.driver, {required this.watch});

  final FluttiumDriver driver;

  final bool watch;

  void report(List<UserFlowStepState> steps);

  void done() {}

  FutureOr<void> error(Object err) {
    if (err is FatalDriverException) {
      return driver.quit();
    }
  }
}
