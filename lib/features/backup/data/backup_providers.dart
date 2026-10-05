import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ascend/core/database/database_providers.dart';
import 'package:ascend/core/services/service_providers.dart';
import 'package:ascend/features/backup/data/backup_service.dart';
import 'package:ascend/features/backup/data/file_picker_backup_gateway.dart';
import 'package:ascend/features/backup/data/file_safety_backup_store.dart';
import 'package:ascend/features/backup/domain/backup_file_gateway.dart';
import 'package:ascend/features/backup/domain/safety_backup_store.dart';
import 'package:ascend/features/settings/data/settings_providers.dart';

final safetyBackupStoreProvider = Provider<SafetyBackupStore>(
      (ref) => FileSafetyBackupStore(),
);

final backupFileGatewayProvider = Provider<BackupFileGateway>(
      (ref) => FilePickerBackupFileGateway(),
);

final backupServiceProvider = Provider<BackupService>(
      (ref) => BackupService(
    db: ref.watch(appDatabaseProvider),
    settings: ref.watch(settingsRepositoryProvider),
    clock: ref.watch(clockProvider),
    safetyStore: ref.watch(safetyBackupStoreProvider),
  ),
);

final safetyBackupsProvider =
FutureProvider.autoDispose<List<SafetyBackupEntry>>(
      (ref) => ref.watch(safetyBackupStoreProvider).list(),
);