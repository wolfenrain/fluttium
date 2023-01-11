// ignore_for_file: prefer_const_constructors

import 'dart:convert';
import 'dart:io';

import 'package:fluttium_interfaces/fluttium_interfaces.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockFile extends Mock implements File {}

class _FakeEncoding extends Fake implements Encoding {}

void main() {
  group('UserFlowYaml', () {
    late File file;

    setUp(() {
      file = _MockFile();
    });

    setUpAll(() {
      registerFallbackValue(_FakeEncoding());
    });

    test('can be instantiated', () {
      final flow = UserFlowYaml(
        description: 'test',
        steps: const [
          UserFlowStep('tapOn', arguments: 'Increment'),
          UserFlowStep('expectVisible', arguments: {'text': 'findByText'}),
        ],
      );

      expect(flow.description, equals('test'));
      expect(
        flow.steps,
        equals([
          UserFlowStep('tapOn', arguments: 'Increment'),
          UserFlowStep(
            'expectVisible',
            arguments: const {'text': 'findByText'},
          ),
        ]),
      );
    });

    test('can construct from a file', () {
      when(() => file.readAsStringSync(encoding: any(named: 'encoding')))
          .thenReturn('''
description: test description
---
- tapOn: "Increment"
- expectVisible: 
    text: "0"
''');

      final flow = UserFlowYaml.fromFile(file);
      expect(flow.description, equals('test description'));
      expect(flow.steps.length, equals(2));

      expect(flow.steps.first.actionName, equals('tapOn'));
      expect(flow.steps.first.arguments, equals('Increment'));

      expect(flow.steps.last.actionName, equals('expectVisible'));
      expect(flow.steps.last.arguments, equals({'text': '0'}));
    });

    test('equality', () {
      final flow = UserFlowYaml(
        description: 'test description',
        steps: const [
          UserFlowStep('tapOn', arguments: 'Increment'),
          UserFlowStep('expectVisible', arguments: {'text': '0'}),
        ],
      );

      final otherFlow = UserFlowYaml(
        description: 'test description',
        steps: const [
          UserFlowStep('tapOn', arguments: 'Increment'),
          UserFlowStep('expectVisible', arguments: {'text': '0'}),
        ],
      );

      expect(flow, equals(otherFlow));
    });
  });
}
