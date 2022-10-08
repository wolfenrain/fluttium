// Copyright (c) 2022, Very Good Ventures
// https://verygood.ventures
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file or at
// https://opensource.org/licenses/MIT.

import 'dart:io';

import 'package:fluttium_cli/src/command_runner.dart';
import 'package:fluttium_cli/src/commands/commands.dart';
import 'package:fluttium_cli/src/version.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pub_updater/pub_updater.dart';
import 'package:test/test.dart';

class FakeProcessResult extends Fake implements ProcessResult {}

class MockLogger extends Mock implements Logger {}

class MockProgress extends Mock implements Progress {}

class MockPubUpdater extends Mock implements PubUpdater {}

void main() {
  const latestVersion = '0.0.0';

  group('update', () {
    late PubUpdater pubUpdater;
    late Logger logger;
    late FluttiumCliCommandRunner commandRunner;

    setUp(() {
      final progress = MockProgress();
      final progressLogs = <String>[];
      pubUpdater = MockPubUpdater();
      logger = MockLogger();
      commandRunner = FluttiumCliCommandRunner(
        logger: logger,
        pubUpdater: pubUpdater,
      );

      when(
        () => pubUpdater.getLatestVersion(any()),
      ).thenAnswer((_) async => packageVersion);
      when(() => progress.complete(any())).thenAnswer((_) {
        final message = _.positionalArguments.elementAt(0) as String?;
        if (message != null) progressLogs.add(message);
      });
      when(() => logger.progress(any())).thenReturn(progress);
      when(
        () => pubUpdater.isUpToDate(
          packageName: any(named: 'packageName'),
          currentVersion: any(named: 'currentVersion'),
        ),
      ).thenAnswer((_) => Future.value(true));
    });

    test('can be instantiated without a pub updater', () {
      final command = UpdateCommand(logger: logger);
      expect(command, isNotNull);
    });

    test(
      'handles pub latest version query errors',
      () async {
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
    );

    test(
      'handles pub update errors',
      () async {
        when(
          () => pubUpdater.getLatestVersion(any()),
        ).thenAnswer((_) async => latestVersion);
        when(
          () => pubUpdater.update(packageName: any(named: 'packageName')),
        ).thenThrow(Exception('oops'));
        final result = await commandRunner.run(['update']);
        expect(result, equals(ExitCode.software.code));
        verify(() => logger.progress('Checking for updates')).called(1);
        verify(() => logger.err('Exception: oops'));
        verify(
          () => pubUpdater.update(packageName: any(named: 'packageName')),
        ).called(1);
      },
    );

    test(
      'updates when newer version exists',
      () async {
        when(
          () => pubUpdater.getLatestVersion(any()),
        ).thenAnswer((_) async => latestVersion);
        when(
          () => pubUpdater.update(packageName: packageName),
        ).thenAnswer((_) => Future.value(FakeProcessResult()));
        when(() => logger.progress(any())).thenReturn(MockProgress());
        final result = await commandRunner.run(['update']);
        expect(result, equals(ExitCode.success.code));
        verify(() => logger.progress('Checking for updates')).called(1);
        verify(() => logger.progress('Updating to $latestVersion')).called(1);
        verify(() => pubUpdater.update(packageName: packageName)).called(1);
      },
    );

    test(
      'does not update when already on latest version',
      () async {
        when(
          () => pubUpdater.getLatestVersion(any()),
        ).thenAnswer((_) async => packageVersion);
        when(() => logger.progress(any())).thenReturn(MockProgress());
        final result = await commandRunner.run(['update']);
        expect(result, equals(ExitCode.success.code));
        verify(
          () => logger.info('CLI is already at the latest version.'),
        ).called(1);
        verifyNever(() => logger.progress('Updating to $latestVersion'));
        verifyNever(() => pubUpdater.update(packageName: packageName));
      },
    );
  });
}
