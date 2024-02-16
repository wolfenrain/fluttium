import 'dart:convert';
import 'dart:io';

import 'package:fluttium_protocol/fluttium_protocol.dart';

void main() {
  // Emitting data for the listener.
  Emitter()
    ..announce('stepName')
    ..start('stepName')
    ..store('fileName', [1, 2, 3])
    ..done('stepName');

  // Listening to data from the emitter.
  Listener(_fakeData()).messages.listen((message) {
    stdout.writeln('Received ${message.type} with data: ${message.data}');
  });
}

Stream<List<int>> _fakeData() async* {
  final list = [
    {'type': 'start'},
    {
      'type': 'data',
      'data': r'"{\"type\":\"announce\",\"data\":\"\\\"stepName\\\"\"}"',
    },
    {'type': 'done'},
    {'type': 'start'},
    {
      'type': 'data',
      'data': r'"{\"type\":\"start\",\"data\":\"\\\"stepName\\\"\"}"',
    },
    {'type': 'done'},
    {'type': 'start'},
    {
      'type': 'data',
      'data': r'"{\"type\":\"done\",\"data\":\"\\\"stepName\\\"\"}"',
    },
    {'type': 'done'},
  ];
  for (final data in list) {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    yield utf8.encode('${json.encode(data)}\n');
  }
}
