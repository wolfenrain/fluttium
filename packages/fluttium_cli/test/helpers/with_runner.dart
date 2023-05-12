import 'dart:async';

import 'package:fluttium_cli/src/command_runner.dart';
import 'package:mason/mason.dart';
import 'package:mocktail/mocktail.dart';
import 'package:process/process.dart';
import 'package:pub_updater/pub_updater.dart';

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
  ) runnerFn,
) {
  return _overridePrint((printLogs) async {
    final logger = _MockLogger();
    final pubUpdater = _MockPubUpdater();
    final progressLogs = <String>[];
    final processManager = _MockProcessManager();

    final commandRunner = FluttiumCommandRunner(
      logger: logger,
      pubUpdater: pubUpdater,
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
    when(
      () => pubUpdater.isUpToDate(
        packageName: any(named: 'packageName'),
        currentVersion: any(named: 'currentVersion'),
      ),
    ).thenAnswer((_) => Future.value(true));

    await runnerFn(commandRunner, logger, printLogs, processManager);
  });
}
