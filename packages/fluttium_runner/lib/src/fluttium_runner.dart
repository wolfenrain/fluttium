import 'dart:convert';
import 'dart:io';

import 'package:fluttium_flow/fluttium_flow.dart';
import 'package:fluttium_runner/src/bundles/bundles.dart';
import 'package:mason/mason.dart';
import 'package:path/path.dart';
import 'package:process/process.dart';
import 'package:watcher/watcher.dart';
import 'package:yaml/yaml.dart';

///
typedef FlowRenderer = void Function(FluttiumFlow flow, List<bool?> stepStates);

/// {@template fluttium_runner}
/// A runner for executing Fluttium flow tests.
/// {@endtemplate}
class FluttiumRunner {
  /// {@macro fluttium_runner}
  FluttiumRunner({
    required this.flowFile,
    required this.projectDirectory,
    required this.deviceId,
    required this.renderer,
    required this.mainEntry,
    this.flavor,
    Logger? logger,
    ProcessManager? processManager,
  })  : _logger = logger ?? Logger(),
        _processManager = processManager ?? const LocalProcessManager();

  /// The flow file to run.
  final File flowFile;

  /// The project directory to run in.
  final Directory projectDirectory;

  /// The device id to run on.
  final String deviceId;

  /// The renderer to use.
  final FlowRenderer renderer;

  /// The main entry file to run.
  ///
  /// Defaults to `lib/main.dart`.
  final File mainEntry;

  /// The flavor to run.
  final String? flavor;

  final Logger _logger;
  final ProcessManager _processManager;

  /// The parsed flow file.
  FluttiumFlow? flow;

  MasonGenerator? _generator;

  /// The result of each previous step that has been run.
  ///
  /// If it is `null` then we just started that step, otherwise it is the
  /// success status of the step that matches the index in the list.
  final List<bool?> _stepStates = [];

  late File _driver;

  final Map<String, dynamic> _vars = {};

  Process? _process;

  /// Execute the given [action].
  void _executeAction(String action, String? data) {
    switch (action) {
      case 'start':
        _stepStates.add(null);
        break;
      case 'fail':
        _stepStates.last = false;
        break;
      case 'done':
        _stepStates.last = true;
        break;
      case 'screenshot':
        final step = flow!.steps[_stepStates.length - 1];
        final bytes = data!.split(',').map(int.parse).toList();
        File(join(projectDirectory.path, 'screenshots', '${step.text}.png'))
          ..createSync(recursive: true)
          ..writeAsBytesSync(bytes);
        break;
      default:
        throw Exception('Unknown action: $action');
    }
  }

  void _convertFlowToVars() {
    String sanitize(String text) => text.replaceAll("'", r"\'");

    _vars.addAll({
      'flow_description': sanitize(flow!.description),
      'flow_steps': flow!.steps
          .map((e) {
            final text = sanitize(e.text);
            switch (e.action) {
              case FluttiumAction.expectVisible:
                return "await worker.expectVisible(r'$text');";
              case FluttiumAction.expectNotVisible:
                return "await worker.expectNotVisible(r'$text');";
              case FluttiumAction.tapOn:
                return "await worker.tapOn(r'$text');";
              case FluttiumAction.inputText:
                return "await worker.inputText(r'$text');";
              case FluttiumAction.takeScreenshot:
                return "await worker.takeScreenshot(r'$text');";
            }
          })
          .map((e) => {'step': e})
          .toList(),
    });
  }

  Future<void> _setupProject() async {
    if (!mainEntry.existsSync()) {
      throw Exception('Could not find main entry file: $mainEntry');
    }

    final projectData = loadYaml(
      File(join(projectDirectory.path, 'pubspec.yaml')).readAsStringSync(),
    ) as YamlMap;

    _vars['mainEntry'] =
        mainEntry.path.replaceFirst(join(projectDirectory.path, 'lib/'), '');
    _vars['project_name'] = projectData['name'];
  }

  Future<void> _generateDriver() async {
    // Read the flow file and parse it. This keeps it fresh in case it changed.
    flow = FluttiumFlow(flowFile.readAsStringSync());
    _convertFlowToVars();

    _generator ??= await MasonGenerator.fromBundle(fluttiumDriverBundle);
    final result = await _generator!.generate(
      DirectoryGeneratorTarget(projectDirectory),
      vars: _vars,
    );
    _driver = File(result.first.path);
  }

