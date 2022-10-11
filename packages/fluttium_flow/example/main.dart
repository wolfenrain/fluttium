import 'package:fluttium_flow/fluttium_flow.dart';

void main() {
  final flow = FluttiumFlow('''
description: 'A simple flow'
---
- expectVisible: 'findByText'
- tapOn: 'findByText'
- inputText: 'findByText'
- expectNotVisible: 'findByText'
''');

  print(flow.description);
}
