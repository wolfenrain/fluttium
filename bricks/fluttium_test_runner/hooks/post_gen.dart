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
  final installingActions = context.logger.progress('Installing actions');
  final result = await runProcess(
    'flutter',
    ['pub', 'get'],
    runInShell: true,
    workingDirectory: Directory.current.path,
  );

  if (result.exitCode != 0) {
    installingActions.fail();
    throw Exception('Failed to install actions: ${result.stderr}');
  }
  installingActions.complete();
}
