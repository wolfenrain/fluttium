import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:cli_completion/cli_completion.dart';
import 'package:fluttium_cli/src/commands/commands.dart';
import 'package:fluttium_cli/src/version.dart';
import 'package:fluttium_driver/fluttium_driver.dart';
import 'package:mason/mason.dart' hide packageVersion;
import 'package:process/process.dart';
import 'package:pub_updater/pub_updater.dart';

const executableName = 'fluttium';
const packageName = 'fluttium_cli';
const description = 'Fluttium, a user flow testing tool for Flutter.';

/// {@template fluttium_command_runner}
/// A [CommandRunner] for the CLI.
///
/// ```
/// $ fluttium --version
/// ```
/// {@endtemplate}
class FluttiumCommandRunner extends CompletionCommandRunner<int> {
  /// {@macro fluttium_command_runner}
  FluttiumCommandRunner({
    Logger? logger,
    PubUpdater? pubUpdater,
    ProcessManager? processManager,
  })  : _logger = logger ?? Logger(),
        _pubUpdater = pubUpdater ?? PubUpdater(),
        _process = processManager ?? const LocalProcessManager(),
        super(executableName, description) {
    // Add root options and flags
    argParser
      ..addFlag(
        'version',
        abbr: 'v',
        negatable: false,
        help: 'Print the current version.',
      )
      ..addFlag(
        'verbose',
        help: 'Noisy logging, including all shell commands executed.',
      );

    // Add sub commands
    addCommand(InitCommand(logger: _logger));
    addCommand(NewCommand(logger: _logger));
    addCommand(TestCommand(logger: _logger, processManager: _process));
    addCommand(UpdateCommand(logger: _logger, pubUpdater: _pubUpdater));
  }

  final Logger _logger;
  final PubUpdater _pubUpdater;
  final ProcessManager _process;

  @override
  void printUsage() => _logger.info(usage);

  @override
  Future<int> run(Iterable<String> args) async {
    try {
      final topLevelResults = parse(args);
      if (topLevelResults['verbose'] == true) {
        _logger.level = Level.verbose;
      }
      return await runCommand(topLevelResults) ?? ExitCode.success.code;
    } on FormatException catch (e, stackTrace) {
      // On format errors, show the commands error message, root usage and
      // exit with an error code
      _logger
        ..err(e.message)
        ..err('$stackTrace')
        ..info('')
        ..info(usage);
      return ExitCode.usage.code;
    } on UsageException catch (e) {
      // On usage errors, show the commands usage message and
      // exit with an error code
      _logger
        ..err(e.message)
        ..info('')
        ..info(e.usage);
      return ExitCode.usage.code;
    }
  }

  @override
  Future<int?> runCommand(ArgResults topLevelResults) async {
    if (topLevelResults.command?.name == 'completion') {
      await super.runCommand(topLevelResults);
      return ExitCode.success.code;
    }

    _logger
      ..detail('Argument information:')
      ..detail('  Top level options:');
    for (final option in topLevelResults.options) {
      if (topLevelResults.wasParsed(option)) {
        _logger.detail('  - $option: ${topLevelResults[option]}');
      }
    }
    if (topLevelResults.command != null) {
      final commandResult = topLevelResults.command!;
      _logger
        ..detail('  Command: ${commandResult.name}')
        ..detail('    Command options:');
      for (final option in commandResult.options) {
        if (commandResult.wasParsed(option)) {
          _logger.detail('    - $option: ${commandResult[option]}');
        }
      }
    }

    final int? exitCode;
    if (topLevelResults['version'] == true) {
      _logger.info(packageVersion);
      exitCode = ExitCode.success.code;
    } else {
      final result =
          (await _process.run(['flutter', '--version'])).stdout as String;

      final flutterVersion =
          RegExp('Flutter (.*?) ').firstMatch(result)!.group(1)!;
      if (!Version.parse(flutterVersion)
          .allowsAny(FluttiumDriver.flutterVersionConstraint)) {
        _logger.err(
          '''
Version solving failed:
  The Fluttium CLI uses "${FluttiumDriver.flutterVersionConstraint}" as the version constraint for Flutter.
  The current Flutter version is "$flutterVersion" which is not supported by Fluttium.

Either update Flutter to a compatible version supported by the CLI or update the CLI to a compatible version of Flutter.''',
        );
        return ExitCode.unavailable.code;
      }

      exitCode = await super.runCommand(topLevelResults);
    }
    if (topLevelResults.command?.name != UpdateCommand.commandName) {
      await _checkForUpdates();
    }
    return exitCode;
  }

  /// Checks if the current version (set by the build runner on the
  /// version.dart file) is the most recent one. If not, show a prompt to the
  /// user.
  Future<void> _checkForUpdates() async {
    try {
      final latestVersion = await _pubUpdater.getLatestVersion(packageName);
      final isUpToDate = packageVersion == latestVersion;
      if (!isUpToDate) {
        _logger
          ..info('')
          ..info(
            '''
${lightYellow.wrap('Update available!')} ${lightCyan.wrap(packageVersion)} \u2192 ${lightCyan.wrap(latestVersion)}
Run ${lightCyan.wrap('$executableName update')} to update''',
          );
      }
    } catch (_) {}
  }
}
