import 'dart:io';

import 'package:mason/mason.dart';

Future<void> run(HookContext context) async {
  final installingActions = context.logger.progress('Installing actions');
  await Process.run(
    'flutter',
    ['pub', 'get'],
    runInShell: true,
    workingDirectory: Directory.current.path,
  );
  installingActions.complete();
}
