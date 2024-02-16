import 'dart:async';
import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:flutter_daemon/flutter_daemon.dart';
import 'package:fluttium_driver/fluttium_driver.dart';
import 'package:fluttium_interfaces/fluttium_interfaces.dart';
import 'package:meta/meta.dart';

/// {@template fluttium_driver}
/// A driver for executing Fluttium flow tests.
/// {@endtemplate}
abstract class FluttiumDriver {
  /// {@macro fluttium_driver}
  FluttiumDriver({
    required this.configuration,
    required this.actions,
    required this.userFlow,
  })  : _stepStateController = StreamController.broadcast(),
        _filesController = StreamController.broadcast(),
        _stepStates = userFlow.steps.map(UserFlowStepState.new).toList();

  /// The configuration for the driver.
  final DriverConfiguration configuration;

  /// The actions to install to run the flow.
  final Map<String, ActionLocation> actions;

  /// The user flow that is being run.
  late UserFlowYaml userFlow;

  /// Stream of the steps in the user flow.
  ///
  /// The steps are emitted as a list of [UserFlowStepState]s representing the
  /// current state of those steps, the list is ordered by the order of
  /// execution.
  late final Stream<List<UserFlowStepState>> steps =
      _stepStateController.stream;
  final StreamController<List<UserFlowStepState>> _stepStateController;
  final List<UserFlowStepState> _stepStates;

  /// Stream of files that should be stored.
  late final Stream<StoredFile> files = _filesController.stream;
  final StreamController<StoredFile> _filesController;

  FlutterDaemon? _daemon;
  FlutterApplication? _application;

  var _restarting = false;

  /// Run the driver.
  ///
  /// This will setup the driver generated code, generate the runner, and start
  /// the runner with the given user flow.
  ///
  /// This will return a [Future] that completes when the driver is done,
  /// either by completing the user flow, application was closed, [quit] was
  /// called, or an error occurred.
  ///
  /// To listen to the steps in the user flow, use the [steps] stream.
  Future<void> run({bool watch = false}) async {
    await onRun(watch: watch);

    _daemon = await getFlutterDaemon();
    _application = await getFlutterApplication(_daemon!);
    if (_application == null) return _daemon!.dispose();

    await _executeSteps();

    // If all steps were done, or if a step failed, stop the process unless
    // we're in watch mode.
    if (!watch &&
        (_stepStates.every((e) => e.status == StepStatus.done) ||
            _stepStates.any((e) => e.status == StepStatus.failed))) {
      return quit();
    }

    // Wait for Daemon to finish.
    await _daemon?.finished;

    await quit();
  }

  /// Called right before the driver starts to run.
  @protected
  Future<void> onRun({required bool watch}) async {}

  /// Restart the runner and the driver.
  Future<void> restart() async {
    if (_restarting || _daemon == null) return;
    _restarting = true;

    await onRestart();

    // Tell the daemon to restart the runner.
    await _application?.restart();
    _restarting = false;

    await _executeSteps();
  }

  /// Called right before the test runner gets restarted.
  @protected
  Future<void> onRestart() async {}

  /// Close the runner and it's driver.
  Future<void> quit() async {
    await onQuit();

    // Close the step state controller.
    await _stepStateController.close();

    // Tell the daemon to stop the runner.
    if (!(_daemon?.isFinished ?? true)) {
      await _application?.stop();
    }
    await _daemon?.dispose();
  }

  /// Called right before the driver starts to quit.
  @protected
  Future<void> onQuit() async {}

  /// Returns the [FlutterDaemon] that will be used to start the test runner
  /// application.
  ///
  /// Each driver has to provide its own daemon implementation.
  @protected
  Future<FlutterDaemon> getFlutterDaemon();

  /// Returns the [FlutterApplication] that will serve as the test runner
  /// application.
  ///
  /// Each driver has to provide its own application implementation, which
  /// should be provided through the daemon to allow [FluttiumDriver] to
  /// correctly dispose of both the daemon and application when so required.
  @protected
  Future<FlutterApplication?> getFlutterApplication(FlutterDaemon daemon);

