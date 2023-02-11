// ignore_for_file: prefer_const_constructors

import 'package:fake_async/fake_async.dart';
import 'package:flutter/material.dart' hide Action;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluttium/fluttium.dart';
import 'package:fluttium_interfaces/fluttium_interfaces.dart';
import 'package:fluttium_protocol/fluttium_protocol.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/helpers.dart';

class _MockAction extends Mock implements Action {}

class _MockWidgetBinding extends Mock implements WidgetsBinding {}

class _MockEmitter extends Mock implements Emitter {}

class _MockRegistry extends Mock implements Registry {}

class _MockBinaryMessenger extends Mock implements BinaryMessenger {}

class _MockPipelineOwner extends Mock implements PipelineOwner {}

class _MockSemanticsOwner extends Mock implements SemanticsOwner {}

class _MockElement extends Mock
    with DiagnosticableToStringMixin
    implements Element {}

class _FakeTester extends Fake implements Tester {}

class _MockSemanticsData extends Mock
    with DiagnosticableToStringMixin
    implements SemanticsData {}

void main() {
  group('Tester', () {
    late Tester tester;
    late Action action;
    late WidgetsBinding binding;
    late Emitter emitter;
    late Registry registry;
    late BinaryMessenger binaryMessenger;

    setUp(() {
      action = _MockAction();
      binding = _MockWidgetBinding();
      emitter = _MockEmitter();
      registry = _MockRegistry();
      binaryMessenger = _MockBinaryMessenger();

      tester = Tester(binding, registry, emitter: emitter);

      when(() => binding.defaultBinaryMessenger).thenReturn(binaryMessenger);

      when(() => registry.getAction(any(), any<dynamic>())).thenReturn(action);
      when(() => emitter.start(any())).thenAnswer((_) async {});
      when(
        () => emitter.fail(any(), reason: any(named: 'reason')),
      ).thenAnswer((_) async {});
      when(() => emitter.done(any())).thenAnswer((_) async {});
    });

    setUpAll(() {
      registerFallbackValue(_FakeTester());
      registerFallbackValue(Uint8List(0));
      registerFallbackValue(PointerDownEvent());
    });

    test('can create a tester without an emitter', () {
      expect(Tester(binding, registry), isNotNull);
    });

    group('compute', () {
      late List<UserFlowStep> steps;

      setUp(() {
        when(() => emitter.announce(any())).thenAnswer((_) async {});

        steps = [
          UserFlowStep('actionName', arguments: 'actionData'),
        ];
      });

      test('retrieves and execute action correctly', () async {
        when(() => action.execute(any())).thenAnswer((_) async => true);
        when(action.description).thenReturn('action');

        final actions = await tester.convert(steps);
        for (final action in actions) {
          await action();
        }

        verify(() => emitter.announce('action')).called(1);

        verify(() => emitter.start(any(that: equals('action')))).called(1);
        verify(
          () => registry.getAction(
            any(that: equals('actionName')),
            any<dynamic>(that: equals('actionData')),
          ),
        ).called(1);
        verify(() => action.execute(any(that: equals(tester)))).called(1);
        verify(() => emitter.done(any(that: equals('action')))).called(1);
      });

      test('fails if action is not found', () async {
        when(() => registry.getAction(any(), any<dynamic>())).thenAnswer((_) {
          throw Exception('Action not found');
        });

        await expectLater(
          () => tester.convert(steps),
          throwsException,
        );

        verifyNever(() => emitter.announce('action'));
      });

      test('fails if action execution throws', () async {
        when(() => action.execute(any()))
            .thenAnswer((_) async => throw Exception('Action failed'));
        when(action.description).thenReturn('action');

        final actions = await tester.convert(steps);
        for (final action in actions) {
          await action();
        }

        verify(() => emitter.announce('action')).called(1);

        verify(() => emitter.start(any(that: equals('action')))).called(1);
        verify(
          () => emitter.fail(
            any(that: equals('action')),
            reason: any(
              named: 'reason',
              that: equals('Exception: Action failed'),
            ),
          ),
        ).called(1);
      });

      test('fails if action execution returns false', () async {
        when(() => action.execute(any())).thenAnswer((_) async => false);
        when(action.description).thenReturn('action');

        final actions = await tester.convert(steps);
        for (final action in actions) {
          await action();
        }

        verify(() => emitter.announce('action')).called(1);

        verify(() => emitter.start(any(that: equals('action')))).called(1);
        verify(
          () => emitter.fail(
            any(that: equals('action')),
            reason: any(named: 'reason'),
          ),
        ).called(1);
      });
    });

    test('storeFile', () async {
      when(() => emitter.store(any(), any())).thenAnswer((_) async {});

      await tester.storeFile('fileName', Uint8List(0));

      verify(
        () => emitter.store(
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
        fakeAsync((async) {
          when(() => binding.endOfFrame).thenAnswer((_) async {
            async.elapse(Duration(milliseconds: 10));
          });

          final future = tester.pump(duration: Duration(milliseconds: 100));

          expect(future, completes);
          async.flushMicrotasks();

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

    group('find', () {
      late SemanticsOwner semanticsOwner;
      late SemanticsNode rootNode;
      late SemanticsNode mergeAllDescendantsIntoThisNode;

      setUp(() {
        semanticsOwner = _MockSemanticsOwner();

        final pipelineOwner = _MockPipelineOwner();
        when(() => binding.pipelineOwner).thenReturn(pipelineOwner);
        when(() => pipelineOwner.semanticsOwner).thenReturn(semanticsOwner);

        rootNode = MockSemanticsNode();
        when(() => semanticsOwner.rootSemanticsNode).thenReturn(rootNode);
      });

      setUpAll(() {
        registerFallbackValue(SemanticsFlag.isHidden);
      });

      test('find a node by given string', () async {
        final node = MockSemanticsNode();
        when(() => node.mergeAllDescendantsIntoThisNode).thenReturn(true);
        when(() => node.isInvisible).thenReturn(false);
        when(() => node.hasFlag(any())).thenReturn(false);

        final semanticsData = _MockSemanticsData();
        when(() => semanticsData.label).thenReturn('label');
        when(() => semanticsData.value).thenReturn('');
        when(() => semanticsData.hint).thenReturn('');
        when(() => semanticsData.tooltip).thenReturn('');

        when(node.getSemanticsData).thenReturn(semanticsData);

        when(() => rootNode.visitChildren(any())).thenAnswer((invocation) {
          final visitor =
              invocation.positionalArguments[0] as SemanticsNodeVisitor;
          visitor(node);
        });

        final result = await tester.find('label');

        expect(result, equals(node));
      });

      test('merge all nodes directly', () async {
        final parentNode = MockSemanticsNode();
        when(() => parentNode.mergeAllDescendantsIntoThisNode)
            .thenReturn(false);
        when(() => parentNode.isInvisible).thenReturn(true);

        final node = MockSemanticsNode();
        when(() => node.mergeAllDescendantsIntoThisNode).thenReturn(false);
        when(() => node.isInvisible).thenReturn(false);
        when(() => node.hasFlag(any())).thenReturn(false);

        final semanticsData = _MockSemanticsData();
        when(() => semanticsData.label).thenReturn('label');
        when(() => semanticsData.value).thenReturn('');
        when(() => semanticsData.hint).thenReturn('');
        when(() => semanticsData.tooltip).thenReturn('');

        when(node.getSemanticsData).thenReturn(semanticsData);

        when(() => rootNode.visitChildren(any())).thenAnswer((invocation) {
          final visitor =
              invocation.positionalArguments[0] as SemanticsNodeVisitor;
          visitor(parentNode);
        });
        when(() => parentNode.visitChildren(any())).thenAnswer((invocation) {
          final visitor =
              invocation.positionalArguments[0] as SemanticsNodeVisitor;
          visitor(node);
        });

        final result = await tester.find('label');

        expect(result, equals(node));
      });

      test('find a node by given regex', () async {
        final node = MockSemanticsNode();
        when(() => node.mergeAllDescendantsIntoThisNode).thenReturn(true);
        when(() => node.isInvisible).thenReturn(false);
        when(() => node.hasFlag(any())).thenReturn(false);

        final semanticsData = _MockSemanticsData();
        when(() => semanticsData.label).thenReturn('');
        when(() => semanticsData.value).thenReturn('');
        when(() => semanticsData.hint).thenReturn('');
        when(() => semanticsData.tooltip).thenReturn('tooltip_0');

        when(node.getSemanticsData).thenReturn(semanticsData);

        when(() => rootNode.visitChildren(any())).thenAnswer((invocation) {
          final visitor =
              invocation.positionalArguments[0] as SemanticsNodeVisitor;
          visitor(node);
        });

        final result = await tester.find(r'tooltip_\d+');

        expect(result, equals(node));
      });

      test('find a node after a pump', () async {
        final node = MockSemanticsNode();
        when(() => node.mergeAllDescendantsIntoThisNode).thenReturn(true);
        when(() => node.isInvisible).thenReturn(false);
        when(() => node.hasFlag(any())).thenReturn(false);

        final semanticsData = _MockSemanticsData();
        when(() => semanticsData.label).thenReturn('label');
        when(() => semanticsData.value).thenReturn('');
        when(() => semanticsData.hint).thenReturn('');
        when(() => semanticsData.tooltip).thenReturn('');

        when(node.getSemanticsData).thenReturn(semanticsData);

        var firstVisit = true;
        when(() => rootNode.visitChildren(any())).thenAnswer((invocation) {
          if (firstVisit) {
            firstVisit = false;
            return;
          }
          final visitor =
              invocation.positionalArguments[0] as SemanticsNodeVisitor;
          visitor(node);
        });

        when(() => binding.endOfFrame).thenAnswer((_) async {});

        final result = await tester.find('label');

        expect(result, equals(node));
        verify(() => binding.endOfFrame).called(1);
      });

      test('returns null after timeout', () {
        fakeAsync((async) {
          when(() => rootNode.visitChildren(any())).thenAnswer((invocation) {});
          when(() => binding.endOfFrame).thenAnswer((_) async {
            async.elapse(Duration(seconds: 1));
          });

          final future = tester.find('label', timeout: Duration(seconds: 1));
          expect(future, completion(isNull));

          async.flushMicrotasks();

          verify(() => binding.endOfFrame).called(2);
        });
      });
    });

    group('getRenderRepaintBoundary', () {
      late RenderObject renderObject;

      setUp(() {
        renderObject = MockRenderObject();

        final renderViewElement = _MockElement();
        when(() => renderViewElement.renderObject).thenReturn(renderObject);
        when(() => binding.renderViewElement).thenReturn(renderViewElement);
      });

      test('recursively finds the renderRepaintBoundary', () {
        final renderRepaintBoundary = MockRenderRepaintBoundary();

        var firstVisit = true;
        when(() => renderObject.visitChildren(any())).thenAnswer((invocation) {
          final visitor =
              invocation.positionalArguments[0] as RenderObjectVisitor;
          if (firstVisit) {
            firstVisit = false;
            return visitor(renderObject);
          }
          return visitor(renderRepaintBoundary);
        });

        final boundary = tester.getRenderRepaintBoundary();
        expect(boundary, equals(renderRepaintBoundary));

        verify(() => renderObject.visitChildren(any())).called(2);
      });
    });
  });
}
