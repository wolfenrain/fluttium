import 'dart:io';

import 'package:fluttium_cli/src/commands/test_command/printers/printers.dart';
import 'package:fluttium_driver/fluttium_driver.dart';
import 'package:fluttium_interfaces/fluttium_interfaces.dart';
import 'package:mason/mason.dart';

class PrettyPrinter extends Printer {
  PrettyPrinter(super.logger);

  @override
  void print(
    List<StepState> steps,
    UserFlowYaml userFlow, {
    required bool watch,
  }) {
    // Reset the cursor to the top of the screen and clear the screen.
    logger.info('''
\u001b[0;0H\u001b[0J
  ${styleBold.wrap(userFlow.description)}
''');

    // Render the steps.
    for (final step in steps) {
      switch (step.status) {
        case StepStatus.initial:
          logger.info('  🔲  ${step.description}');
          break;
        case StepStatus.running:
          logger.info('  ⏳  ${step.description}');
          break;
        case StepStatus.done:
          logger.info('  ✅  ${step.description}');
          for (final file in step.files.entries) {
            logger.detail('Writing ${file.value.length} bytes to $file');
            File(file.key)
              ..createSync(recursive: true)
              ..writeAsBytesSync(file.value);
          }
          break;
        case StepStatus.failed:
          logger.info('  ❌  ${step.description}');
          break;
      }
    }

    logger.info('');
    if (watch) {
      logger.info('''
  ${styleDim.wrap('Press')} r ${styleDim.wrap('to restart the test.')}
  ${styleDim.wrap('Press')} q ${styleDim.wrap('to quit.')}''');
    }
  }

  @override
  void done() {}
}
