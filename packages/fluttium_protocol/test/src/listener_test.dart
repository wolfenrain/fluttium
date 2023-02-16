// ignore_for_file: prefer_const_constructors

import 'dart:async';
import 'dart:convert';

import 'package:fluttium_protocol/fluttium_protocol.dart';
import 'package:test/test.dart';

void main() {
  group('Listener', () {
    test('correctly parses a single message', () async {
      await runWithEmitter((emitter, stream) async {
        final listener = Listener(stream);

        await emitter.start('step');

        expect(
          listener.messages,
          emitsInOrder([equals(Message.start('step'))]),
        );
      });
    });

    test('correctly parses multiple messages', () async {
      await runWithEmitter((emitter, stream) async {
        final listener = Listener(stream);

        await emitter.start('step');
        await emitter.done('step');

        expect(
          listener.messages,
          emitsInOrder([
            equals(Message.start('step')),
            equals(Message.done('step')),
          ]),
        );
      });
    });

    test('correctly parses a message split across multiple chunks', () async {
      await runWithEmitter((emitter, stream) async {
        final listener = Listener(stream);

        final bytes = List.generate(10000, (i) => i);

        await emitter.start('step');
        await emitter.store('fileName', bytes);
        await emitter.done('step');

        await printingDone;

        expect(
          listener.messages,
          emitsInOrder([
            equals(Message.start('step')),
            equals(Message.store('fileName', bytes)),
            equals(Message.done('step')),
          ]),
        );
      });
    });

    test('correctly parse messages with other data in between', () async {
      await runWithEmitter((emitter, stream) async {
        final listener = Listener(stream);

        await emitter.start('step');
        // ignore: avoid_print
        print('some other data');
        // ignore: avoid_print
        print('some more data that is annoying but hey what can you do');
        await emitter.done('step');

        await printingDone;

        expect(
          listener.messages,
          emitsInOrder([
            equals(Message.start('step')),
            equals(Message.done('step')),
          ]),
        );
      });
    });

    test('correctly parse big messages with other data in between', () async {
      await runWithEmitter((emitter, stream) async {
        final listener = Listener(stream);

        final bytes = List.generate(10000, (i) => i);

        await emitter.start('step');
        // ignore: avoid_print
        print('some other data');
        await emitter.store('fileName', bytes);
        // ignore: avoid_print
        print('some more data that is annoying but hey what can you do');
        await emitter.done('step');

        await printingDone;

        expect(
          listener.messages,
          emitsInOrder([
            equals(Message.start('step')),
            equals(Message.store('fileName', bytes)),
            equals(Message.done('step')),
          ]),
        );
      });
    });
  });
}

Future<void> runWithEmitter(
  Future<void> Function(
    Emitter emitter,
    Stream<List<int>> controller,
  )
      callback,
) async {
  final emitter = Emitter();
  final controller = StreamController<List<int>>();

  await runZoned(
    () => callback(emitter, controller.stream),
    zoneSpecification: ZoneSpecification(
      print: (self, parent, zone, message) =>
          controller.add(utf8.encode('$message\n')),
    ),
  );

  await printingDone;
  await controller.close();
}
