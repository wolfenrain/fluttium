import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:fluttium_cli/src/bundles/fluttium_flow_bundle.dart';
import 'package:fluttium_flow/fluttium_flow.dart';
import 'package:mason/mason.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart';

/// {@template create_command}
/// `fluttium create` command which creates a [FluttiumFlow] test.
/// {@endtemplate}
class CreateCommand extends Command<int> {
  /// {@macro create_command}
  CreateCommand({
    required Logger logger,
  }) : _logger = logger {
    argParser.addOption(
      'desc',
      abbr: 'd',
      help: 'The description of the flow test.',
    );
  }

  @override
  String get description => 'Create a FluttiumFlow test.';

  @override
  String get name => 'create';

  @override
  String get invocation {
    return super.invocation.replaceAll('[arguments]', '<output.yaml>');
  }

  final Logger _logger;

  /// [ArgResults] used for testing purposes only.
  @visibleForTesting
  ArgResults? testArgResults;

  /// [ArgResults] for the current command.
  ArgResults get results => testArgResults ?? argResults!;

  /// The file to write too.
  File get outputFile {
    if (results.arguments.isEmpty || results.arguments.first.isEmpty) {
      usageException('No output file specified.');
    }
    final file = File(results.arguments.first);
    if (file.existsSync()) {
      final answer = _logger.confirm('File already exists. Overwrite?');
      if (!answer) {
        _logger.err('Aborting.');
        exit(ExitCode.cantCreate.code);
      }
    }
    return file;
  }

  String get _description {
    if (results['desc'] == null) {
      return _logger.prompt('Description:');
    }
    _logger.info(
      '''Description: ${styleDim.wrap(lightCyan.wrap(results['desc'] as String))}''',
    );
    return results['desc'] as String;
  }

  @override
  Future<int> run() async {
    final description = _description;

    final steps = <FluttiumStep>[];
    while (true) {
      final action = _logger.chooseOne(
        'What action should be executed?',
        choices: FluttiumAction.values,
        display: (action) => action.name,
      );

      final value = _logger.prompt('What is the search value (q to exit):');

      if (value == 'q') {
        break;
      }
      steps.add(FluttiumStep(action, text: value));
    }

    final generator = await MasonGenerator.fromBundle(fluttiumFlowBundle);

    await generator.generate(
      DirectoryGeneratorTarget(Directory.current),
      vars: {
        'name': basenameWithoutExtension(outputFile.path),
        'description': description,
        'steps': steps.map((e) => e.toJson()),
      },
      fileConflictResolution: FileConflictResolution.prompt,
    );

    return ExitCode.success.code;
  }
}
