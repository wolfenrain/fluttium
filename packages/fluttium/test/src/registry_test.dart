import 'package:flutter_test/flutter_test.dart';
import 'package:fluttium/fluttium.dart';

class _TestAction extends Action {
  @override
  Future<bool> execute(Tester tester) {
    throw UnimplementedError();
  }

  @override
  String description() {
    throw UnimplementedError();
  }
}

class _TestActionWithArguments extends Action {
  const _TestActionWithArguments({
    required this.key,
  });

  final String key;

  @override
  Future<bool> execute(Tester tester) {
    throw UnimplementedError();
  }

  @override
  String description() {
    throw UnimplementedError();
  }
}

void main() {
  group('Registry', () {
    late Registry registry;

    setUp(() {
      registry = Registry();
    });

    group('registerAction', () {
      test('registers a new action', () {
        registry.registerAction('action', _TestAction.new);

        expect(registry.actions.containsKey('action'), isTrue);
      });

      test('registers a new action with a short hand', () {
        registry.registerAction(
          'action',
          _TestActionWithArguments.new,
          shortHandIs: #key,
        );

        expect(registry.actions.containsKey('action'), isTrue);
        expect(registry.actions['action']!.shortHand, equals(#key));
      });

      test('throws if the action is already registered', () {
        registry.registerAction('action', _TestAction.new);

        expect(
          () => registry.registerAction('action', _TestAction.new),
          throwsArgumentError,
        );
      });
    });

    group('getAction', () {
      test('resolve action with no arguments', () {
        registry.registerAction('action', _TestAction.new);

        expect(registry.getAction('action', null), isA<_TestAction>());
      });

      test('resolve action with arguments', () {
        registry.registerAction('action', _TestActionWithArguments.new);

        expect(
          registry.getAction('action', {'key': 'value'}),
          isA<_TestActionWithArguments>().having(
            (action) => action.key,
            'key',
            'value',
          ),
        );
      });

      test('resolve action using the short-hand mechanism', () {
        registry.registerAction(
          'action',
          _TestActionWithArguments.new,
          shortHandIs: #key,
        );

        expect(
          registry.getAction('action', 'value'),
          isA<_TestActionWithArguments>().having(
            (action) => action.key,
            'key',
            'value',
          ),
        );
      });

      test('throws if the action is not registered', () {
        expect(
          () => registry.getAction('action', null),
          throwsArgumentError,
        );
      });

      test(
        'throws if the action is registered but the arguments are invalid',
        () {
          registry.registerAction('action', _TestActionWithArguments.new);

          expect(
            () => registry.getAction('action', 'key'),
            throwsException,
          );
        },
      );
    });
  });
}
