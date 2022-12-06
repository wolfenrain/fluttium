import 'dart:io';

import 'package:mason/mason.dart';

Future<void> run(HookContext context) async {
  final uninstallingTestRunner = context.logger.progress(
    'Uninstalling test runner',
  );

  await Process.run(
    'flutter',
    ['pub', 'remove', 'fluttium_test_runner'],
    runInShell: true,
    workingDirectory: Directory.current.path,
  );

  uninstallingTestRunner.complete();
}
