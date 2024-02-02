// ignore_for_file: prefer_const_constructors

import 'package:fluttium_interfaces/fluttium_interfaces.dart';
import 'package:test/test.dart';

void main() {
  group('$AddonLocation', () {
    test('can be instantiated', () {
      final location = AddonLocation(
        hosted: HostedPath(
          url: 'https://pub.dartlang.org',
          version: VersionConstraint.parse('1.0.0'),
        ),
      );

      expect(location.hosted, isNotNull);
      expect(location.git, isNull);
      expect(location.path, isNull);
    });

    group('fromJson', () {
      test('creates hosted location when data is a string', () {
        final location = AddonLocation.fromJson('1.0.0');

        expect(location.hosted, isNotNull);
        expect(
          location.hosted!.version,
          equals(VersionConstraint.parse('1.0.0')),
        );
        expect(location.git, isNull);
        expect(location.path, isNull);
      });

      test('creates hosted location when data is a hosted map', () {
        final location = AddonLocation.fromJson(const {
          'hosted': 'https://my.custom.pub',
          'version': '1.0.0',
        });

        expect(location.hosted, isNotNull);
        expect(
          location.hosted!.version,
          equals(VersionConstraint.parse('1.0.0')),
        );
        expect(location.hosted!.url, equals('https://my.custom.pub'));
        expect(location.git, isNull);
        expect(location.path, isNull);
      });

      test('creates git location when data is a git map with a string', () {
        final location = AddonLocation.fromJson(const {
          'git': 'git@git.some.where/some/addon.git',
        });

        expect(location.hosted, isNull);
        expect(location.git, isNotNull);
        expect(location.git!.url, equals('git@git.some.where/some/addon.git'));
        expect(location.git!.ref, isNull);
        expect(location.git!.path, isNull);
        expect(location.path, isNull);
      });

      test('creates git location when data is a git map', () {
        final location = AddonLocation.fromJson(const {
          'git': {
            'url': 'git@git.some.where/some/addon.git',
            'ref': 'main',
            'path': 'some/path',
          }
        });

        expect(location.hosted, isNull);
        expect(location.git, isNotNull);
        expect(location.git!.url, equals('git@git.some.where/some/addon.git'));
        expect(location.git!.ref, equals('main'));
        expect(location.git!.path, equals('some/path'));
        expect(location.path, isNull);
      });

      test('creates path location when data is a path map', () {
        final location = AddonLocation.fromJson(const {
          'path': 'some/path',
        });

        expect(location.hosted, isNull);
        expect(location.git, isNull);
        expect(location.path, equals('some/path'));
      });

      test('throws when data is not a string or map', () {
        expect(
          () => AddonLocation.fromJson(1),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('throws when data is a map with unknown keys', () {
        expect(
          () => AddonLocation.fromJson(const {
            'unknown': 'some/path',
          }),
          throwsA(isA<UnsupportedError>()),
        );
      });
    });

    test('equality', () {
      final location = AddonLocation(
        hosted: HostedPath(
          url: 'https://pub.dartlang.org',
          version: VersionConstraint.parse('1.0.0'),
        ),
      );

      final otherLocation = AddonLocation(
        hosted: HostedPath(
          url: 'https://pub.dartlang.org',
          version: VersionConstraint.parse('1.0.0'),
        ),
      );

      expect(location, equals(otherLocation));
    });
  });

  group('HostedPath', () {
    test('can be instantiated', () {
      final path = HostedPath(
        url: 'https://pub.dartlang.org',
        version: VersionConstraint.parse('1.0.0'),
      );

      expect(path.url, equals('https://pub.dartlang.org'));
      expect(path.version, equals(VersionConstraint.parse('1.0.0')));
    });

    test('equality', () {
      final path = HostedPath(
        url: 'https://pub.dartlang.org',
        version: VersionConstraint.parse('1.0.0'),
      );

      final otherPath = HostedPath(
        url: 'https://pub.dartlang.org',
        version: VersionConstraint.parse('1.0.0'),
      );

      expect(path, equals(otherPath));
    });
  });

  group('GitPath', () {
    test('can be instantiated', () {
      final path = GitPath(
        url: 'git@git.some.where/some/addon.git',
        ref: 'main',
        path: 'some/path',
      );

      expect(path.url, equals('git@git.some.where/some/addon.git'));
      expect(path.ref, equals('main'));
      expect(path.path, equals('some/path'));
    });

    test('equality', () {
      final path = GitPath(
        url: 'git@git.some.where/some/addon.git',
        ref: 'main',
        path: 'some/path',
      );

      final otherPath = GitPath(
        url: 'git@git.some.where/some/addon.git',
        ref: 'main',
        path: 'some/path',
      );

      expect(path, equals(otherPath));
    });
  });
}
