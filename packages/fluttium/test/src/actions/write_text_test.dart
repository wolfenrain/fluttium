// ignore_for_file: prefer_const_constructors

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluttium/fluttium.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('$WriteText', () {
    late Tester tester;

    setUp(() {
      tester = MockTester();
      when(() => tester.pumpAndSettle(timeout: any(named: 'timeout')))
          .thenAnswer((_) async {});
      when(() => tester.emitPlatformMessage(any(), any()))
          .thenAnswer((_) async {});
    });

    test('writes given text', () async {
      final inputText = WriteText(text: 'hello');
      await inputText.execute(tester);

      verifyInOrder([
        () => tester.emitPlatformMessage(
              any(that: equals(SystemChannels.textInput.name)),
              any(that: isRequestExistingInputState),
            ),
        () => tester.emitPlatformMessage(
              any(that: equals(SystemChannels.textInput.name)),
              any(that: isText('h')),
            ),
        () =>
            tester.pumpAndSettle(timeout: any(named: 'timeout', that: isNull)),
        () => tester.emitPlatformMessage(
              any(that: equals(SystemChannels.textInput.name)),
              any(that: isText('he')),
            ),
        () =>
            tester.pumpAndSettle(timeout: any(named: 'timeout', that: isNull)),
        () => tester.emitPlatformMessage(
              any(that: equals(SystemChannels.textInput.name)),
              any(that: isText('hel')),
            ),
        () =>
            tester.pumpAndSettle(timeout: any(named: 'timeout', that: isNull)),
        () => tester.emitPlatformMessage(
              any(that: equals(SystemChannels.textInput.name)),
              any(that: isText('hell')),
            ),
        () =>
            tester.pumpAndSettle(timeout: any(named: 'timeout', that: isNull)),
        () => tester.emitPlatformMessage(
              any(that: equals(SystemChannels.textInput.name)),
              any(that: isText('hello')),
            ),
        () =>
            tester.pumpAndSettle(timeout: any(named: 'timeout', that: isNull)),
      ]);
    });

    test('Readable representation', () {
      final inputText = WriteText(text: 'hello');

      expect(inputText.description(), 'Write text "hello"');
    });
  });
}

Matcher get isRequestExistingInputState {
  final data = JSONMessageCodec().encodeMessage(<String, Object?>{
    'method': 'TextInputClient.requestExistingInputState',
    'args': null,
  });

  return isA<ByteData?>().having(
    (p0) => p0?.buffer.asUint8List().toList(),
    'buffer',
    equals(data?.buffer.asUint8List().toList()),
  );
}

Matcher isText(String text) {
  final data = JSONMessageCodec().encodeMessage(<String, Object?>{
    'method': 'TextInputClient.updateEditingState',
    'args': [
      -1,
      TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      ).toJSON()
    ],
  });

  return isA<ByteData?>().having(
    (p0) => p0?.buffer.asUint8List().toList(),
    'buffer',
    equals(data?.buffer.asUint8List().toList()),
  );
}
