import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:fluttium/fluttium.dart';

/// {@template registry}
/// The registry of all the actions a [Tester] can perform.
/// {@endtemplate}
class Registry {
  final Map<String, ActionRegistration> _actions = {
    'tapOn': ActionRegistration(PressOn.new, shortHand: #text),
    'inputText': ActionRegistration(WriteText.new, shortHand: #text),
    // TODO(wolfen): deprecate the above action keys

    'pressOn': ActionRegistration(PressOn.new, shortHand: #text),
    'longPressOn': ActionRegistration(LongPressOn.new, shortHand: #text),
    'clearText': ActionRegistration(ClearText.new, shortHand: #characters),
    'writeText': ActionRegistration(WriteText.new, shortHand: #text),
    'expectVisible': ActionRegistration(ExpectVisible.new, shortHand: #text),
    'expectNotVisible':
        ActionRegistration(ExpectNotVisible.new, shortHand: #text),
    'takeScreenshot': ActionRegistration(TakeScreenshot.new, shortHand: #path),
    'wait': ActionRegistration(Wait.new, shortHand: #milliseconds),
    'scroll': ActionRegistration(
      ({
        required String within,
        required String until,
        String direction = 'down',
        double speed = 40,
        int? timeout,
      }) =>
          Scroll(
        within: within,
        until: until,
        direction: AxisDirection.values.firstWhere((e) => e.name == direction),
        speed: speed,
        timeout: timeout,
      ),
      aliases: const [
        Alias(['in'], #within)
      ],
    ),
    'swipe': ActionRegistration(
      ({
        required String within,
        required String until,
        String direction = 'left',
        double speed = 40,
        int? timeout,
      }) =>
          Swipe(
        within: within,
        until: until,
        direction: AxisDirection.values.firstWhere((e) => e.name == direction),
        speed: speed,
        timeout: timeout,
      ),
      aliases: const [
        Alias(['in'], #within)
      ],
    ),
  };

  /// Map of all the action that are registered.
  UnmodifiableMapView<String, ActionRegistration> get actions =>
      UnmodifiableMapView(_actions);

  /// Registers an action with the registry.
  void registerAction(
    String name,
    Function action, {
    Symbol? shortHandIs,
    List<Alias> aliases = const [],
  }) {
    if (_actions.containsKey(name)) {
      throw ArgumentError.value(
        name,
        'name',
        'An action with this name is already registered.',
      );
    }
    _actions[name] =
        ActionRegistration(action, shortHand: shortHandIs, aliases: aliases);
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

/// {@template alias}
/// Describe an alias parameter for an [ActionRegistration].
///
/// Use this to map multiple parameters to a single parameter for the [Action]
/// constructor.
/// {@endtemplate}
@immutable
class Alias {
  /// {@macro alias}
  const Alias(this.aliases, this.key);

  /// The aliases that point to [key].
  final List<String> aliases;

  /// The key for which the [aliases] are defined.
  final Symbol key;

  @override
  bool operator ==(Object other) {
    if (other is! Alias) return false;
    if (key != other.key) return false;

    if (aliases.length != other.aliases.length) return false;
    for (var i = 0; i < aliases.length; i++) {
      if (!(aliases.elementAt(i) == other.aliases.elementAt(i))) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll([key, aliases]);
}

/// {@template action_registration}
/// A registration of an action.
/// {@endtemplate}
class ActionRegistration {
  /// The action to be registered.
  ActionRegistration(
    this.actionFactory, {
    this.shortHand,
    this.aliases = const [],
  });

  /// The factory that creates the action.
  final Function actionFactory;

  /// The short-hand for the action.
  final Symbol? shortHand;

  /// Aliases for parameters.
  final List<Alias> aliases;

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

    final namedParameters = data.map((key, value) {
      for (final alias in aliases) {
        if (alias.aliases.contains(key)) {
          return MapEntry(alias.key, value);
        }
      }
      return MapEntry(Symbol(key), value);
    });

    return Function.apply(actionFactory, [], namedParameters) as Action;
  }
}
