import 'dart:io';

import 'package:mason/mason.dart';

Future<void> run(HookContext context) async {
  final installingTestRunner = context.logger.progress(
    'Installing test runner',
  );

  await Process.run(
    'flutter',
    ['pub', 'remove', 'fluttium_test_runner'],
    runInShell: true,
    workingDirectory: Directory.current.path,
  );

  await Process.run(
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
