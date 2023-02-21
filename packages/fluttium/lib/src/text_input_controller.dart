import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// {@template text_input_controller}
/// Used to retrieve the current editing state of an input
/// {@endtemplate}
@visibleForTesting
class TextInputController with TextInputControl {
  /// The current editing state.
  TextEditingValue value = TextEditingValue.empty;

  @override
  void setEditingState(TextEditingValue value) {
    this.value = value;
  }
}
