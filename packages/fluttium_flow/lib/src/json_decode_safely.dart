import 'dart:convert';

/// A function that takes a raw string that contains JSON and other text and
/// returns an iterable of JSON objects that it found.
Iterable<dynamic> jsonDecodeSafely(String input) sync* {
  final jsonRegex = RegExp(
    r'(?:(\{).*?\})|(?:(\[).*?\])',
    dotAll: true,
  );

  for (final match in jsonRegex.allMatches(input)) {
    final source = match.group(0)!;
    final String openBracket;
    final String closeBracket;

    if (match.group(1) != null) {
      openBracket = '{';
      closeBracket = '}';
    } else {
      openBracket = '[';
      closeBracket = ']';
    }

    final buffer = StringBuffer();
    var depth = 0;

    // Assuming the JSON is valid, we only need to start matching the opening
    // and closing brackets until it evens out to extract the JSON.
    for (var i = 0; i < source.length; i++) {
      final currentChar = source[i];
      final previousChar = i > 0 ? source[i - 1] : null;

      buffer.write(currentChar);

      // Match the opening and closing brackets, if the current character is a
      // the open bracket we increment the depth, if it is the closing bracket
      // we decrement the depth.
      if (currentChar == openBracket && previousChar != r'\') {
        depth++;
      } else if (currentChar == closeBracket && previousChar != r'\') {
        depth--;
      }

      // If the depth is 0, we have matched the opening and closing brackets
      // and can break out of the loop.
      if (depth == 0) break;
    }

    yield jsonDecode(buffer.toString());
  }
}
