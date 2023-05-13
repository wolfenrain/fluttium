import 'package:fluttium_interfaces/fluttium_interfaces.dart';
import 'package:test/test.dart';

void main() {
  group('FluttiumEnvironment', () {
    test('can be instantiated', () {
      final environment = FluttiumEnvironment(
        fluttium: VersionConstraint.parse('>=0.1.0 <0.2.0'),
      );

      expect(environment.fluttium, isA<VersionConstraint>());
      expect(
        environment.fluttium.allows(Version(0, 1, 0)),
        isTrue,
      );
      expect(
        environment.fluttium.allows(Version(0, 3, 0)),
        isFalse,
      );
    });

    test('fromJson', () {
      final environment = FluttiumEnvironment.fromJson(const {
        'fluttium': '>=0.1.0 <0.2.0',
      });

      expect(environment.fluttium, isA<VersionConstraint>());
      expect(
        environment.fluttium.allows(Version(0, 1, 0)),
        isTrue,
      );
      expect(
        environment.fluttium.allows(Version(0, 3, 0)),
        isFalse,
      );
    });

    test('equality', () {
      final environment = FluttiumEnvironment(
        fluttium: VersionConstraint.parse('>=0.1.0 <0.2.0'),
      );

      final otherEnvironment = FluttiumEnvironment(
        fluttium: VersionConstraint.parse('>=0.1.0 <0.2.0'),
      );

      expect(environment, equals(otherEnvironment));
    });
  });
}
