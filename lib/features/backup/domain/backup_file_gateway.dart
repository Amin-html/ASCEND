import 'dart:typed_data';

import 'package:ascend/features/backup/domain/backup_models.dart';

/// Выбор и сохранение файлов backup через системные диалоги.
abstract interface class BackupFileGateway {
  /// true — файл сохранён, false — пользователь отменил.
  Future<bool> save(BackupFile file);

  /// null — пользователь отменил.
  Future<Uint8List?> pick();
}