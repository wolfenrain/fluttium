import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:fluttium_cli/src/commands/new_command/new_command.dart';
import 'package:mason/mason.dart';
import 'package:meta/meta.dart';

/// {@template new_bundle_command}
/// Generic class for creating instance of bundles, part of [NewCommand].
/// {@endtemplate}
///
/// It contains the common logic for all the bundles of [NewCommand].
///
/// By default, adds the following arguments to the [argParser]:
/// - 'output-directory': the output directory
class NewBundleCommand extends Command<int> {
  /// {@macro new_bundle_command}
  NewBundleCommand({
    required Logger logger,
    required MasonGeneratorFromBundle? generatorFromBundle,
    required MasonGeneratorFromBrick? generatorFromBrick,
    required MasonBundle bundle,
    this.defaultVars = const {},
  })  : _bundle = bundle,
        _logger = logger,
        _generatorFromBundle = generatorFromBundle ?? MasonGenerator.fromBundle,
        _generatorFromBrick = generatorFromBrick ?? MasonGenerator.fromBrick {
    argParser.addOption(
      'output-directory',
      abbr: 'o',
      help: 'The desired output directory.',
    );

    for (final entry in _bundle.vars.entries) {
      // Skipping name entries.
      if (entry.key == 'name') continue;

      // Skip default vars.
      if (defaultVars.containsKey(entry.key)) continue;

      final props = entry.value;
      switch (props.type) {
        case BrickVariableType.enumeration:
        case BrickVariableType.array:
        case BrickVariableType.list:
          break;
        case BrickVariableType.boolean:
        case BrickVariableType.number:
        case BrickVariableType.string:
          argParser.addOption(
            entry.key,
            help: props.description,
            defaultsTo: props.defaultValue as String?,
          );
      }
    }
  }

  @override
  String get name => _bundle.name.replaceFirst('fluttium_', '');

  @override
  String get description => _bundle.description;

  @override
  String get invocation => 'fluttium new $name <name> [arguments]';

  final Map<String, dynamic> defaultVars;

  final MasonBundle _bundle;

  final Logger _logger;

  final MasonGeneratorFromBundle _generatorFromBundle;

  final MasonGeneratorFromBrick _generatorFromBrick;

  /// [ArgResults] which can be overridden for testing.
  @visibleForTesting
  ArgResults? argResultOverrides;

  /// Gets the output [Directory].
  Directory get outputDirectory {
    final directory = argResults['output-directory'] as String? ?? '.';
    return Directory(directory);
  }

  @override
  ArgResults get argResults => argResultOverrides ?? super.argResults!;

  Future<MasonGenerator> _getGeneratorForTemplate() async {
    try {
      final brick = Brick.version(
        name: _bundle.name,
        version: '^${_bundle.version}',
      );
      _logger.detail(
        '''Building generator from brick: ${brick.name} ${brick.location.version}''',
      );
      return await _generatorFromBrick(brick);
    } catch (_) {
      _logger.detail('Building generator from brick failed: $_');
    }
    _logger.detail(
      '''Building generator from bundle ${_bundle.name} ${_bundle.version}''',
    );
    return _generatorFromBundle(_bundle);
  }

  @override
  Future<int> run() async {
    final args = argResults.rest;
    if (args.isEmpty) usageException('No name specified.');
    if (args.length > 1) usageException('Multiple names specified.');

    final name = args.first;
    final bundle = _bundle;
    final generator = await _getGeneratorForTemplate();
    final vars = bundle.vars.map((key, _) {
      if (key == 'name') return MapEntry(key, name);
      if (defaultVars.containsKey(key)) return MapEntry(key, defaultVars[key]);
      return MapEntry(key, argResults[key]);
    });

    final relativePath = outputDirectory.relativePath;
    final generateProgress =
        _logger.progress('Generating a new ${this.name} in "$relativePath"');
    final target = DirectoryGeneratorTarget(outputDirectory);

    await generator.hooks.preGen(vars: vars, onVarsChanged: vars.addAll);
    await generator.generate(target, vars: vars, logger: _logger);
    generateProgress
        .complete('Generated a new ${this.name} in "$relativePath"');

    return ExitCode.success.code;
  }
}

extension on Directory {
  String get relativePath {
    final path = this.path;
    if (!path.startsWith('.') && !path.startsWith('/')) {
      return './$path';
    }
    return path;
  }
}
