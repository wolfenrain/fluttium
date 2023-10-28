import 'package:fluttium_cli/src/json_decode_safely.dart';
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

    test('safely decodes nested JSON from a malformed string', () {
      const input = '''
{
  "a": [
    1,
    2,
    3
  ],
  "b": {
    "d": 5,
    "e": 6,
    "f": [7, 8, 9]
  },
  "c": 4
}
Some output
''';
      final output = jsonDecodeSafely(input);
      expect(
        output,
        equals({
          'a': [1, 2, 3],
          'b': {
            'd': 5,
            'e': 6,
            'f': [7, 8, 9],
          },
          'c': 4,
        }),
      );
    });

    test('throws an error if no JSON is found', () {
      const input = 'some output';

      expect(
        () => jsonDecodeSafely(input),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
