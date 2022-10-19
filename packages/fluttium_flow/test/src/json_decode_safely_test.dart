import 'package:fluttium_flow/fluttium_flow.dart';
import 'package:test/test.dart';

void main() {
  group('jsonDecodeSafely', () {
    test('safely decodes multiple JSON values from a malformed string', () {
      const input = '''
{
  "a": 1,
  "b": 2,
  "c": 3
}

Some output
{
  "key": "Value"
}

Some more output
[1,2,3]
[{"a": 1}, 
{"b": 3}, {"c": 2}]
''';
      final output = jsonDecodeSafely(input);
      expect(
        output.toList(),
        equals([
          {
            'a': 1,
            'b': 2,
            'c': 3,
          },
          {
            'key': 'Value',
          },
          [1, 2, 3],
          [
            {'a': 1},
            {'b': 3},
            {'c': 2},
          ],
        ]),
      );
    });

    test('throws an error if the JSON is malformed', () {
      const input = '{1,2,3}';

      expect(
        () => jsonDecodeSafely(input).toList(),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
