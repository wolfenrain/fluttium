// ignore_for_file: prefer_const_constructors

import 'package:fluttium_protocol/fluttium_protocol.dart';
import 'package:test/test.dart';

void main() {
  group('Message', () {
    test('announce', () {
      final message = Message.announce('step');

      expect(message.type, equals(MessageType.announce));
      expect(message.data, equals('step'));
    });

    test('start', () {
      final message = Message.start('step');

      expect(message.type, equals(MessageType.start));
      expect(message.data, equals('step'));
    });

    test('done', () {
      final message = Message.done('step');

      expect(message.type, equals(MessageType.done));
      expect(message.data, equals('step'));
    });

    test('fatal', () {
      final message = Message.fatal('reason');

      expect(message.type, equals(MessageType.fatal));
      expect(message.data, equals('reason'));
    });

    test('fail', () {
      final message = Message.fail('step', reason: 'error');

      expect(message.type, equals(MessageType.fail));
      expect(message.data, equals(['step', 'error']));
    });

    test('store', () {
      final message = Message.store('fileName', const [1, 2, 3]);

      expect(message.type, equals(MessageType.store));
      expect(
        message.data,
        equals([
          'fileName',
          [1, 2, 3],
        ]),
      );
    });

    group('fromJson', () {
      test('parses correctly', () {
        final message = Message.fromJson(const {'type': 'start'});

        expect(message.type, equals(MessageType.start));
      });

      test('throws when type is not implemented', () {
        expect(
          () => Message.fromJson(const {'type': 'unknown'}),
          throwsA(isA<UnimplementedError>()),
        );
      });
    });

    test('toJson', () {
      final message = Message.start('step');

      expect(
        message.toJson(),
        equals(const {'type': 'start', 'data': '"step"'}),
      );

      final messageWithData = Message.fail('step', reason: 'error');

      expect(
        messageWithData.toJson(),
        equals(const {'type': 'fail', 'data': '["step","error"]'}),
      );
    });
  });
}
