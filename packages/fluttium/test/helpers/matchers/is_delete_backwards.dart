import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Matcher get isDeleteBackward {
  final data = const JSONMessageCodec().encodeMessage(<String, Object?>{
    'method': 'TextInputClient.performSelectors',
    'args': [
      -1,
      ['deleteBackward:'],
    ],
  });

  return isA<ByteData?>().having(
    (p0) => p0?.buffer.asUint8List().toList(),
    'buffer',
    equals(data?.buffer.asUint8List().toList()),
  );
}
