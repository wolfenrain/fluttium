// ignore_for_file: prefer_const_constructors

import 'package:flutter_test/flutter_test.dart';
import 'package:fluttium/fluttium.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/helpers.dart';

void main() {
  group('$Wait', () {
    late Tester tester;

    setUp(() {
      tester = MockTester();
    });

    test('returns true if wait was successful', () async {
      final wait = Wait(milliseconds: 500);

      when(() => tester.pump(duration: any(named: 'duration')))
          .thenAnswer((_) async {});

      expect(await wait.execute(tester), isTrue);

      verify(
        () => tester.pump(
          duration: any(
            named: 'duration',
            that: equals(Duration(milliseconds: 500)),
          ),
        ),
      ).called(1);
    });

    test('returns false if duration is zero', () async {
      final wait = Wait();

      expect(await wait.execute(tester), isFalse);

      verifyNever(
        () => tester.pump(
          duration: any(
            named: 'duration',
            that: equals(Duration(milliseconds: 500)),
          ),
        ),
      );
    });

    group('Readable representation', () {
      test('simple', () {
        final wait = Wait(milliseconds: 500);

        expect(wait.description(), 'Wait 500 milliseconds');
      });

      test('complex', () {
        final wait = Wait(
          days: 1,
          hours: 2,
          minutes: 30,
          seconds: 30,
          milliseconds: 500,
          microseconds: 500,
        );

        expect(
          wait.description(),
          '''Wait 1 day, 2 hours, 30 minutes, 30 seconds, 500 milliseconds and 500 microseconds''',
        );
      });
    });
  });
}
