import 'dart:io';

import 'package:mason/mason.dart';
import 'package:path/path.dart';

Future<void> run(HookContext context) async {
  final projectDir = Directory(context.vars['projectPath']);

  final syncingFiles = context.logger.progress('Syncing project');
  for (final file in projectDir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => !f.path.endsWith('.dart'))) {
    final relative = file.path.replaceFirst('${projectDir.path}/', '');

    // Write to target file
    File(join(Directory.current.path, relative))
      ..deleteAndCreateSync(recursive: true)
      ..writeAsBytesSync(file.readAsBytesSync());
  }
  syncingFiles.complete();

  final cleaningProject = context.logger.progress('Cleaning project');
  await Process.run(
    'flutter',
    ['clean'],
    runInShell: true,
    workingDirectory: Directory.current.path,
  );
  cleaningProject.complete();

  final installingDeps = context.logger.progress('Installing dependencies');
  await Process.run(
    'flutter',
    ['pub', 'add', 'integration_test', '--sdk=flutter', '--dev'],
    runInShell: true,
    workingDirectory: Directory.current.path,
  );
  await Process.run(
    'flutter',
    ['pub', 'add', 'flutter_test', '--sdk=flutter', '--dev'],
    runInShell: true,
    workingDirectory: Directory.current.path,
  );
  await Process.run(
    'flutter',
    ['pub', 'get'],
    runInShell: true,
    workingDirectory: Directory.current.path,
  );
  installingDeps.complete();
}

extension on File {
  void deleteAndCreateSync({bool recursive = true}) {
    if (existsSync()) {
      deleteSync(recursive: recursive);
    }
    createSync(recursive: recursive);
  }
}