  Future<void> _isReady() async {
    // The service extensions might not be setup yet, so we wait at most 30
    // seconds and constantly retry to determine if it is setup.
    final timeout = clock.now().add(const Duration(seconds: 30));

    Future<void> ready() async {
      final response = await _application!.callServiceExtension(
        'ext.fluttium.ready',
      );

      if (response.hasError || response.result!['ready'] == false) {
        if (clock.now().isBefore(timeout)) {
          return Future.delayed(const Duration(microseconds: 500), ready);
        }

        throw FluttiumFailedToGetReady(
          response.error ??
              response.result?['reason'] as String? ??
              'Unknown reason',
        );
      }
    }

    return ready();
  }

  Future<void> _executeSteps() async {
    _stepStates
      ..clear()
      ..addAll(userFlow.steps.map(UserFlowStepState.new));

    await _isReady();

    // Get all action descriptions and announce them.
    for (var i = 0; i < _stepStates.length; i++) {
      final response = await _application!.callServiceExtension(
        'ext.fluttium.getActionDescription',
        params: {
          'name': _stepStates[i].step.actionName,
          'arguments': json.encode(_stepStates[i].step.arguments),
        },
      );
      if (response.hasError) {
        throw FluttiumFatalStepFail(_stepStates[i], response.error!);
      }

      _stepStates[i] = _stepStates[i].copyWith(
        description: response.result!['description'] as String,
      );
    }
    _stepStateController.add(_stepStates);

    for (var i = 0; i < _stepStates.length; i++) {
      _stepStates[i] = _stepStates[i].copyWith(status: StepStatus.running);
      _stepStateController.add(_stepStates);
      final response = await _application!.callServiceExtension(
        'ext.fluttium.executeAction',
        params: {
          'name': _stepStates[i].step.actionName,
          'arguments': json.encode(_stepStates[i].step.arguments),
        },
      );

      final hasError =
          response.hasError || response.result!['success'] == false;

      if (hasError) {
        _stepStates[i] = _stepStates[i].copyWith(
          status: StepStatus.failed,
          failReason: response.error ?? response.result!['reason'] as String?,
        );
      } else {
        final files = response.result!['files'] as Map<String, dynamic>;
        if (files.isNotEmpty) {
          for (final key in files.keys) {
            _filesController.add(
              StoredFile(key, base64.decode(files[key]! as String)),
            );
          }
        }
        _stepStates[i] = _stepStates[i].copyWith(
          status: StepStatus.done,
          // ignore: deprecated_member_use_from_same_package
          files: files.map((k, v) => MapEntry(k, base64.decode(v as String))),
        );
      }
      _stepStateController.add(_stepStates);

      // We had an error, do not continue.
      if (hasError) break;
    }
  }
}

/// {@template fluttium_failed_to_get_ready}
/// Thrown when the [FluttiumDriver] does not get a ready event from the
/// [FlutterApplication] on time.
/// {@endtemplate}
class FluttiumFailedToGetReady implements Exception {
  /// {@macro fluttium_failed_to_get_ready}
  FluttiumFailedToGetReady(this.reason);

  /// Reason for failure.
  final String reason;

  @override
  String toString() => 'Fluttium failed to get ready: $reason';
}

/// {@template fluttium_fatal_step_fail}
/// Thrown when the [FluttiumDriver] detect a fatal failure, this is different
/// from a step that fails normally.
/// {@endtemplate}
class FluttiumFatalStepFail implements Exception {
  /// {@macro fluttium_fatal_step_fail}
  const FluttiumFatalStepFail(this.state, this.reason);

  /// The state at which the step was at.
  final UserFlowStepState state;

  /// The reason for the fatal failure.
  final String reason;

  @override
  String toString() {
    return 'Fluttium fatally failed step "${state.description}": $reason';
  }
}
