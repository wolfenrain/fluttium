import 'package:fluttium/fluttium.dart';

/// {@template wait}
/// Wait for a given amount of time until continuing with the next step.
///
/// This action can be invoked either using the short-hand version:
///
/// ```yaml
/// - wait: 500
/// ```
///
/// Or using the verbose version:
///
/// ```yaml
/// - wait:
///     days: 1 # why would you do this?
///     hours: 1
///     minutes: 2
///     seconds: 50
///     milliseconds: 500
///     microseconds: 50
/// ```
/// {@endtemplate}
class Wait extends Action {
  /// {@macro wait}
  Wait({
    int days = 0,
    int hours = 0,
    int minutes = 0,
    int seconds = 0,
    int milliseconds = 0,
    int microseconds = 0,
  }) : duration = Duration(
          days: days,
          hours: hours,
          minutes: minutes,
          seconds: seconds,
          milliseconds: milliseconds,
          microseconds: microseconds,
        );

  /// The duration to wait.
  final Duration duration;

  @override
  Future<bool> execute(Tester tester) async {
    if (duration.isNegative || duration == Duration.zero) {
      return false;
    }

    await tester.pump(duration: duration);
    return true;
  }

  @override
  String description() {
    final microseconds = duration.inMicroseconds;
    final milliseconds = (microseconds / 1000).floor();
    final seconds = milliseconds ~/ 1000;
    final minutes = seconds ~/ 60;
    final hours = minutes ~/ 60;
    final days = hours ~/ 24;

    final remainingHours = hours % 24;
    final remainingMinutes = minutes % 60;
    final remainingSeconds = seconds % 60;
    final remainingMs = milliseconds % 1000;
    final remainingUs = microseconds % 1000;

    final parts = <String>[];
    if (days > 0) {
      parts.add('$days day${days > 1 ? 's' : ''}');
    }
    if (remainingHours > 0) {
      parts.add('$remainingHours hour${remainingHours > 1 ? 's' : ''}');
    }
    if (remainingMinutes > 0) {
      parts.add('$remainingMinutes minute${remainingMinutes > 1 ? 's' : ''}');
    }
    if (remainingSeconds > 0) {
      parts.add('$remainingSeconds second${remainingSeconds > 1 ? 's' : ''}');
    }
    if (remainingMs > 0) {
      parts.add('$remainingMs millisecond${remainingMs > 1 ? 's' : ''}');
    }
    if (remainingUs > 0) {
      parts.add('$remainingUs microsecond${remainingUs > 1 ? 's' : ''}');
    }

    if (parts.length == 1) {
      return 'Wait ${parts[0]}';
    }
    final lastPart = parts.removeLast();
    final allButLastPart = parts.join(', ');
    return 'Wait $allButLastPart and $lastPart';
  }
}
