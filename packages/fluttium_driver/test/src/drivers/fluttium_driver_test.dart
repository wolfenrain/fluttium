// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'dart:async';
import 'dart:convert';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_daemon/flutter_daemon.dart';
import 'package:fluttium_driver/fluttium_driver.dart';
import 'package:fluttium_interfaces/fluttium_interfaces.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockFlutterDaemon extends Mock implements FlutterDaemon {}

class _MockFlutterApplication extends Mock implements FlutterApplication {}

class _TestDriver extends FluttiumDriver {
  _TestDriver(this.daemon, {required super.userFlow})
      : super(
          actions: {},
          configuration: const DriverConfiguration(),
        );

  final FlutterDaemon daemon;

  bool runCalled = false;

  bool quitCalled = false;

  bool restartCalled = false;

  @override
  Future<void> onRun({required bool watch}) async => runCalled = true;

  @override
  Future<void> onQuit() async => quitCalled = true;

  @override
  Future<void> onRestart() async => restartCalled = true;

  @override
  Future<FlutterApplication?> getFlutterApplication(FlutterDaemon daemon) {
    return daemon.run(arguments: []);
  }

  @override
  Future<FlutterDaemon> getFlutterDaemon() async => daemon;
}

void main() {
  group('$FluttiumDriver', () {
    late FlutterDaemon daemon;
    late Completer<bool> daemonIsFinished;
    late FlutterApplication application;
    late Completer<bool> isReady;
    late Completer<void> startExecuting;
    late String? executionError;
    late String? getError;
    late Map<String, String> files;
    late _TestDriver driver;

    void continueExecuting() => startExecuting.complete();

    setUp(() {
      daemon = _MockFlutterDaemon();
      when(() => daemon.run(arguments: any(named: 'arguments'))).thenAnswer(
        (_) async => application,
      );

      daemonIsFinished = Completer();
      when(() => daemon.finished).thenAnswer((_) => daemonIsFinished.future);
      when(() => daemon.isFinished).thenAnswer(
        (_) => daemonIsFinished.isCompleted,
      );

      when(() => daemon.dispose()).thenAnswer((_) async {});

      application = _MockFlutterApplication();

      isReady = Completer();
      when(
        () => application.callServiceExtension(
          any(that: equals('ext.fluttium.ready')),
          params: any(named: 'params'),
        ),
      ).thenAnswer((_) async {
        return AppCallServiceExtensionResponse.fromJSON({
          'id': 0,
          'result': <String, dynamic>{'ready': isReady.future},
          'error': null,
        });
      });

      when(
        () => application.callServiceExtension(
          any(that: equals('ext.fluttium.getActionDescription')),
          params: any(named: 'params'),
        ),
      ).thenAnswer((invocation) async {
        final params =
            invocation.namedArguments[#params] as Map<String, dynamic>;

        return AppCallServiceExtensionResponse.fromJSON({
          'id': 0,
          'result': <String, dynamic>{'description': params['name']},
          'error': getError,
        });
      });

      startExecuting = Completer<void>();
      when(
        () => application.callServiceExtension(
          any(that: equals('ext.fluttium.executeAction')),
          params: any(named: 'params'),
        ),
      ).thenAnswer((_) async {
        await startExecuting.future;

        return AppCallServiceExtensionResponse.fromJSON({
          'id': 0,
          'result': <String, dynamic>{
            'success': executionError == null,
            'files': files,
          },
          'error': executionError,
        });
      });

      when(() => application.stop()).thenAnswer((_) async {
        return AppStopResponse.fromJSON({
          'id': 0,
          'result': true,
          'error': null,
        });
      });

      when(() => application.restart()).thenAnswer((_) async {
        return AppRestartResponse.fromJSON({
          'id': 0,
          'result': {
            'code': 0,
            'message': '',
          },
          'error': null,
        });
      });

      executionError = null;
      getError = null;
      files = {};
      driver = _TestDriver(
        daemon,
        userFlow: UserFlowYaml(
          description: 'description',
          steps: [
            UserFlowStep('expectVisible', arguments: 'Text'),
            UserFlowStep('pressOn', arguments: 'Text'),
          ],
        ),
      );
    });

    test('can run a flow test', () async {
      final future = driver.run();
      isReady.complete(true);

      expect(driver.runCalled, isTrue);

      final initialSteps = await driver.steps
          .where((event) => event.every((e) => e.description != ''))
          .first;

      expect(
        initialSteps,
        equals([
          UserFlowStepState(
            UserFlowStep('expectVisible', arguments: 'Text'),
            description: 'expectVisible',
            status: StepStatus.running,
          ),
          UserFlowStepState(
            UserFlowStep('pressOn', arguments: 'Text'),
            description: 'pressOn',
          ),
        ]),
      );

      final foundFile = driver.files.first;

      files['test.file'] = base64.encode(utf8.encode('test'));

      continueExecuting();

      final finishedSteps = await driver.steps
          .where((event) => event.every((e) => e.status == StepStatus.done))
          .first;

      expect(
        finishedSteps,
        equals([
          UserFlowStepState(
            UserFlowStep('expectVisible', arguments: 'Text'),
            description: 'expectVisible',
            status: StepStatus.done,
          ),
          UserFlowStepState(
            UserFlowStep('pressOn', arguments: 'Text'),
            description: 'pressOn',
            status: StepStatus.done,
          ),
        ]),
      );

      expect(
        await foundFile,
        isA<StoredFile>()
            .having((f) => f.path, 'path', equals('test.file'))
            .having((f) => f.data, 'data', equals(utf8.encode('test'))),
      );

      await future;

      expect(driver.quitCalled, isTrue);

      verify(
        () => application.callServiceExtension(
          any(that: equals('ext.fluttium.ready')),
          params: any(named: 'params', that: equals({})),
        ),
      ).called(equals(1));

      verify(
        () => application.callServiceExtension(
          any(that: equals('ext.fluttium.getActionDescription')),
          params: any(
            named: 'params',
            that: equals({
              'name': isA<String>(),
              'arguments': isA<String>(),
            }),
          ),
        ),
      ).called(equals(2));
    });

    group('throws $FluttiumFailedToGetReady', () {
      late String? readyReason;
      late String? error;

      setUp(() {
        readyReason = null;
        error = null;

        when(
          () => application.callServiceExtension(
            any(that: equals('ext.fluttium.ready')),
            params: any(named: 'params'),
          ),
        ).thenAnswer((_) async {
          return AppCallServiceExtensionResponse.fromJSON({
            'id': 0,
            'result': <String, dynamic>{'ready': false, 'reason': readyReason},
            'error': error,
          });
        });
      });

      Matcher failedToGetReady(String reason) {
        return isA<FluttiumFailedToGetReady>().having(
          (e) => e.reason,
          'reason',
          reason,
        );
      }

      test('with a non-ready reason', () {
        readyReason = 'readyReason';

        fakeAsync((async) {
          final future = driver.run();
          expectLater(future, throwsA(failedToGetReady('readyReason')));
          async.elapse(Duration(seconds: 31));
        });
      });

      test('when there is an error', () {
        error = 'errorReason';

        fakeAsync((async) {
          final future = driver.run();
          expectLater(future, throwsA(failedToGetReady('errorReason')));
          async.elapse(Duration(seconds: 31));
        });
      });

      test('when it times out without a reason', () {
        fakeAsync((async) {
          final future = driver.run();
          expectLater(future, throwsA(failedToGetReady('Unknown reason')));
          async.elapse(Duration(seconds: 31));
        });
      });
    });

    test('throws $FluttiumFatalStepFail if a step fails unexpectedly',
        () async {
      // Set the getDescription error.
      getError = 'failed';

      final future = driver.run();

      await expectLater(
        future,
        throwsA(
          isA<FluttiumFatalStepFail>()
              .having((e) => e.reason, 'reason', 'failed')
              .having(
                (e) => e.state,
                'state',
                UserFlowStepState(
                  UserFlowStep('expectVisible', arguments: 'Text'),
                ),
              ),
        ),
      );
    });

    test('quit if a step state failed', () async {
      final future = driver.run();
      isReady.complete(true);

      // Set the execution error.
      executionError = 'failed';
      continueExecuting();

      final failedSteps = await driver.steps
          .where((event) => event.any((e) => e.status == StepStatus.failed))
          .first;

      expect(
        failedSteps,
        equals([
          UserFlowStepState(
            UserFlowStep('expectVisible', arguments: 'Text'),
            description: 'expectVisible',
            status: StepStatus.failed,
            failReason: 'failed',
          ),
          UserFlowStepState(
            UserFlowStep('pressOn', arguments: 'Text'),
            description: 'pressOn',
          ),
        ]),
      );

      await future;

      expect(driver.quitCalled, isTrue);

      verify(() => application.stop()).called(equals(1));
      verify(() => daemon.dispose()).called(equals(1));
    });

    group('watch', () {
      test('quit after driver finishes in watch mode', () async {
        final future = driver.run(watch: true);
        isReady.complete(true);

        // Wait until the steps are done.
        continueExecuting();
        await driver.steps
            .where((event) => event.every((e) => e.status == StepStatus.done))
            .first;

        // Should not be called because it is in watch mode
        expect(driver.quitCalled, isFalse);

        // Tell the daemon we are finished, the future should now complete.
        daemonIsFinished.complete(true);
        await future;

        expect(driver.quitCalled, isTrue);

        // Should never be called as the daemon was already finished.
        verifyNever(() => application.stop());
        verify(() => daemon.dispose()).called(equals(1));
      });

      test('restart driver while in watch mode', () async {
        final future = driver.run(watch: true);
        isReady.complete(true);

        // Wait until the steps are done.
        continueExecuting();
        await driver.steps
            .where((event) => event.every((e) => e.status == StepStatus.done))
            .first;

        expect(driver.restartCalled, isFalse);
        await driver.restart();
        verify(() => application.restart()).called(equals(1));
        expect(driver.restartCalled, isTrue);

        // Tell the daemon we are finished, the future should now complete.
        daemonIsFinished.complete(true);
        await future;

        expect(driver.quitCalled, isTrue);
        verify(() => daemon.dispose()).called(equals(1));

        // Because we restart it should have been called 4 times instead of two.
        verify(
          () => application.callServiceExtension(
            any(that: equals('ext.fluttium.getActionDescription')),
            params: any(
              named: 'params',
              that: equals({
                'name': isA<String>(),
                'arguments': isA<String>(),
              }),
            ),
          ),
        ).called(equals(4));
      });
    });
  });

  group('$FluttiumFailedToGetReady', () {
    test('toString', () {
      expect(
        FluttiumFailedToGetReady('reason').toString(),
        equals('Fluttium failed to get ready: reason'),
      );
    });
  });

  group('$FluttiumFatalStepFail', () {
    test('toString', () {
      expect(
        FluttiumFatalStepFail(
          UserFlowStepState(
            UserFlowStep('expectVisible', arguments: 'Text'),
            description: 'expectVisible',
          ),
          'reason',
        ).toString(),
        equals('Fluttium fatally failed step "expectVisible": reason'),
      );
    });
  });
}
