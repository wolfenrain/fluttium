import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:fluttium_cli/src/commands/test_command/reporters/reporters.dart';
import 'package:fluttium_driver/fluttium_driver.dart';
import 'package:mason/mason.dart';

class PrettyReporter extends Reporter {
  PrettyReporter(super.driver, {required super.watch, required this.logger}) {
    if (!watch) return;

    if (!stdin.hasTerminal) {
      throw UnsupportedError('Watch provided but no terminal was attached.');
    }

    _echoMode = stdin.echoMode;
    _lineMode = stdin.lineMode;

    stdin
      ..echoMode = false
      ..lineMode = false
      ..listen((event) async {
        switch (utf8.decode(event).trim()) {
          case 'q':
            return driver.quit();
          case 'r':
            return driver.restart();
        }
      });
  }

  final Logger logger;

  late final bool _echoMode;
  late final bool _lineMode;

  @override
  void report(List<UserFlowStepState> steps) {
    // Reset the cursor to the top of the screen and clear the screen.
    logger.info('''
\u001b[0;0H\u001b[0J
  ${styleBold.wrap(driver.userFlow.description)}
''');

    // Render the steps.
    for (final step in steps) {
      switch (step.status) {
        case StepStatus.initial:
          logger.info('  🔲  ${step.description}');
        case StepStatus.running:
          logger.info('  ⏳  ${step.description}');
        case StepStatus.done:
          logger.info('  ✅  ${step.description}');
        case StepStatus.failed:
          logger.info('  ❌  ${step.description}');
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
  void done() {
    if (watch && stdin.hasTerminal) {
      stdin
        ..lineMode = _lineMode
        ..echoMode = _echoMode;
    }
  }

  @override
  FutureOr<void> error(Object err) {
    if (err is FatalDriverException) {
      logger.err(' Fatal driver exception occurred: ${err.reason}');
      return super.error(err);
    }
    logger.err('Unknown exception occurred: $err');
  }
}
