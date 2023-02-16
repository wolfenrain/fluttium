import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttium/fluttium.dart';
import 'package:fluttium_interfaces/fluttium_interfaces.dart';

/// {@template action}
/// An action is a piece of code that can be executed by the driver. It can be
/// used to perform a specific action on the app, like tapping a button or
/// scrolling a list.
///
/// Actions are defined in the `actions` section of the [DriverConfiguration].
///
/// They are immutable as they are created from the steps in a [UserFlowYaml]
/// file.
/// {@endtemplate}
@immutable
abstract class Action {
  /// {@macro action}
  const Action();

  /// Called when it executes the action in a flow file.
  Future<bool> execute(Tester tester);

  /// A human readable description of the action.
  String description();
}
