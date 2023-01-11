import 'dart:io';

import 'package:fluttium_driver/fluttium_driver.dart';
import 'package:fluttium_interfaces/fluttium_interfaces.dart';
import 'package:mason/mason.dart' hide GitPath;

Future<void> main() async {
  final driver = FluttiumDriver(
    logger: Logger(level: Level.verbose),
    configuration: const DriverConfiguration(
      // flavor: 'development',
      mainEntry: 'lib/main_development.dart',
      deviceId: 'macos',
    ),
    actions: {
      // 'tap': const ActionLocation(
      //   path: '../../some/path',
      // ),
      // 'swipe': ActionLocation(
      //   hosted: HostedPath(
      //     url: 'https://some.url',
      //     version: VersionConstraint.parse('0.1.0'),
      //   ),
      // ),
      // 'scroll': const ActionLocation(
      //   git: GitPath(
      //     url: 'https://some.url',
      //     ref: 'some-ref',
      //     path: 'some/path',
      //   ),
      // ),
    },
    projectDirectory: Directory('../../example'),
    userFlowFile: File('../../example/flows/progress_flow.yaml'),
  );

  driver.steps.listen((steps) {
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
          stdout
              .writeln(' 🔴 ${step.description} - reason: ${step.failReason}');
          break;
      }
    }
  });

  final subscription =
      ProcessSignal.sigint.watch().listen((_) => driver.quit());

  await driver.run();
  await subscription.cancel();
}
