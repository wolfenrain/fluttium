import 'package:args/command_runner.dart';
import 'package:fluttium_cli/src/bundles/bundles.dart';
import 'package:fluttium_cli/src/commands/new_command/new_bundle_command.dart';
import 'package:fluttium_driver/fluttium_driver.dart';
import 'package:mason/mason.dart';

/// A method which returns a [Future<MasonGenerator>] given a [MasonBundle].
typedef MasonGeneratorFromBundle = Future<MasonGenerator> Function(MasonBundle);

/// A method which returns a [Future<MasonGenerator>] given a [Brick].
typedef MasonGeneratorFromBrick = Future<MasonGenerator> Function(Brick);

/// {@template new_command}
/// `fluttium new` command creates code from various built-in bundles.
/// {@endtemplate}
///
/// See also:
/// - [NewBundleCommand] for the class that handles all bundles.
class NewCommand extends Command<int> {
  /// {@macro new_command}
  NewCommand({
    required Logger logger,
    MasonGeneratorFromBundle? generatorFromBundle,
    MasonGeneratorFromBrick? generatorFromBrick,
  }) {
    // fluttium new action <args>
    addSubcommand(
      NewBundleCommand(
        bundle: fluttiumActionBundle,
        logger: logger,
        generatorFromBundle: generatorFromBundle,
        generatorFromBrick: generatorFromBrick,
        defaultVars: {
          'fluttiumVersion': FluttiumDriver.fluttiumVersionConstraint.min,
        },
      ),
    );

    // fluttium new flow <args>
    addSubcommand(
      NewBundleCommand(
        bundle: fluttiumFlowBundle,
        logger: logger,
        generatorFromBundle: generatorFromBundle,
        generatorFromBrick: generatorFromBrick,
      ),
    );
  }

  @override
  String get description =>
      'Create new actions and flows to use with Fluttium.';

  @override
  String get name => 'new';

  @override
  String get invocation => 'fluttium new <subcommand> <name> [arguments]';
}
