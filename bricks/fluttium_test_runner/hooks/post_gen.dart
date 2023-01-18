import 'dart:io';

import 'package:mason/mason.dart';

Future<void> run(HookContext context) async {
  final installingActions = context.logger.progress('Installing actions');
  final result = await Process.run(
    'flutter',
    ['pub', 'get'],
    runInShell: true,
    workingDirectory: Directory.current.path,
  );

  if (result.exitCode != 0) {
    throw Exception('Failed to install actions: ${result.stderr}}');
  }
  installingActions.complete();
}
