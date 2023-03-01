import 'dart:io';

void main() {
  final localSetup = '''
dependency_overrides:
  fluttium:
    path: ${Directory.current.uri.resolve('packages/fluttium').path}
  fluttium_protocol:
    path: ${Directory.current.uri.resolve('packages/fluttium_protocol').path}
  fluttium_interfaces:
    path: ${Directory.current.uri.resolve('packages/fluttium_interfaces').path}
''';

  File('example/pubspec_overrides.yaml').writeAsStringSync(localSetup);
  File('bricks/fluttium_test_runner/__brick__/pubspec_overrides.yaml')
      .writeAsStringSync(localSetup);
}
