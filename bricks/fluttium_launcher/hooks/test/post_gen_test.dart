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
    late Progress uninstallingTestRunner;

    setUp(() {
      logger = _MockLogger();
      context = _FakeHookContext(logger: logger);
      uninstallingTestRunner = _MockProgress();

      when(() => logger.progress(any())).thenReturn(uninstallingTestRunner);
    });

    test('run completes', () {
      expect(run(context), completes);
    });

    test('uninstalls fluttium_test_runner correctly', () async {
      var processRunnerCallCount = 0;

      final result = _MockProcessResult();
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
          expect(args, equals(['pub', 'remove', 'fluttium_test_runner']));
          expect(workingDirectory, equals(Directory.current.path));
          expect(runInShell, isTrue);
          return result;
        },
      );

      expect(processRunnerCallCount, equals(1));
      verify(
        () => logger.progress(any(that: equals('Uninstalling test runner'))),
      ).called(1);
      verify(() => uninstallingTestRunner.complete()).called(1);
    });
  });
}
