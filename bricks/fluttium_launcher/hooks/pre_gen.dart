import 'dart:io';

import 'package:mason/mason.dart';

typedef ProcessRunner = Future<ProcessResult> Function(
  String executable,
  List<String> arguments, {
  String workingDirectory,
  bool runInShell,
});

Future<void> run(HookContext context) => preGen(context);

Future<void> preGen(
  HookContext context, {
  Directory? directory,
  ProcessRunner runProcess = Process.run,
}) async {
  final installingTestRunner = context.logger.progress(
    'Installing test runner',
  );

  await runProcess(
    'flutter',
    ['pub', 'remove', 'fluttium_test_runner'],
    runInShell: true,
    workingDirectory: Directory.current.path,
  );

  await runProcess(
    'flutter',
    [
      'pub',
      'add',
      'fluttium_test_runner',
      '--dev',
      '--path',
      context.vars['runner_path'] as String,
    ],
    runInShell: true,
    workingDirectory: Directory.current.path,
  );

  installingTestRunner.complete();
}
