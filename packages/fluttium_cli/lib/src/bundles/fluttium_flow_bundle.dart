// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, implicit_dynamic_list_literal, implicit_dynamic_map_literal, inference_failure_on_collection_literal

import 'package:mason/mason.dart';

final fluttiumFlowBundle = MasonBundle.fromJson(<String, dynamic>{
  "files": [
    {
      "path": "{{name.snakeCase()}}.yaml",
      "data":
          "ZGVzY3JpcHRpb246IHt7e2Rlc2NyaXB0aW9ufX19Ci0tLQotIHRhcE9uOiAnVGhlIHRleHQgb3IgYSBzZW1hbnRpYyBsYWJlbCBvbiB0aGUgc2NyZWVuJw==",
      "type": "text"
    }
  ],
  "hooks": [],
  "name": "fluttium_flow",
  "description": "Generate a new Fluttium flow file.",
  "version": "0.1.0+1",
  "environment": {"mason": ">=0.1.0-dev.41 <0.1.0"},
  "vars": {
    "name": {
      "type": "string",
      "description": "The name of the flow file",
      "default": "my_flow",
      "prompt": "What is the name of the flow file?"
    },
    "description": {
      "type": "string",
      "description": "The description of the flow",
      "default": "My first Fluttium flow.",
      "prompt": "What is the description of the flow?"
    }
  }
});
