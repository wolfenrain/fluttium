import 'package:fluttium/fluttium.dart';

/// {@template fluttium_registry}
/// The registry of all the actions a [FluttiumBinding] can perform.
/// {@endtemplate}
class FluttiumRegistry {
  final Map<String, _ActionRegistration> _actions = {
    'tapOn': _ActionRegistration(TapOn.new, #text),
    'inputText': _ActionRegistration(InputText.new, #text),
    'expectVisible': _ActionRegistration(ExpectVisible.new, #text),
    'expectNotVisible': _ActionRegistration(ExpectNotVisible.new, #text),
  };

  /// Registers an action with the registry.
  void registerAction(String name, Function action, {Symbol? shortHandIs}) {
    if (_actions.containsKey(name)) {
      // TODO: better error
      throw ArgumentError.value(
        name,
        'name',
        'An action with this name is already registered.',
      );
    }
    _actions[name] = _ActionRegistration(action, shortHandIs);
  }

  /// Returns the action with the given name.
  Action getAction(String name, dynamic arguments) {
    if (!_actions.containsKey(name)) {
      // TODO: better error
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

class _ActionRegistration {
  _ActionRegistration(this.actionFactory, this.shortHand);

  final Function actionFactory;
  final Symbol? shortHand;

  Action resolve(dynamic data) {
    // If the data is not a map, check if the action has a short-hand. If it
    // does, then we can assume that the data is the short-hand value.
    if (data is! Map<String, dynamic>) {
      if (shortHand != null) {
        return Function.apply(actionFactory, [], {shortHand!: data}) as Action;
      }
      // TODO: better error
      throw Exception('Invalid data type: ${data.runtimeType}');
    }

    return Function.apply(
      actionFactory,
      [],
      data.map((key, value) => MapEntry(Symbol(key), value)),
    ) as Action;
  }
}
