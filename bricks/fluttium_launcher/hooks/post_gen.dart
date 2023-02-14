import 'dart:io';

import 'package:mason/mason.dart';

typedef ProcessRunner = Future<ProcessResult> Function(
  String executable,
  List<String> arguments, {
  String workingDirectory,
  bool runInShell,
});

// coverage:ignore-start
Future<void> run(HookContext context) => postGen(context);
// coverage:ignore-end

Future<void> postGen(
  HookContext context, {
  Directory? directory,
  ProcessRunner runProcess = Process.run,
}) async {
  final uninstallingTestRunner = context.logger.progress(
    'Uninstalling test runner',
  );

  await runProcess(
    'flutter',
    ['pub', 'remove', 'fluttium_test_runner'],
    runInShell: true,
    workingDirectory: Directory.current.path,
  );

  uninstallingTestRunner.complete();
}
