import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' show sha256;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ascend/core/database/app_database.dart';
import 'package:ascend/core/theme/app_theme.dart';
import 'package:ascend/features/backup/data/backup_providers.dart';
import 'package:ascend/features/backup/data/backup_service.dart';
import 'package:ascend/features/backup/domain/safety_backup_store.dart';
import 'package:ascend/features/backup/presentation/backup_screen.dart';

import '../../helpers/fakes.dart';
import 'backup_flow_test.dart' show FakeFiles;

/// Собирает корректный файл backup вручную и синхронно.
Uint8List buildBackup({bool encrypted = false}) {
  final payload = encrypted
      ? Uint8List.fromList([1, 2, 3, 4])
      : Uint8List.fromList(
    gzip.encode(
      utf8.encode(jsonEncode({'tables': <String, Object?>{}})),
    ),
  );
  final envelope = <String, Object?>{
    'magic': 'ASCEND_BACKUP',
    'backupVersion': 1,
    'schemaVersion': 1,
    'appVersion': '1.0.0',
    'createdAt': DateTime.utc(2026, 10, 4, 12).toIso8601String(),
    'encrypted': encrypted,
    'summary': {
      'tasks': 3,
      'completedTasks': 1,
      'goals': 2,
      'habits': 1,
      'notes': 0,
      'totalXp': 120,
    },
    if (encrypted)
      'kdf': {
        'name': 'pbkdf2-hmac-sha256',
        'iterations': 1000,
        'salt': base64Encode([1, 2, 3]),
      },
    'checksum': sha256.convert(payload).toString(),
    'payload': base64Encode(payload),
  };
  return Uint8List.fromList(utf8.encode(jsonEncode(envelope)));
}

void main() {
  late FakeFiles files;
  late AppDatabase db;

  Widget app() {
    final service = BackupService(
      db: db,
      settings: InMemorySettingsRepository(),
      clock: FakeClock(DateTime(2026, 10, 4, 10)),
      safetyStore: FakeSafetyBackupStore(),
      kdfIterations: 1000,
    );
    return ProviderScope(
      overrides: [
        backupServiceProvider.overrideWithValue(service),
        backupFileGatewayProvider.overrideWithValue(files),
        safetyBackupStoreProvider.overrideWithValue(FakeSafetyBackupStore()),
        safetyBackupsProvider.overrideWith(
              (ref) async => const <SafetyBackupEntry>[],
        ),
      ],
      child: MaterialApp(theme: AppTheme.dark, home: const BackupScreen()),
    );
  }

  setUp(() {
    files = FakeFiles();
    db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
  });

  testWidgets('shows the sections', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(find.text('Data & Backup'), findsOneWidget);
    expect(find.text('Create backup'), findsOneWidget);
    expect(find.text('Choose backup file'), findsOneWidget);
    expect(find.text('Safety copies'), findsOneWidget);
    expect(find.text('No safety copies yet.'), findsOneWidget);
  });

  testWidgets('create dialog validates the password', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Create backup'));
    await tester.pumpAndSettle();
    expect(find.text('Protect with password'), findsOneWidget);

    FilledButton createButton() => tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Create'),
    );

    expect(createButton().onPressed, isNotNull);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(createButton().onPressed, isNull);

    await tester.enterText(
      find.widgetWithText(TextField, 'Password'),
      'secret1',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Confirm password'),
      'secret2',
    );
    await tester.pump();
    expect(find.text('Passwords do not match'), findsOneWidget);
    expect(createButton().onPressed, isNull);

    await tester.enterText(
      find.widgetWithText(TextField, 'Confirm password'),
      'secret1',
    );
    await tester.pump();
    expect(createButton().onPressed, isNotNull);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Create backup'), findsOneWidget);
    expect(files.saved, isEmpty);
  });

  testWidgets('restore shows a preview of the chosen file', (tester) async {
    files.toPick = buildBackup();
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Choose backup file'));
    await tester.pumpAndSettle();

    expect(find.text('Restore backup?'), findsOneWidget);
    expect(find.text('3 (1 done)'), findsOneWidget);
    expect(find.text('120'), findsOneWidget);
    expect(find.textContaining('replaces all current data'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Restore backup?'), findsNothing);
  });

  testWidgets('encrypted backup asks for a password', (tester) async {
    files.toPick = buildBackup(encrypted: true);
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Choose backup file'));
    await tester.pumpAndSettle();

    expect(find.text('This backup is password protected'), findsOneWidget);
    FilledButton restoreButton() => tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Restore'),
    );
    expect(restoreButton().onPressed, isNull);

    await tester.enterText(
      find.widgetWithText(TextField, 'Backup password'),
      'secret',
    );
    await tester.pump();
    expect(restoreButton().onPressed, isNotNull);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
  });

  testWidgets('a file that is not a backup shows an error', (tester) async {
    files.toPick = Uint8List.fromList([1, 2, 3]);
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Choose backup file'));
    await tester.pumpAndSettle();

    expect(
      find.text('This is not a valid ASCEND backup file.'),
      findsOneWidget,
    );
  });
}