import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttium/fluttium.dart';

/// {@template action}
/// TODO: Add documentation
/// {@endtemplate}
@immutable
abstract class Action {
  /// {@macro action}
  const Action();

  /// Called when it executes the action in a flow file.
  Future<bool> execute(FluttiumTester tester);
}
