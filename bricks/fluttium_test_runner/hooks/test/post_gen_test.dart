import 'dart:io';

import 'package:mason/mason.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../post_gen.dart';

class _FakeHookContext extends Fake implements HookContext {
  _FakeHookContext({Logger? logger}) : _logger = logger ?? _MockLogger();

  final Logger _logger;

  var _vars = <String, dynamic>{};

  @override
  Map<String, dynamic> get vars => _vars;

  @override
  set vars(Map<String, dynamic> value) => _vars = value;

  @override
  Logger get logger => _logger;
}

class _MockLogger extends Mock implements Logger {}

class _MockProgress extends Mock implements Progress {}

class _MockProcessResult extends Mock implements ProcessResult {}

void main() {
  group('postGen', () {
    late HookContext context;
    late Logger logger;
    late Progress installingActions;

    setUp(() {
      logger = _MockLogger();
      context = _FakeHookContext(logger: logger);
      installingActions = _MockProgress();

      when(() => logger.progress(any())).thenReturn(installingActions);
    });

    test('installs actions correctly', () async {
      var processRunnerCallCount = 0;

      final result = _MockProcessResult();
      when(() => result.exitCode).thenReturn(ExitCode.success.code);

      await postGen(
        context,
        runProcess: (
          executable,
          args, {
          String? workingDirectory,
          bool? runInShell,
        }) async {
          processRunnerCallCount++;
          expect(executable, equals('flutter'));
          expect(args, equals(['pub', 'get']));
          expect(workingDirectory, equals(Directory.current.path));
          expect(runInShell, isTrue);
          return result;
        },
      );

      expect(processRunnerCallCount, equals(1));
      verify(
        () => logger.progress(any(that: equals('Installing actions'))),
      ).called(1);
      verify(() => installingActions.complete()).called(1);
    });

    test('fails installing actions throws exception', () async {
      var processRunnerCallCount = 0;

      final result = _MockProcessResult();
      when(() => result.exitCode).thenReturn(ExitCode.tempFail.code);
      when(() => result.stderr).thenReturn('fake error');

      try {
        await postGen(
          context,
          runProcess: (
            executable,
            args, {
            String? workingDirectory,
            bool? runInShell,
          }) async {
            processRunnerCallCount++;
            expect(executable, equals('flutter'));
            expect(args, equals(['pub', 'get']));
            expect(workingDirectory, equals(Directory.current.path));
            expect(runInShell, isTrue);
            return result;
          },
        );
      } on Exception catch (err) {
        expect(
          err.toString(),
          equals('Exception: Failed to install actions: fake error'),
        );
      }

      expect(processRunnerCallCount, equals(1));
      verify(
        () => logger.progress(any(that: equals('Installing actions'))),
      ).called(1);
      verifyNever(() => installingActions.complete());
    });
  });
}
