import 'dart:io';
import 'package:path/path.dart' as path;

void main() {
  final localSetup = '''
dependency_overrides:
  fluttium:
    path: ${path.canonicalize(path.join(Directory.current.path, 'packages/fluttium'))}
  fluttium_protocol:
    path: ${path.canonicalize(path.join(Directory.current.path, 'packages/fluttium_protocol'))}
  fluttium_interfaces:
    path: ${path.canonicalize(path.join(Directory.current.path, 'packages/fluttium_interfaces'))}
''';

  File('example/pubspec_overrides.yaml').writeAsStringSync(localSetup);
  File('bricks/fluttium_test_runner/__brick__/pubspec_overrides.yaml')
      .writeAsStringSync(localSetup);
}
