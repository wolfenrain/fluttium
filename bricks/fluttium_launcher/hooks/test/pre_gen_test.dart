import 'dart:io';

import 'package:mason/mason.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../pre_gen.dart';

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
  group('preGen', () {
    late HookContext context;
    late Logger logger;
    late Progress installingTestRunner;

    setUp(() {
      logger = _MockLogger();
      context = _FakeHookContext(logger: logger)
        ..vars = {'runner_path': 'runner_path'};
      installingTestRunner = _MockProgress();

      when(() => logger.progress(any())).thenReturn(installingTestRunner);
    });

    test('installs fluttium_test_runner correctly', () async {
      var processRunnerCallCount = 0;

      final result = _MockProcessResult();
      await preGen(
        context,
        runProcess: (
          executable,
          args, {
          String? workingDirectory,
          bool? runInShell,
        }) async {
          processRunnerCallCount++;
          expect(executable, equals('flutter'));
          expect(workingDirectory, equals(Directory.current.path));
          expect(runInShell, isTrue);

          if (processRunnerCallCount == 1) {
            expect(args, equals(['pub', 'remove', 'fluttium_test_runner']));
          } else {
            expect(
              args,
              equals([
                'pub',
                'add',
                'fluttium_test_runner',
                '--dev',
                '--path',
                'runner_path',
              ]),
            );
          }
          return result;
        },
      );

      expect(processRunnerCallCount, equals(2));
      verify(
        () => logger.progress(any(that: equals('Installing test runner'))),
      ).called(1);
      verify(installingTestRunner.complete).called(1);
    });
  });
}
