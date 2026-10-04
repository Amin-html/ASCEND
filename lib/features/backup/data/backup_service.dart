import 'dart:typed_data';

import 'package:ascend/core/database/app_database.dart';
import 'package:ascend/core/services/clock.dart';
import 'package:ascend/features/backup/data/backup_codec.dart';
import 'package:ascend/features/backup/data/backup_database_io.dart';
import 'package:ascend/features/backup/domain/backup_exceptions.dart';
import 'package:ascend/features/backup/domain/backup_format.dart';
import 'package:ascend/features/backup/domain/backup_migrations.dart';
import 'package:ascend/features/backup/domain/backup_models.dart';
import 'package:ascend/features/backup/domain/safety_backup_store.dart';
import 'package:ascend/features/settings/domain/app_settings.dart';
import 'package:ascend/features/settings/domain/settings_repository.dart';

class BackupService {
  BackupService({
    required AppDatabase db,
    required this._settings,
    required this._clock,
    required this._safetyStore,
    this._codec = const BackupCodec(),
    this._kdfIterations = BackupFormat.pbkdf2Iterations,
  })  : _db = db,
        _io = BackupDatabaseIo(db);

  final AppDatabase _db;
  final BackupDatabaseIo _io;
  final SettingsRepository _settings;
  final Clock _clock;
  final SafetyBackupStore _safetyStore;
  final BackupCodec _codec;
  final int _kdfIterations;

  /// Собирает backup всех данных. С паролем содержимое шифруется.
  Future<BackupFile> createBackup({
    String? password,
    String filePrefix = 'ascend-backup',
  }) async {
    final snapshot = await _io.export();
    final now = _clock.now();

    final bytes = await _codec.encode(
      payload: {
        'tables': snapshot.tables,
        'settings': _settings.load().toJson(),
      },
      schemaVersion: _db.schemaVersion,
      createdAt: now,
      summary: snapshot.summary,
      password: password,
      iterations: _kdfIterations,
    );
    return BackupFile(
      fileName: backupFileName(now, prefix: filePrefix),
      bytes: bytes,
    );
  }

  /// Предпросмотр без пароля: структура, версия, контрольная сумма.
  ParsedBackup inspect(Uint8List bytes) {
    final parsed = _codec.parse(bytes);
    if (parsed.header.schemaVersion > _db.schemaVersion) {
      throw const BackupNewerVersionException();
    }
    return parsed;
  }

  /// Полная замена текущих данных содержимым backup.
  /// Перед заменой сохраняется копия текущих данных.
  Future<BackupHeader> restore(Uint8List bytes, {String? password}) async {
    final parsed = inspect(bytes);
    final payload = await _codec.readPayload(parsed, password: password);

    final migrated = const BackupMigrations().upgrade(
      payload,
      from: parsed.header.schemaVersion,
      to: _db.schemaVersion,
    );

    final tables = migrated['tables'];
    if (tables is! Map<String, dynamic>) {
      throw const BackupCorruptedException();
    }

    try {
      final safety = await createBackup(filePrefix: 'safety-before-restore');
      await _safetyStore.save(safety.fileName, safety.bytes);
    } on Object {
      throw const BackupRestoreFailedException(
        'Could not save a safety copy of your current data. Nothing was changed.',
      );
    }

    try {
      await _io.replaceAll(tables);
    } on Object {
      throw const BackupRestoreFailedException();
    }

    final settings = migrated['settings'];
    if (settings is Map<String, dynamic>) {
      await _settings.save(AppSettings.fromJson(settings));
    }
    return parsed.header;
  }
}