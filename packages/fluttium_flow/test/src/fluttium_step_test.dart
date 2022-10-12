// ignore_for_file: prefer_const_constructors

import 'package:fluttium_flow/fluttium_flow.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

void main() {
  group('FluttiumStep', () {
    test('can be instantiated', () {
      final step = FluttiumStep(
        FluttiumAction.expectNotVisible,
        text: 'findByText',
      );

      expect(
        step.action,
        equals(FluttiumAction.expectNotVisible),
      );

      expect(
        step.text,
        equals('findByText'),
      );
    });

    test('can construct from a short-hand yaml node', () {
      final step = FluttiumStep.fromYaml(
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
      final step = FluttiumStep.fromYaml(
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
        () => FluttiumStep.fromYaml(YamlList.wrap([])),
        throwsUnsupportedError,
      );
    });

    test('toJson', () {
      final step = FluttiumStep(
        FluttiumAction.expectNotVisible,
        text: 'findByText',
      );

      expect(
        step.toJson(),
        equals({
          'action': 'expectNotVisible',
          'text': 'findByText',
        }),
      );
    });
  });
}
