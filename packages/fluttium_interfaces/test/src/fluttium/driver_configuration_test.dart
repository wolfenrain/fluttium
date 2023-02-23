// ignore_for_file: prefer_const_constructors

import 'package:fluttium_interfaces/fluttium_interfaces.dart';
import 'package:test/test.dart';

void main() {
  group('DriverConfiguration', () {
    test('can be instantiated', () {
      final driver = DriverConfiguration(
        mainEntry: 'lib/main_development.dart',
        flavor: 'development',
        dartDefines: const ['SOME_API_KEY=development'],
        deviceId: '1234',
      );

      expect(driver.mainEntry, equals('lib/main_development.dart'));
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

        expect(driver.mainEntry, equals('lib/main_development.dart'));
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

        expect(driver.mainEntry, equals('lib/main_development.dart'));
        expect(driver.flavor, equals('development'));
        expect(driver.dartDefines, equals(['SOME_API_KEY=development']));
        expect(driver.deviceId, equals('1234'));
      });

      test('can parse an empty json file', () {
        final driver = DriverConfiguration.fromJson(const {});

        expect(driver.mainEntry, equals('lib/main.dart'));
        expect(driver.flavor, isNull);
        expect(driver.dartDefines, isEmpty);
        expect(driver.deviceId, isNull);
      });
    });

    test('copyWith', () {
      final driver = DriverConfiguration(
        mainEntry: 'lib/main_development.dart',
        flavor: 'development',
        dartDefines: const ['SOME_API_KEY=development'],
        deviceId: '1234',
      );

      final identicalCopy = driver.copyWith();
      expect(identicalCopy, driver);

      final otherDriver = driver.copyWith(
        mainEntry: 'lib/main_production.dart',
        flavor: 'production',
        dartDefines: ['SOME_API_KEY=production'],
        deviceId: '5678',
      );

      expect(otherDriver.mainEntry, equals('lib/main_production.dart'));
      expect(otherDriver.flavor, equals('production'));
      expect(otherDriver.dartDefines, equals(['SOME_API_KEY=production']));
      expect(otherDriver.deviceId, equals('5678'));
    });

    test('equality', () {
      final driver = DriverConfiguration(
        mainEntry: 'lib/main_development.dart',
        flavor: 'development',
        dartDefines: const ['SOME_API_KEY=development'],
        deviceId: '1234',
      );

      final otherDriver = DriverConfiguration(
        mainEntry: 'lib/main_development.dart',
        flavor: 'development',
        dartDefines: const ['SOME_API_KEY=development'],
        deviceId: '1234',
      );

      expect(driver, equals(otherDriver));
    });
  });
}
