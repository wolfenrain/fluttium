// ignore_for_file: prefer_const_constructors

import 'dart:convert';
import 'dart:io';

import 'package:fluttium_interfaces/fluttium_interfaces.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockFile extends Mock implements File {}

class _FakeEncoding extends Fake implements Encoding {}

void main() {
  group('FluttiumYaml', () {
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

actions:
  custom_action: ^0.1.0-dev.1
  some_other_action: 1.2.3
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
            mainEntry: 'lib/main_development.dart',
            flavor: 'development',
            dartDefines: const ['SOME_API_KEY=development'],
            deviceId: '1234',
          ),
        ),
      );

      expect(config.actions.length, equals(2));
      expect(
        config.actions,
        equals({
          'custom_action': ActionLocation(
            hosted: HostedPath(
              url: 'https://pub.dartlang.org',
              version: VersionConstraint.parse('^0.1.0-dev.1'),
            ),
          ),
          'some_other_action': ActionLocation(
            hosted: HostedPath(
              url: 'https://pub.dartlang.org',
              version: VersionConstraint.parse('1.2.3'),
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
        mainEntry: 'lib/main_development.dart',
        flavor: 'development',
        dartDefines: const ['SOME_API_KEY=development'],
        deviceId: '1234',
      );

      final actions = {
        'custom_action': ActionLocation(
          hosted: HostedPath(
            url: 'https://pub.dartlang.org',
            version: VersionConstraint.parse('^0.1.0-dev.1'),
          ),
        ),
        'some_other_action': ActionLocation(
          hosted: HostedPath(
            url: 'https://pub.dartlang.org',
            version: VersionConstraint.parse('1.2.3'),
          ),
        ),
      };

      final otherConfig = config.copyWith(
        environment: environment,
        driver: driver,
        actions: actions,
      );

      expect(config.environment, isNot(equals(environment)));
      expect(config.driver, isNot(equals(driver)));
      expect(config.actions, isNot(equals(actions)));
      expect(otherConfig.environment, equals(environment));
      expect(otherConfig.driver, equals(driver));
      expect(otherConfig.actions, equals(actions));
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
