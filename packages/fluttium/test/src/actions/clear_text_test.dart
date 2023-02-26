// ignore_for_file: prefer_const_constructors

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluttium/fluttium.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('$ClearText', () {
    late Tester tester;

    setUp(() {
      tester = MockTester();
      when(() => tester.pumpAndSettle(timeout: any(named: 'timeout')))
          .thenAnswer((_) async {});
      when(() => tester.emitPlatformMessage(any(), any()))
          .thenAnswer((_) async {});
    });

    test('clear text by given amount', () async {
      final clearText = ClearText(characters: 2);
      clearText.textInputController.value = TextEditingValue(text: 'test');
      await clearText.execute(tester);

      verifyInOrder([
        () => tester.emitPlatformMessage(
              any(that: equals(SystemChannels.textInput.name)),
              any(that: isRequestExistingInputState),
            ),
        () => tester.emitPlatformMessage(
              any(that: equals(SystemChannels.textInput.name)),
              any(that: isDeleteBackward),
            ),
        () =>
            tester.pumpAndSettle(timeout: any(named: 'timeout', that: isNull)),
        () => tester.emitPlatformMessage(
              any(that: equals(SystemChannels.textInput.name)),
              any(that: isDeleteBackward),
            ),
        () =>
            tester.pumpAndSettle(timeout: any(named: 'timeout', that: isNull)),
      ]);
    });

    test('exits early when text is empty', () async {
      final clearText = ClearText();
      await clearText.execute(tester);

      verify(
        () => tester.emitPlatformMessage(
          any(that: equals(SystemChannels.textInput.name)),
          any(that: isRequestExistingInputState),
        ),
      ).called(1);
      verifyNever(
        () => tester.emitPlatformMessage(
          any(that: equals(SystemChannels.textInput.name)),
          any(that: isDeleteBackward),
        ),
      );
      verifyNever(
        () =>
            tester.pumpAndSettle(timeout: any(named: 'timeout', that: isNull)),
      );
      verifyNever(
        () => tester.emitPlatformMessage(
          any(that: equals(SystemChannels.textInput.name)),
          any(that: isDeleteBackward),
        ),
      );
      verifyNever(
        () =>
            tester.pumpAndSettle(timeout: any(named: 'timeout', that: isNull)),
      );
    });

    test('Readable representation', () {
      final clearText = ClearText();
      expect(clearText.description(), 'Clear text');
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
