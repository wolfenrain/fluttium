// ignore_for_file: prefer_const_constructors

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluttium/fluttium.dart';
import 'package:fluttium/src/actions/remove_text.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/helpers.dart';

void main() {
  group('RemoveText', () {
    late Tester tester;

    setUp(() {
      tester = MockTester();
      when(() => tester.pumpAndSettle(timeout: any(named: 'timeout')))
          .thenAnswer((_) async {});
      when(() => tester.emitPlatformMessage(any(), any()))
          .thenAnswer((_) async {});
    });

    test('remove text by given amount', () async {
      final removeText = RemoveText(amount: 2);
      await removeText.execute(tester);

      verifyInOrder([
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

    test('Readable representation', () {
      final removeText1 = RemoveText();
      expect(removeText1.description(), 'Remove text 1 time');

      final removeText2 = RemoveText(amount: 2);
      expect(removeText2.description(), 'Remove text 2 times');
    });
  });
}

Matcher get isDeleteBackward {
  final data = JSONMessageCodec().encodeMessage(<String, Object?>{
    'method': 'TextInputClient.performSelectors',
    'args': [
      -1,
      ['deleteBackward:']
    ],
  });

  return isA<ByteData?>().having(
    (p0) => p0?.buffer.asUint8List().toList(),
    'buffer',
    equals(data?.buffer.asUint8List().toList()),
  );
}
