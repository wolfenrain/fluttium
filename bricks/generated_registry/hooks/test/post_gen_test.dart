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

void main() {
  group('postGen', () {
    late HookContext context;
    late Logger logger;

    setUp(() {
      logger = _MockLogger();
      context = _FakeHookContext(logger: logger);

      when(() => logger.progress(any())).thenReturn(_MockProgress());
    });

    test('run completes when pubspec.yaml exists', () async {
      const name = 'example';
      context.vars = {'name': name};
      await expectLater(run(context), completes);
    });
  });
}
