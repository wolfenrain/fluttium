import 'package:fluttium_flow/fluttium_flow.dart';
import 'package:test/test.dart';

void main() {
  group('jsonDecodeSafely', () {
    test('safely decodes JSON map from a malformed string', () {
      const input = '''
{
  "a": 1,
  "b": 2,
  "c": 3
}

Some output
''';
      final output = jsonDecodeSafely(input);
      expect(
        output,
        equals({
          'a': 1,
          'b': 2,
          'c': 3,
        }),
      );
    });

    test('safely decodes JSON list from a malformed string', () {
      const input = '''
[
  1,
  2,
  3
]

Some output
''';
      final output = jsonDecodeSafely(input);
      expect(
        output,
        equals([1, 2, 3]),
      );
    });

    test('throws an error if no JSON is found', () {
      const input = 'some output';

      expect(
        () => jsonDecodeSafely(input).toList(),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
