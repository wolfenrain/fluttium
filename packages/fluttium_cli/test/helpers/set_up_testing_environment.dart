import 'dart:io';

import 'package:path/path.dart' as path;

String testFixturesPath(Directory cwd, {String suffix = ''}) {
  return path.join(cwd.path, 'test_fixtures', suffix);
}

void setUpTestingEnvironment(Directory cwd, {String suffix = ''}) {
  try {
    final testDir = Directory(testFixturesPath(cwd, suffix: suffix));
    if (testDir.existsSync()) testDir.deleteSync(recursive: true);
    testDir.createSync(recursive: true);
    Directory.current = testDir.path;
  } catch (_) {}
}