  Future<void> _cleanupProject() async {
    if (_driver.existsSync()) {
      _driver.deleteSync();
    }

    await _generator!.hooks.postGen(
      vars: _vars,
      workingDirectory: projectDirectory.path,
      onVarsChanged: _vars.addAll,
    );
  }

  /// Runs the flow.
  ///
  /// If [watch] is true, the flow will be re-run whenever the flow file
  /// changed or the application code changed.
  Future<void> run({bool watch = false}) async {
    await _setupProject();
    await _generateDriver();

    final startingUpTestDriver = _logger.progress('Starting up test driver');
    _process = await _processManager.start(
      [
        'flutter',
        'run',
        _driver.path,
        '-d',
        deviceId,
        if (flavor != null) ...['--flavor', flavor!],
      ],
      runInShell: true,
      workingDirectory: projectDirectory.path,
    );

    var isAttached = false;
    final buffer = StringBuffer();
    _process?.stdout.listen((event) async {
      final data = utf8.decode(event).trim();
      buffer.write(data);

      // Skip until we see the first line of the test output.
      if (!isAttached &&
          data.startsWith(RegExp(r'^[I/]*flutter[\s*\(\s*\d+\)]*: '))) {
        startingUpTestDriver.complete();
        isAttached = true;
      }

      // Skip until the driver is ready.
      if (!isAttached) return;

      final regex = RegExp('fluttium:(start|fail|done|screenshot):(.*?);');
      final matches = regex.allMatches(buffer.toString());

      // If matches is not empty, clear the buffer and check if the last match
      // is the end of the buffer. If it is not, we add what is left back to
      // the buffer.
      if (matches.isNotEmpty) {
        final content = buffer.toString();
        final lastMatch = matches.last;

        buffer.clear();
        if (content.length > lastMatch.end) {
          buffer.write(content.substring(lastMatch.end));
        }
      }

      for (final match in matches) {
        _executeAction(match.group(1)!, match.group(2));
      }

      // Only render if there was actions found.
      if (matches.isNotEmpty) {
        renderer(flow!, _stepStates);
      }

      // If we have completed all the steps, or if we have failed, exit the
      // process unless we are in watch mode.
      if (!watch &&
          (_stepStates.whereType<bool>().length == flow!.steps.length ||
              _stepStates.any((e) => e == false))) {
        _process?.stdin.write('q');
      }
    });

    final stderrBuffer = StringBuffer();
    _process?.stderr.listen((event) => stderrBuffer.write(utf8.decode(event)));

    // If we are in watch mode, we need to watch the flow file and the
    // application code for changes.
    if (watch) {
      // If the application code changes, we clear the step states and
      // hot restart the application.
      final projectWatcher = DirectoryWatcher(projectDirectory.path);
      projectWatcher.events.listen(
        (event) {
          if (!event.path.endsWith('.dart')) return;
          restart();
        },
        onError: (Object err) {
          if (err is FileSystemException &&
              err.message.contains('Failed to watch')) {
            return _logger.detail(err.toString());
          }
          // ignore: only_throw_errors
          throw err;
        },
      );

      // If the flow file changes, we clear the step states and re-generate
      // the driver before hot restarting the application.
      final flowWatcher = FileWatcher(flowFile.path);
      flowWatcher.events.listen((event) async {
        await _generateDriver();
        restart();
      });
    }

    // Wait for the process to exit, and then clean up the project.
    await _process!.exitCode;
    _process = null;

    // If it exited without correctly attaching to the application, we
    // output the errors.
    if (!isAttached) {
      startingUpTestDriver.fail('Failed to start test driver');
      _logger.err(stderrBuffer.toString());
    }

    await quit();
  }

  /// Restart the runner and it's driver.
  void restart() {
    _stepStates.clear();
    _process?.stdin.write('R');
  }

  /// Quit the runner and it's driver.
  Future<void> quit() async {
    _process?.stdin.write('q');
    await _cleanupProject();
  }
}
