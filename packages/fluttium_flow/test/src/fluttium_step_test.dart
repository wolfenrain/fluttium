// ignore_for_file: prefer_const_constructors

import 'package:fluttium_flow/fluttium_flow.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

void main() {
  group('FluttiumStep', () {
    test('can construct from a short-hand yaml node', () {
      final step = FluttiumStep(
        YamlMap.wrap({
          'expectVisible': 'findByText',
        }),
      );

      expect(
        step.action,
        equals(FluttiumAction.expectVisible),
      );

      expect(
        step.text,
        equals('findByText'),
      );
    });

    test('can construct from a yaml node', () {
      final step = FluttiumStep(
        YamlMap.wrap({
          'expectVisible': {
            'text': 'findByText',
          }
        }),
      );

      expect(
        step.action,
        equals(FluttiumAction.expectVisible),
      );

      expect(
        step.text,
        equals('findByText'),
      );
    });

    test('throws exception when the node is not a map', () {
      expect(
        () => FluttiumStep(YamlList.wrap([])),
        throwsUnsupportedError,
      );
    });
  });
}
