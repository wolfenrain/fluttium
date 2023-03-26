import 'package:fake_async/fake_async.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluttium/fluttium.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('$Scroll', () {
    late Tester tester;
    late SemanticsNode node;
    late SemanticsNode item;

    setUp(() {
      tester = MockTester();
      node = MockSemanticsNode();
      item = MockSemanticsNode();
      when(() => node.transform).thenReturn(Matrix4.identity());
      when(() => node.rect).thenReturn(
        Rect.fromCircle(center: Offset.zero, radius: 10),
      );

      when(
        () => tester.find(
          any(that: equals('node')),
          timeout: any(named: 'timeout'),
        ),
      ).thenAnswer((_) async => node);

      when(
        () => tester.find(
          any(that: equals('item')),
          timeout: any(named: 'timeout'),
        ),
      ).thenAnswer((_) async => item);

      when(() => tester.pump(duration: any(named: 'duration')))
          .thenAnswer((_) async {});
      when(() => tester.emitPointerEvent(any())).thenAnswer((_) async {});
    });

    setUpAll(() {
      registerFallbackValue(FakePointerEvent());
    });

    test('returns false if within is not found', () async {
      when(() => tester.find(any(that: equals('node'))))
          .thenAnswer((_) async => null);

      final scroll = Scroll(within: 'node', until: 'item');
      expect(await scroll.execute(tester), isFalse);

      verify(
        () => tester.find(
          any(that: equals('node')),
          timeout: any(named: 'timeout'),
        ),
      ).called(1);
    });

    test('returns true without scrolling if until is found directly', () async {
      final scroll = Scroll(within: 'node', until: 'item');
      expect(await scroll.execute(tester), isTrue);

      verify(
        () => tester.find(
          any(that: equals('node')),
          timeout: any(named: 'timeout'),
        ),
      ).called(1);
      verify(
        () => tester.find(
          any(that: equals('item')),
          timeout: any(named: 'timeout', that: equals(Duration.zero)),
        ),
      ).called(1);
      verifyNever(() => tester.emitPointerEvent(any()));
      verifyNever(() => tester.pump());
    });

    test('returns true with scrolling', () async {
      var firstCall = true;
      when(
        () => tester.find(
          any(that: equals('item')),
          timeout: any(named: 'timeout'),
        ),
      ).thenAnswer((_) async {
        if (firstCall) {
          firstCall = false;
          return null;
        }
        return item;
      });

      final scroll = Scroll(within: 'node', until: 'item');
      expect(await scroll.execute(tester), isTrue);

      verify(
        () => tester.find(
          any(that: equals('node')),
          timeout: any(named: 'timeout'),
        ),
      ).called(1);
      verify(
        () => tester.find(
          any(that: equals('item')),
          timeout: any(named: 'timeout', that: equals(Duration.zero)),
        ),
      ).called(2);
      verify(
        () => tester.emitPointerEvent(
          any(
            that: isPointerScollEvent(
              position: Offset.zero,
              scrollDelta: const Offset(0, 40),
            ),
          ),
        ),
      ).called(1);
      verify(() => tester.pump()).called(1);
    });

    test('returns false after timeout', () {
      when(
        () => tester.find(
          any(that: equals('item')),
          timeout: any(named: 'timeout'),
        ),
      ).thenAnswer((_) async => null);

      fakeAsync((async) {
        when(() => tester.pump()).thenAnswer((_) async {
          async.elapse(const Duration(seconds: 1));
        });

        final scroll = Scroll(within: 'node', until: 'item', timeout: 1000);
        final future = scroll.execute(tester);
        expect(future, completion(isFalse));

        async.flushMicrotasks();

        verify(() => tester.pump()).called(2);
      });
    });

    group('supports all directions', () {
      setUp(() {
        var firstCall = true;
        when(
          () => tester.find(
            any(that: equals('item')),
            timeout: any(named: 'timeout'),
          ),
        ).thenAnswer((_) async {
          if (firstCall) {
            firstCall = false;
            return null;
          }
          return item;
        });
      });

      test('down', () async {
        final scroll = Scroll(within: 'node', until: 'item');
        expect(await scroll.execute(tester), isTrue);

        verify(
          () => tester.emitPointerEvent(
            any(
              that: isPointerScollEvent(
                position: Offset.zero,
                scrollDelta: const Offset(0, 40),
              ),
            ),
          ),
        ).called(1);
      });

      test('up', () async {
        final scroll =
            Scroll(within: 'node', until: 'item', direction: AxisDirection.up);
        expect(await scroll.execute(tester), isTrue);

        verify(
          () => tester.emitPointerEvent(
            any(
              that: isPointerScollEvent(
                position: Offset.zero,
                scrollDelta: const Offset(0, -40),
              ),
            ),
          ),
        ).called(1);
      });

      test('left', () async {
        final scroll = Scroll(
          within: 'node',
          until: 'item',
          direction: AxisDirection.left,
        );
        expect(await scroll.execute(tester), isTrue);

        verify(
          () => tester.emitPointerEvent(
            any(
              that: isPointerScollEvent(
                position: Offset.zero,
                scrollDelta: const Offset(-40, 0),
              ),
            ),
          ),
        ).called(1);
      });

      test('right', () async {
        final scroll = Scroll(
          within: 'node',
          until: 'item',
          direction: AxisDirection.right,
        );
        expect(await scroll.execute(tester), isTrue);

        verify(
          () => tester.emitPointerEvent(
            any(
              that: isPointerScollEvent(
                position: Offset.zero,
                scrollDelta: const Offset(40, 0),
              ),
            ),
          ),
        ).called(1);
      });
    });

    test('Readable representation', () {
      final scroll = Scroll(
        within: 'node',
        until: 'item',
        direction: AxisDirection.left,
      );

      expect(
        scroll.description(),
        'Scroll left in "node" until "item" is found',
      );
    });
  });
}
