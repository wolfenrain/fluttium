import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:cli_completion/cli_completion.dart';
import 'package:fluttium_cli/src/command_runner.dart';
import 'package:fluttium_cli/src/version.dart';
import 'package:fluttium_driver/fluttium_driver.dart';
import 'package:mason/mason.dart' hide packageVersion;
import 'package:mocktail/mocktail.dart';
import 'package:process/process.dart';
import 'package:pub_updater/pub_updater.dart';
import 'package:test/test.dart';

class MockLogger extends Mock implements Logger {}

class MockPubUpdater extends Mock implements PubUpdater {}

class MockProgress extends Mock implements Progress {}

class MockProcessManger extends Mock implements ProcessManager {}

const latestVersion = '0.0.0';

final updatePrompt = '''
${lightYellow.wrap('Update available!')} ${lightCyan.wrap(packageVersion)} \u2192 ${lightCyan.wrap(latestVersion)}
Run ${lightCyan.wrap('fluttium update')} to update''';

void main() {
  group('FluttiumCommandRunner', () {
    late PubUpdater pubUpdater;
    late Logger logger;
    late FluttiumCommandRunner commandRunner;
    late ProcessManager processManager;
    var flutterVersion = FluttiumDriver.flutterVersionConstraint.min.toString();

    setUp(() {
      pubUpdater = MockPubUpdater();

      when(
        () => pubUpdater.getLatestVersion(any()),
      ).thenAnswer((_) async => packageVersion);

      logger = MockLogger();

      processManager = MockProcessManger();
      when(
        () => processManager.run(any(that: equals(['flutter', '--version']))),
      ).thenAnswer((_) async {
        return ProcessResult(
          0,
          ExitCode.success.code,
          '''
Flutter $flutterVersion • channel stable • https://github.com/flutter/flutter.git
Framework • revision AAAAAAAAAA (0 days ago) • 9999-12-31 00:00:00 -0700
Engine • revision AAAAAAAAAA
Tools • Dart 0.0.0 • DevTools 0.0.0
''',
          '',
        );
      });

      commandRunner = FluttiumCommandRunner(
        logger: logger,
        pubUpdater: pubUpdater,
        processManager: processManager,
      );
    });

    test('shows update message when newer version exists', () async {
      when(
        () => pubUpdater.getLatestVersion(any()),
      ).thenAnswer((_) async => latestVersion);

      final result = await commandRunner.run(['--version']);
      expect(result, equals(ExitCode.success.code));
      verify(() => logger.info(updatePrompt)).called(1);
    });

    test('does not show update message when using the update command',
        () async {
      when(
        () => pubUpdater.getLatestVersion(any()),
      ).thenAnswer((_) async => latestVersion);
      when(
        () => pubUpdater.update(packageName: packageName),
      ).thenAnswer((_) => Future.value(ProcessResult(0, 0, '', '')));
      when(
        () => pubUpdater.isUpToDate(
          packageName: any(named: 'packageName'),
          currentVersion: any(named: 'currentVersion'),
        ),
      ).thenAnswer((_) => Future.value(true));

      final progress = MockProgress();
      final progressLogs = <String>[];
      when(() => progress.complete(any())).thenAnswer((_) {
        final message = _.positionalArguments.elementAt(0) as String?;
        if (message != null) progressLogs.add(message);
      });
      when(() => logger.progress(any())).thenReturn(progress);

      final result = await commandRunner.run(['update']);
      expect(result, equals(ExitCode.success.code));
      verifyNever(() => logger.info(updatePrompt));
    });

    test('can be instantiated without an explicit analytics/logger instance',
        () {
      final commandRunner = FluttiumCommandRunner();
      expect(commandRunner, isNotNull);
    });

    test('handles FormatException', () async {
      const exception = FormatException('oops!');
      var isFirstInvocation = true;
      when(() => logger.info(any())).thenAnswer((_) {
        if (isFirstInvocation) {
          isFirstInvocation = false;
          throw exception;
        }
      });
      final result = await commandRunner.run(['--version']);
      expect(result, equals(ExitCode.usage.code));
      verify(() => logger.err(exception.message)).called(1);
      verify(() => logger.info(commandRunner.usage)).called(1);
    });

    test('handles UsageException', () async {
      final exception = UsageException('oops!', 'exception usage');
      var isFirstInvocation = true;
      when(() => logger.info(any())).thenAnswer((_) {
        if (isFirstInvocation) {
          isFirstInvocation = false;
          throw exception;
        }
      });
      final result = await commandRunner.run(['--version']);
      expect(result, equals(ExitCode.usage.code));
      verify(() => logger.err(exception.message)).called(1);
      verify(() => logger.info('exception usage')).called(1);
    });

    group('--version', () {
      test('outputs current version', () async {
        final result = await commandRunner.run(['--version']);
        expect(result, equals(ExitCode.success.code));
        verify(() => logger.info(packageVersion)).called(1);
      });
    });

    group('--verbose', () {
      test('enables verbose logging', () async {
        final result = await commandRunner.run(['--verbose']);
        expect(result, equals(ExitCode.success.code));

        verify(() => logger.detail('Argument information:')).called(1);
        verify(() => logger.detail('  Top level options:')).called(1);
        verify(() => logger.detail('  - verbose: true')).called(1);
        verifyNever(() => logger.detail('    Command options:'));
      });

      test('enables verbose logging for sub commands', () async {
        final result = await commandRunner.run([
          '--verbose',
          'test',
          '--help',
        ]);
        expect(result, equals(ExitCode.success.code));

        verify(() => logger.detail('Argument information:')).called(1);
        verify(() => logger.detail('  Top level options:')).called(1);
        verify(() => logger.detail('  - verbose: true')).called(1);
        verify(() => logger.detail('  Command: test')).called(1);
        verify(() => logger.detail('    Command options:')).called(1);
        verify(() => logger.detail('    - help: true')).called(1);
      });
    });

    group('completion', () {
      test('is completion command runner', () {
        final commandRunner = FluttiumCommandRunner();
        expect(commandRunner, isA<CompletionCommandRunner<int>>());
      });

      test('fast track completion command', () async {
        final result = await commandRunner.run(['completion']);
        expect(result, equals(ExitCode.success.code));

        verifyNever(() => logger.detail(any()));
      });
    });

    test('if flutter version does not fit constraints', () async {
      flutterVersion = '0.0.0';

      final result = await commandRunner.run([
        'test',
        '--help',
      ]);
      expect(result, equals(ExitCode.unavailable.code));

      verify(
        () => logger.err('''
Version solving failed:
  The Fluttium CLI uses "${FluttiumDriver.flutterVersionConstraint}" as the version constraint for Flutter.
  The current Flutter version is "$flutterVersion" which is not supported by Fluttium.

Either update Flutter to a compatible version supported by the CLI or update the CLI to a compatible version of Flutter.'''),
      ).called(equals(1));
    });
  });
}
