import 'dart:async';
import 'dart:io';

import 'package:fluttium_cli/src/command_runner.dart';
import 'package:fluttium_driver/fluttium_driver.dart';
import 'package:mason/mason.dart';
import 'package:mocktail/mocktail.dart';
import 'package:process/process.dart';
import 'package:pub_updater/pub_updater.dart';
import 'package:test/test.dart';

class _MockLogger extends Mock implements Logger {}

class _MockPubUpdater extends Mock implements PubUpdater {}

class _MockProgress extends Mock implements Progress {}

class _MockProcessManager extends Mock implements ProcessManager {}

void Function() _overridePrint(void Function(List<String>) fn) {
  return () {
    final printLogs = <String>[];
    final spec = ZoneSpecification(
      print: (_, __, ___, String msg) {
        printLogs.add(msg);
      },
    );

    return Zone.current
        .fork(specification: spec)
        .run<void>(() => fn(printLogs));
  };
}

void Function() withRunner(
  FutureOr<void> Function(
    FluttiumCommandRunner commandRunner,
    Logger logger,
    List<String> printLogs,
    ProcessManager processManager,
  ) runnerFn, {
  PubUpdater Function()? pubUpdater,
}) {
  return _overridePrint((printLogs) async {
    final logger = _MockLogger();
    final progressLogs = <String>[];
    final processManager = _MockProcessManager();

    when(
      () => processManager.run(any(that: equals(['flutter', '--version']))),
    ).thenAnswer((_) async {
      return ProcessResult(
        0,
        ExitCode.success.code,
        '''
Flutter ${FluttiumDriver.flutterVersionConstraint.min} • channel stable • https://github.com/flutter/flutter.git
Framework • revision AAAAAAAAAA (0 days ago) • 9999-12-31 00:00:00 -0700
Engine • revision AAAAAAAAAA
Tools • Dart 0.0.0 • DevTools 0.0.0
''',
        '',
      );
    });

    final updater = pubUpdater != null ? pubUpdater.call() : _MockPubUpdater();
    when(
      () => updater.isUpToDate(
        packageName: any(named: 'packageName'),
        currentVersion: any(named: 'currentVersion'),
      ),
    ).thenAnswer((_) => Future.value(true));

    final commandRunner = FluttiumCommandRunner(
      logger: logger,
      pubUpdater: updater,
      processManager: processManager,
    );

    final progress = _MockProgress();
    when(() => progress.complete(any())).thenAnswer((_) {
      if (_.positionalArguments.isEmpty) {
        return;
      }
      if (_.positionalArguments[0] != null) {
        progressLogs.add(_.positionalArguments[0] as String);
      }
    });
    when(() => logger.progress(any())).thenReturn(progress);

    await runnerFn(commandRunner, logger, printLogs, processManager);
  });
}
