import 'dart:io';

import 'package:fluttium_cli/src/command_runner.dart';
import 'package:fluttium_cli/src/commands/commands.dart';
import 'package:fluttium_cli/src/version.dart';
import 'package:mason/mason.dart' hide packageVersion;
import 'package:mocktail/mocktail.dart';
import 'package:pub_updater/pub_updater.dart';
import 'package:test/test.dart';

import '../../helpers/helpers.dart';

class _MockPubUpdater extends Mock implements PubUpdater {}

void main() {
  const latestVersion = '0.0.0';

  group('update', () {
    late PubUpdater pubUpdater;

    setUp(() {
      pubUpdater = _MockPubUpdater();

      when(
        () => pubUpdater.getLatestVersion(any()),
      ).thenAnswer((_) async => packageVersion);
    });

    test('can be instantiated without a pub updater', () {
      final command = UpdateCommand(logger: Logger());
      expect(command, isNotNull);
    });

    test(
      'handles pub latest version query errors',
      withRunner(
        pubUpdater: () => pubUpdater,
        (commandRunner, logger, printLogs, processManager) async {
          when(
            () => pubUpdater.getLatestVersion(any()),
          ).thenThrow(Exception('oops'));

          final result = await commandRunner.run(['update']);
          expect(result, equals(ExitCode.software.code));

          verify(() => logger.progress('Checking for updates')).called(1);
          verify(() => logger.err('Exception: oops'));
          verifyNever(
            () => pubUpdater.update(packageName: any(named: 'packageName')),
          );
        },
      ),
    );

    test(
      'handles pub update errors',
      withRunner(
        pubUpdater: () => pubUpdater,
        (commandRunner, logger, printLogs, processManager) async {
          when(
            () => pubUpdater.getLatestVersion(any()),
          ).thenAnswer((_) async => latestVersion);
          when(
            () => pubUpdater.update(packageName: any(named: 'packageName')),
          ).thenThrow(Exception('oops'));

          final result = await commandRunner.run(['update']);
          expect(result, equals(ExitCode.software.code));

          verify(() => logger.progress('Checking for updates')).called(1);
          verify(
            () => pubUpdater.update(packageName: any(named: 'packageName')),
          ).called(1);
        },
      ),
    );

    test(
      'updates when newer version exists',
      withRunner(
        pubUpdater: () => pubUpdater,
        (commandRunner, logger, printLogs, processManager) async {
          when(
            () => pubUpdater.getLatestVersion(any()),
          ).thenAnswer((_) async => latestVersion);
          when(
            () => pubUpdater.update(packageName: packageName),
          ).thenAnswer((_) => Future.value(ProcessResult(0, 0, '', '')));

          final result = await commandRunner.run(['update']);
          expect(result, equals(ExitCode.success.code));

          verify(() => logger.progress('Checking for updates')).called(1);
          verify(() => logger.progress('Updating to $latestVersion')).called(1);
          verify(() => pubUpdater.update(packageName: packageName)).called(1);
        },
      ),
    );

    test(
      'does not update when already on latest version',
      withRunner(
        pubUpdater: () => pubUpdater,
        (commandRunner, logger, printLogs, processManager) async {
          when(
            () => pubUpdater.getLatestVersion(any()),
          ).thenAnswer((_) async => packageVersion);

          final result = await commandRunner.run(['update']);
          expect(result, equals(ExitCode.success.code));

          verify(
            () => logger.info('CLI is already at the latest version.'),
          ).called(1);
          verifyNever(() => logger.progress('Updating to $latestVersion'));
          verifyNever(() => pubUpdater.update(packageName: packageName));
        },
      ),
    );
  });
}
