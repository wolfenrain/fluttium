import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:fluttium_protocol/fluttium_protocol.dart';
import 'package:meta/meta.dart';

/// {@template emitter}
/// Emits [Message]s from the runner to the driver.
/// {@endtemplate}
class Emitter {
  bool _hasFailed = false;

  /// Announce that a step has been initialized.
  Future<void> announce(String step) => _emit(Message.announce(step));

  /// Indicate that a step has started.
  Future<void> start(String step) => _emit(Message.start(step));

  /// Indicate that a step has completed.
  Future<void> done(String step) => _emit(Message.done(step));

  /// Store binary data with the given [fileName].
  Future<void> store(String fileName, List<int> bytes) {
    return _emit(Message.store(fileName, bytes));
  }

  /// Indicate that a step has failed.
  Future<void> fail(String step, {String? reason}) async {
    await _emit(Message.fail(step, reason: reason ?? 'Unknown'));
    _hasFailed = true;
  }

  Future<void> _emit(Message message) async {
    if (_hasFailed) return Completer<void>().future;

    _throttledPrint(json.encode({'type': 'start'}));

    final data = json.encode(message.toJson());
    const maxLength = 800;
    for (var i = 0; i < data.length; i += maxLength) {
      final offset = i + maxLength;
      final part = data.substring(
        i,
        offset >= data.length ? data.length : offset,
      );
      _throttledPrint(json.encode({'type': 'data', 'data': json.encode(part)}));
    }
    _throttledPrint(json.encode({'type': 'done'}));
  }
}

/// This avoids dropping messages on platforms that rate-limit their
/// logging (for example, Android).
///
/// Based on `debugThrottledPrint` from Flutter.
void _throttledPrint(String message) {
  final messageLines = message.split('\n');
  _printBuffer.addAll(messageLines);
  if (!_printScheduled) {
    _printTask();
  }
}

var _printedCharacters = 0;
const _printCapacity = 12 * 1024;
const _printPauseTime = Duration(seconds: 1);
final _printBuffer = Queue<String>();
final _printStopwatch = Stopwatch();
Completer<void>? _printCompleter;
var _printScheduled = false;

void _printTask() {
  _printScheduled = false;
  if (_printStopwatch.elapsed > _printPauseTime) {
    _printStopwatch
      ..stop()
      ..reset();
    _printedCharacters = 0;
  }
  while (_printedCharacters < _printCapacity && _printBuffer.isNotEmpty) {
    final line = _printBuffer.removeFirst();
    _printedCharacters += line.length;
    // ignore: avoid_print
    print(line);
  }
  if (_printBuffer.isNotEmpty) {
    _printScheduled = true;
    _printedCharacters = 0;
    Timer(_printPauseTime, _printTask);
    _printCompleter ??= Completer<void>();
  } else {
    _printStopwatch.start();
    _printCompleter?.complete();
    _printCompleter = null;
  }
}

/// A Future that resolves when there is no longer any buffered content being
/// printed by [_throttledPrint].
@visibleForTesting
Future<void> get printingDone =>
    _printCompleter?.future ?? Future<void>.value();
