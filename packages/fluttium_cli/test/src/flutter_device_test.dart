import 'package:fluttium_cli/src/flutter_device.dart';
import 'package:test/test.dart';

void main() {
  group('FlutterDevice', () {
    test('can be instantiated', () {
      final device = FlutterDevice({
        'id': 'id',
        'name': 'name',
        'isSupported': true,
        'targetPlatform': 'targetPlatform',
      });

      expect(device.id, 'id');
      expect(device.name, 'name');
      expect(device.isSupported, true);
      expect(device.targetPlatform, 'targetPlatform');
    });
  });
}
