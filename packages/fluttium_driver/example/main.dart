import 'dart:io';

import 'package:fluttium_driver/fluttium_driver.dart';
import 'package:fluttium_interfaces/fluttium_interfaces.dart';
import 'package:mason/mason.dart' hide GitPath;

Future<void> main() async {
  final driver = FluttiumDriver(
    logger: Logger(level: Level.verbose),
    configuration: const DriverConfiguration(
      flavor: 'development',
      mainEntry: 'lib/main_development.dart',
      deviceId: 'chrome',
    ),
    actions: {
      'expect_environment_text': const ActionLocation(
        path: 'actions/expect_environment_text',
      ),
    },
    projectDirectory: Directory('../../example'),
    userFlowFile: File('../../example/flows/progress_flow.yaml'),
  );

  final stepsSubscription = driver.steps.listen(
    (steps) {
      // clear the terminal
      stdout.write('\x1B[2J\x1B[0;0H\n');

      for (final step in steps) {
        switch (step.status) {
          case StepStatus.initial:
            stdout.writeln(' ⚪️ ${step.description}');
            break;
          case StepStatus.running:
            stdout.writeln(' 🟡 ${step.description}');
            break;
          case StepStatus.done:
            stdout.writeln(' 🟢 ${step.description}');
            break;
          case StepStatus.failed:
            stdout.writeln(
              ' 🔴 ${step.description} - reason: ${step.failReason}',
            );
            break;
        }
      }
    },
    onError: (Object err) {
      if (err is FatalDriverException) {
        stderr.writeln(' Fatal Driver Exception: ${err.reason}');
        return driver.quit();
      }
    },
  );

  final processSubscription =
      ProcessSignal.sigint.watch().listen((_) => driver.quit());

  await driver.run();
  await stepsSubscription.cancel();
  await processSubscription.cancel();
}
