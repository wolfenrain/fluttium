// ignore_for_file: prefer_const_constructors

import 'package:fluttium_interfaces/fluttium_interfaces.dart';
import 'package:test/test.dart';

void main() {
  group('$DriverConfiguration', () {
    test('can be instantiated', () {
      final driver = DriverConfiguration(
        target: 'lib/main_development.dart',
        flavor: 'development',
        dartDefines: const ['SOME_API_KEY=development'],
        deviceId: '1234',
      );

      expect(driver.target, equals('lib/main_development.dart'));
      expect(driver.flavor, equals('development'));
      expect(driver.dartDefines, equals(['SOME_API_KEY=development']));
      expect(driver.deviceId, equals('1234'));
    });

    group('fromJson', () {
      test('can parse a json file', () {
        final driver = DriverConfiguration.fromJson(const {
          'target': 'lib/main_development.dart',
          'flavor': 'development',
          'dart_defines': [
            'SOME_API_KEY=development',
          ],
          'deviceId': '1234',
        });

        expect(driver.target, equals('lib/main_development.dart'));
        expect(driver.flavor, equals('development'));
        expect(driver.dartDefines, equals(['SOME_API_KEY=development']));
        expect(driver.deviceId, equals('1234'));
      });

      test('can parse a json file with deprecated values', () {
        final driver = DriverConfiguration.fromJson(const {
          'mainEntry': 'lib/main_development.dart',
          'flavor': 'development',
          'dartDefines': [
            'SOME_API_KEY=development',
          ],
          'deviceId': '1234',
        });

        expect(driver.target, equals('lib/main_development.dart'));
        expect(driver.flavor, equals('development'));
        expect(driver.dartDefines, equals(['SOME_API_KEY=development']));
        expect(driver.deviceId, equals('1234'));
      });

      test('can parse an empty json file', () {
        final driver = DriverConfiguration.fromJson(const {});

        expect(driver.target, equals('lib/main.dart'));
        expect(driver.flavor, isNull);
        expect(driver.dartDefines, isEmpty);
        expect(driver.deviceId, isNull);
      });
    });

    group('copyWith', () {
      test('can copy with no parameters', () {
        final driver = DriverConfiguration(
          target: 'lib/main_development.dart',
          flavor: 'development',
          dartDefines: const ['SOME_API_KEY=development'],
          deviceId: '1234',
        );

        final identicalCopy = driver.copyWith();
        expect(identicalCopy, driver);
      });

      test('can copy normally', () {
        final driver = DriverConfiguration(
          target: 'lib/main_development.dart',
          flavor: 'development',
          dartDefines: const ['SOME_API_KEY=development'],
          deviceId: '1234',
        );

        final otherDriver = driver.copyWith(
          target: 'lib/main_production.dart',
          flavor: 'production',
          dartDefines: ['SOME_API_KEY=production'],
          deviceId: '5678',
        );

        expect(otherDriver.target, equals('lib/main_production.dart'));
        expect(otherDriver.flavor, equals('production'));
        expect(otherDriver.dartDefines, equals(['SOME_API_KEY=production']));
        expect(otherDriver.deviceId, equals('5678'));
      });

      test('can copy using deprecated fields', () {
        final driver = DriverConfiguration(
          target: 'lib/main_development.dart',
          flavor: 'development',
          dartDefines: const ['SOME_API_KEY=development'],
          deviceId: '1234',
        );

        final otherDriver = driver.copyWith(
          // ignore: deprecated_member_use_from_same_package
          mainEntry: 'lib/main_production.dart',
          flavor: 'production',
          dartDefines: ['SOME_API_KEY=production'],
          deviceId: '5678',
        );

        // ignore: deprecated_member_use_from_same_package
        expect(otherDriver.mainEntry, equals('lib/main_production.dart'));
        expect(otherDriver.flavor, equals('production'));
        expect(otherDriver.dartDefines, equals(['SOME_API_KEY=production']));
        expect(otherDriver.deviceId, equals('5678'));
      });
    });

    test('equality', () {
      final driver = DriverConfiguration(
        target: 'lib/main_development.dart',
        flavor: 'development',
        dartDefines: const ['SOME_API_KEY=development'],
        deviceId: '1234',
      );

      final otherDriver = DriverConfiguration(
        target: 'lib/main_development.dart',
        flavor: 'development',
        dartDefines: const ['SOME_API_KEY=development'],
        deviceId: '1234',
      );

      expect(driver, equals(otherDriver));
    });
  });
}
