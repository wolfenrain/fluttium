import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Matcher isText(String text) {
  final data = const JSONMessageCodec().encodeMessage(<String, Object?>{
    'method': 'TextInputClient.updateEditingState',
    'args': [
      -1,
      TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      ).toJSON(),
    ],
  });

  return isA<ByteData?>().having(
    (p0) => p0?.buffer.asUint8List().toList(),
    'buffer',
    equals(data?.buffer.asUint8List().toList()),
  );
}
