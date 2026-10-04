import 'package:ascend/features/backup/domain/backup_exceptions.dart';

typedef _Step = Map<String, Object?> Function(Map<String, Object?> payload);

/// Цепочка обновления старых backup до текущей схемы БД.
/// Когда поднимется schemaVersion, сюда добавляется шаг `{1: _v1ToV2}`.
class BackupMigrations {
  const BackupMigrations();

  static const Map<int, _Step> _steps = {};

  Map<String, Object?> upgrade(
      Map<String, Object?> payload, {
        required int from,
        required int to,
      }) {
    var data = payload;
    for (var version = from; version < to; version++) {
      final step = _steps[version];
      if (step == null) {
        throw const BackupInvalidFileException(
          'This backup was made by an unsupported older version.',
        );
      }
      data = step(data);
    }
    return data;
  }
}