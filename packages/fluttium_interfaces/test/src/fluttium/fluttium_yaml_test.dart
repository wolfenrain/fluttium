// ignore_for_file: prefer_const_constructors

import 'dart:convert';

import 'package:fluttium_interfaces/fluttium_interfaces.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _FakeEncoding extends Fake implements Encoding {}

void main() {
  group('$FluttiumYaml', () {
    setUpAll(() {
      registerFallbackValue(_FakeEncoding());
    });

    test('can be instantiated', () {
      final config = FluttiumYaml(
        environment: FluttiumEnvironment(
          fluttium: VersionConstraint.parse('>=0.1.0-dev.1 <0.1.0'),
        ),
      );

      expect(config.environment, isA<FluttiumEnvironment>());
    });

    test('can construct from a file', () {
      final config = FluttiumYaml.fromData('''
environment:
  fluttium: ">=0.1.0-dev.1 <0.1.0"

driver:
  mainEntry: lib/main_development.dart
  flavor: development
  dartDefines:
    - SOME_API_KEY=development
  deviceId: 1234

addons:
  custom_addons: ^0.1.0-dev.1
  some_other_addon: 
    path: ../some_other_addon
  and_final_addon:
    git: 
      url: https://github.com/wolfenrain/fluttium.git
      path: addons/and_final_addon
      ref: development
''');

      expect(
        config.environment,
        equals(
          FluttiumEnvironment(
            fluttium: VersionConstraint.parse('>=0.1.0-dev.1 <0.1.0'),
          ),
        ),
      );

      expect(
        config.driver,
        equals(
          DriverConfiguration(
            target: 'lib/main_development.dart',
            flavor: 'development',
            dartDefines: const ['SOME_API_KEY=development'],
            deviceId: '1234',
          ),
        ),
      );

      expect(
        config.addons,
        equals({
          'custom_addon': AddonLocation(
            hosted: HostedPath(
              url: 'https://pub.dartlang.org',
              version: VersionConstraint.parse('^0.1.0-dev.1'),
            ),
          ),
          'some_other_addons': AddonLocation(
            path: '../some_other_addons',
          ),
          'and_final_addon': AddonLocation(
            git: GitPath(
              url: 'https://github.com/wolfenrain/fluttium.git',
              path: 'addons/and_final_addons',
              ref: 'development',
            ),
          ),
        }),
      );
    });

    test('is backwards compatible', () {
      final config = FluttiumYaml.fromData('''
environment:
  fluttium: ">=0.1.0-dev.1 <0.1.0"

driver:
  mainEntry: lib/main_development.dart
  flavor: development
  dartDefines:
    - SOME_API_KEY=development
  deviceId: 1234

actions:
  custom_addons: ^0.1.0-dev.1
  some_other_addon: 
    path: ../some_other_addon
  and_final_addon:
    git: 
      url: https://github.com/wolfenrain/fluttium.git
      path: addons/and_final_addon
      ref: development
''');

      expect(
        config.environment,
        equals(
          FluttiumEnvironment(
            fluttium: VersionConstraint.parse('>=0.1.0-dev.1 <0.1.0'),
          ),
        ),
      );

      expect(
        config.driver,
        equals(
          DriverConfiguration(
            target: 'lib/main_development.dart',
            flavor: 'development',
            dartDefines: const ['SOME_API_KEY=development'],
            deviceId: '1234',
          ),
        ),
      );

      expect(
        config.addons,
        equals({
          'custom_addon': AddonLocation(
            hosted: HostedPath(
              url: 'https://pub.dartlang.org',
              version: VersionConstraint.parse('^0.1.0-dev.1'),
            ),
          ),
          'some_other_addons': AddonLocation(
            path: '../some_other_addons',
          ),
          'and_final_addon': AddonLocation(
            git: GitPath(
              url: 'https://github.com/wolfenrain/fluttium.git',
              path: 'addons/and_final_addons',
              ref: 'development',
            ),
          ),
        }),
      );
    });

    test('copyWith', () {
      final config = FluttiumYaml(
        environment: FluttiumEnvironment(
          fluttium: VersionConstraint.parse('>=0.1.0-dev.1 <0.1.0'),
        ),
      );

      final identicalCopy = config.copyWith();
      expect(identicalCopy, config);

      final environment = FluttiumEnvironment(
        fluttium: VersionConstraint.parse('>=0.1.0-dev.16 <0.1.0'),
      );

      final driver = DriverConfiguration(
        target: 'lib/main_development.dart',
        flavor: 'development',
        dartDefines: const ['SOME_API_KEY=development'],
        deviceId: '1234',
      );

      final addons = {
        'custom_addon': AddonLocation(
          hosted: HostedPath(
            url: 'https://pub.dartlang.org',
            version: VersionConstraint.parse('^0.1.0-dev.1'),
          ),
        ),
        'some_other_addon': AddonLocation(
          hosted: HostedPath(
            url: 'https://pub.dartlang.org',
            version: VersionConstraint.parse('1.2.3'),
          ),
        ),
      };

      final otherConfig = config.copyWith(
        environment: environment,
        driver: driver,
        addons: addons,
      );

      expect(config.environment, isNot(equals(environment)));
      expect(config.driver, isNot(equals(driver)));
      expect(config.addons, isNot(equals(addons)));
      expect(otherConfig.environment, equals(environment));
      expect(otherConfig.driver, equals(driver));
      expect(otherConfig.addons, equals(addons));
    });

    test('equality', () {
      final config = FluttiumYaml(
        environment: FluttiumEnvironment(
          fluttium: VersionConstraint.parse('>=0.1.0-dev.1 <0.1.0'),
        ),
      );

      final otherConfig = FluttiumYaml(
        environment: FluttiumEnvironment(
          fluttium: VersionConstraint.parse('>=0.1.0-dev.1 <0.1.0'),
        ),
      );

      expect(config, equals(otherConfig));
    });
  });
}
