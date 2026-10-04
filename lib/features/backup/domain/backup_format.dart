abstract final class BackupFormat {
  static const String magic = 'ASCEND_BACKUP';

  /// Версия контейнера. Растёт при изменении структуры файла.
  static const int backupVersion = 1;

  static const String fileExtension = 'plannerbackup';
  static const String appVersion = '1.0.0';

  static const int pbkdf2Iterations = 150000;
  static const int saltLength = 16;
}

String backupFileName(DateTime at, {String prefix = 'ascend-backup'}) {
  String two(int n) => n.toString().padLeft(2, '0');
  final date = '${at.year.toString().padLeft(4, '0')}${two(at.month)}${two(at.day)}';
  final time = '${two(at.hour)}${two(at.minute)}';
  return '$prefix-$date-$time.${BackupFormat.fileExtension}';
}