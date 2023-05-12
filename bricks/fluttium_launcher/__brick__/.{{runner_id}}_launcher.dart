import 'dart:async';

import 'package:{{{project_name}}}/{{{target}}}' as app;
import 'package:flutter/material.dart';

import 'package:fluttium_test_runner/fluttium_test_runner.dart' as test_runner;

void main() async {
  await Future(app.main);

  scheduleMicrotask(() => test_runner.run(WidgetsBinding.instance));
}
