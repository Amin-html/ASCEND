import 'dart:typed_data';

import 'package:ascend/core/services/clock.dart';
import 'package:ascend/core/services/id_generator.dart';
import 'package:ascend/features/backup/domain/safety_backup_store.dart';
import 'package:ascend/features/settings/domain/app_settings.dart';
import 'package:ascend/features/settings/domain/settings_repository.dart';

class FakeClock implements Clock {
  FakeClock(this.current);

  DateTime current;

  @override
  DateTime now() => current;
}

class SequentialIds implements IdGenerator {
  int _n = 0;

  @override
  String newId() => 'id_${_n++}';
}

class InMemorySettingsRepository implements SettingsRepository {
  InMemorySettingsRepository([this.current = const AppSettings()]);

  AppSettings current;

  @override
  AppSettings load() => current;

  @override
  Future<void> save(AppSettings settings) async {
    current = settings;
  }
}

class FakeSafetyBackupStore implements SafetyBackupStore {
  final Map<String, Uint8List> files = {};

  @override
  Future<void> save(String fileName, Uint8List bytes) async {
    files[fileName] = bytes;
  }

  @override
  Future<List<SafetyBackupEntry>> list() async {
    return [
      for (final entry in files.entries)
        SafetyBackupEntry(
          fileName: entry.key,
          modified: DateTime(2026),
          sizeBytes: entry.value.length,
        ),
    ];
  }

  @override
  Future<Uint8List> read(String fileName) async => files[fileName]!;
}