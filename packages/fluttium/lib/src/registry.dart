import 'dart:collection';

import 'package:fluttium/fluttium.dart';
import 'package:fluttium/src/actions/clear_text.dart';

/// {@template registry}
/// The registry of all the actions a [Tester] can perform.
/// {@endtemplate}
class Registry {
  final Map<String, ActionRegistration> _actions = {
    'tapOn': ActionRegistration(PressOn.new, #text),
    'inputText': ActionRegistration(WriteText.new, #text),
    // TODO(wolfen): deprecate the above action keys

    'pressOn': ActionRegistration(PressOn.new, #text),
    'longPressOn': ActionRegistration(LongPressOn.new, #text),
    'clearText': ActionRegistration(ClearText.new, #amount),
    'writeText': ActionRegistration(WriteText.new, #text),
    'expectVisible': ActionRegistration(ExpectVisible.new, #text),
    'expectNotVisible': ActionRegistration(ExpectNotVisible.new, #text),
    'takeScreenshot': ActionRegistration(TakeScreenshot.new, #fileName),
  };

  /// Map of all the action that are registered.
  UnmodifiableMapView<String, ActionRegistration> get actions =>
      UnmodifiableMapView(_actions);

  /// Registers an action with the registry.
  void registerAction(String name, Function action, {Symbol? shortHandIs}) {
    if (_actions.containsKey(name)) {
      throw ArgumentError.value(
        name,
        'name',
        'An action with this name is already registered.',
      );
    }
    _actions[name] = ActionRegistration(action, shortHandIs);
  }

  /// Returns the action with the given name.
  Action getAction(String name, dynamic arguments) {
    if (!_actions.containsKey(name)) {
      throw ArgumentError.value(
        name,
        'name',
        'An action with this name is not registered.',
      );
    }
    final registration = _actions[name]!;
    return registration.resolve(arguments);
  }
}

/// {@template action_registration}
/// A registration of an action.
/// {@endtemplate}
class ActionRegistration {
  /// The action to be registered.
  ActionRegistration(this.actionFactory, this.shortHand);

  /// The factory that creates the action.
  final Function actionFactory;

  /// The short-hand for the action.
  final Symbol? shortHand;

  /// Creates an action from the given arguments.
  Action resolve(dynamic data) {
    // If the data is not a map, check if the action has a short-hand. If it
    // does, then we can assume that the data is the short-hand value.
    if (data is! Map<String, dynamic>) {
      if (shortHand != null) {
        return Function.apply(actionFactory, [], {shortHand!: data}) as Action;
      }
      if (data == null) {
        return Function.apply(actionFactory, []) as Action;
      }
      throw Exception('Invalid data type: ${data.runtimeType}');
    }

    return Function.apply(
      actionFactory,
      [],
      data.map((key, value) => MapEntry(Symbol(key), value)),
    ) as Action;
  }
}
