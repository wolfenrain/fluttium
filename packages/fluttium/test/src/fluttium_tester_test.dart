// ignore_for_file: prefer_const_constructors

import 'package:fake_async/fake_async.dart';
import 'package:flutter/material.dart' hide Action;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluttium/fluttium.dart';
import 'package:mocktail/mocktail.dart';

class _MockAction extends Mock implements Action {}

class _MockWidgetBinding extends Mock implements WidgetsBinding {}

class _MockFluttiumStateManager extends Mock implements FluttiumStateManager {}

class _MockFluttiumRegistry extends Mock implements FluttiumRegistry {}

class _MockBinaryMessenger extends Mock implements BinaryMessenger {}

class _MockPipelineOwner extends Mock implements PipelineOwner {}

class _MockSemanticsOwner extends Mock implements SemanticsOwner {}

class _FakeFluttiumTester extends Fake implements FluttiumTester {}

void main() {
  group('FluttiumTester', () {
    late FluttiumTester tester;
    late _MockAction action;
    late _MockWidgetBinding binding;
    late _MockFluttiumStateManager stateManager;
    late _MockFluttiumRegistry registry;
    late BinaryMessenger binaryMessenger;
    late SemanticsOwner semanticsOwner;

    setUp(() {
      action = _MockAction();
      binding = _MockWidgetBinding();
      stateManager = _MockFluttiumStateManager();
      registry = _MockFluttiumRegistry();
      binaryMessenger = _MockBinaryMessenger();
      semanticsOwner = _MockSemanticsOwner();

      tester = FluttiumTester(binding, stateManager, registry);

      final pipelineOwner = _MockPipelineOwner();
      when(() => binding.pipelineOwner).thenReturn(pipelineOwner);
      when(() => pipelineOwner.semanticsOwner).thenReturn(semanticsOwner);

      when(() => binding.defaultBinaryMessenger).thenReturn(binaryMessenger);

      when(() => registry.getAction(any(), any())).thenReturn(action);
      when(stateManager.start).thenAnswer((_) async {});
      when(stateManager.fail).thenAnswer((_) async {});
      when(stateManager.done).thenAnswer((_) async {});
    });

    setUpAll(() {
      registerFallbackValue(_FakeFluttiumTester());
      registerFallbackValue(Uint8List(0));
      registerFallbackValue(PointerDownEvent());
    });

    group('executeStep', () {
      test('retrieves and execute action correctly', () async {
        when(() => action.execute(any())).thenAnswer((_) async => true);

        await tester.executeStep('actionName', 'actionData');

        verify(stateManager.start).called(1);
        verify(
          () => registry.getAction(
            any(that: equals('actionName')),
            any<dynamic>(that: equals('actionData')),
          ),
        ).called(1);
        verify(() => action.execute(any(that: equals(tester)))).called(1);
        verify(stateManager.done).called(1);
      });

      test('fails if action is not found', () async {
        when(() => registry.getAction(any(), any())).thenAnswer((_) {
          throw Exception('Action not found');
        });

        await tester.executeStep('actionName', 'actionData');

        verify(stateManager.start).called(1);
        verify(stateManager.fail).called(1);
      });

      test('fails if action execution throws', () async {
        when(() => action.execute(any())).thenThrow(Exception('Action failed'));

        await tester.executeStep('actionName', 'actionData');

        verify(stateManager.start).called(1);
        verify(stateManager.fail).called(1);
      });

      test('fails if action execution returns false', () async {
        when(() => action.execute(any())).thenAnswer((_) async => false);

        await tester.executeStep('actionName', 'actionData');

        verify(stateManager.start).called(1);
        verify(stateManager.fail).called(1);
      });
    });

    test('storeFile', () async {
      when(() => stateManager.store(any(), any())).thenAnswer((_) async {});

      await tester.storeFile('fileName', Uint8List(0));

      verify(
        () => stateManager.store(
          any(that: equals('fileName')),
          any(that: equals(Uint8List(0))),
        ),
      ).called(1);
    });

    test('emitPointerEvent', () async {
      when(() => binding.handlePointerEvent(any())).thenAnswer((_) {});

      tester.emitPointerEvent(PointerDownEvent());

      verify(
        () => binding.handlePointerEvent(any(that: isA<PointerDownEvent>())),
      ).called(1);
    });

    test('emitPlatformMessage', () {
      when(() => binaryMessenger.handlePlatformMessage(any(), any(), any()))
          .thenAnswer((invocation) async {
        final callback = invocation.positionalArguments[2]
            as PlatformMessageResponseCallback;
        final bytes = invocation.positionalArguments[1] as ByteData;
        callback(bytes);
      });

      tester.emitPlatformMessage('channel', ByteData.sublistView(Uint8List(0)));

      verify(
        () => binaryMessenger.handlePlatformMessage(
          any(that: equals('channel')),
          any(
            that: isA<ByteData?>().having(
              (p0) => p0?.buffer.asUint8List().toList(),
              'buffer',
              equals(Uint8List(0)),
            ),
          ),
          any(that: isA<PlatformMessageResponseCallback>()),
        ),
      ).called(1);
    });

    group('pump', () {
      test('pump a single frame', () async {
        when(() => binding.endOfFrame).thenAnswer((_) async {});

        await tester.pump();

        verify(() => binding.endOfFrame).called(1);
      });

      test('pump for the given duration', () async {
        await FakeAsync().run((async) async {
          when(() => binding.endOfFrame).thenAnswer((_) async {
            async.elapse(Duration(milliseconds: 10));
          });

          await tester.pump(duration: Duration(milliseconds: 100));

          verify(() => binding.endOfFrame).called(10);
        });
      });
    });

    group('pumpAndSettle', () {
      setUp(() {
        when(() => binding.endOfFrame).thenAnswer((_) async {});
      });

      test('pump until no new frame is left', () async {
        var firstFrame = true;
        when(() => binding.hasScheduledFrame).thenAnswer((_) {
          if (firstFrame) {
            return !(firstFrame = false);
          }
          return false;
        });

        await tester.pumpAndSettle();

        verify(() => binding.hasScheduledFrame).called(2);
        verify(() => binding.endOfFrame).called(2);
      });

      test('throws exception on timeout', () {
        when(() => binding.hasScheduledFrame).thenAnswer((_) => true);

        expect(
          () => tester.pumpAndSettle(timeout: Duration(milliseconds: 10)),
          throwsA(isA<Exception>()),
        );
      });
    });
  });
}
