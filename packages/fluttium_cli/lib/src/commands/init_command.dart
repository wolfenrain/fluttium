import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:fluttium_driver/fluttium_driver.dart';
import 'package:fluttium_interfaces/fluttium_interfaces.dart';
import 'package:mason/mason.dart';

/// {@template init_command}
/// `fluttium init` command which initializes a [FluttiumYaml] in the current
/// directory.
/// {@endtemplate}
class InitCommand extends Command<int> {
  /// {@macro init_command}
  InitCommand({required Logger logger}) : _logger = logger;

  final Logger _logger;

  @override
  final String description = 'Initialize Fluttium in the current directory.';

  @override
  final String name = 'init';

  bool get fluttiumInitialized => File(FluttiumYaml.file).existsSync();

  @override
  Future<int> run() async {
    if (fluttiumInitialized) {
      _logger.err(
        'There is already a "${FluttiumYaml.file}" in the current directory',
      );
      return ExitCode.usage.code;
    }

    final initProgress = _logger.progress('Initializing');
    final generator = _FluttiumYamlGenerator();
    await generator.generate(
      DirectoryGeneratorTarget(Directory.current),
      vars: <String, String>{'name': '{{name}}'},
      logger: _logger,
    );
    initProgress.complete('Initialized a new Fluttium project.');

    _logger
      ..info('')
      ..info('Run "fluttium new flow" to create your first flow.');
    return ExitCode.success.code;
  }
}

class _FluttiumYamlGenerator extends MasonGenerator {
  _FluttiumYamlGenerator()
      : super(
          '__fluttium_init__',
          'Initialize a new ${FluttiumYaml.file}',
          files: [TemplateFile(FluttiumYaml.file, _fluttiumYamlContent)],
        );

  static final _fluttiumYamlContent = '''
# The following defines the environment for your Fluttium project. It includes 
# the version of Fluttium that the project requires.
environment:
  fluttium: "${FluttiumDriver.fluttiumVersionConstraint}"

# The driver can be configured with default values. Uncomment the following 
# lines to automatically run Fluttium using a different flavor and dart-defines.
# driver:
#   flavor: development
#   dartDefines:
#     - CUSTOM_DART_DEFINE=1

# Register actions which can be used within your Fluttium flows.
actions:
  # The following adds the log action to your project.
  log_action: 0.1.0+1
  # Actions can also be imported via git url.
  # Uncomment the following lines to import
  # the log_action from a remote git url.
  # log_action:
  #   git:
  #     url: https://github.com/wolfenrain/fluttium.git
  #     path: actions/log_action
''';
}
