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
    ProcessManager processManager,
  ) runnerFn, {
  PubUpdater Function()? pubUpdater,
  Logger Function()? logger,
  void Function(List<String> printLogs)? verifyPrints,
}) {
  return _overridePrint((printLogs) async {
    final log = logger != null ? logger.call() : _MockLogger();
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
      logger: log,
      pubUpdater: updater,
      processManager: processManager,
    );

    if (logger == null) {
      when(() => log.progress(any())).thenReturn(_MockProgress());
    }

    await runnerFn(commandRunner, log, processManager);
    verifyPrints?.call(printLogs);
  });
}
