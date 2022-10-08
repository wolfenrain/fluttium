// ignore_for_file: prefer_const_constructors

import 'package:fluttium_flow/fluttium_flow.dart';
import 'package:test/test.dart';

void main() {
  group('FluttiumFlow', () {
    test('can be instantiated', () {
      expect(
        FluttiumFlow('''
name: test
description: test
---
- tapOn: "Increment"
'''),
        isNotNull,
      );
    });
  });
}
