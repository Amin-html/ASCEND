import 'dart:typed_data';

class SafetyBackupEntry {
  const SafetyBackupEntry({
    required this.fileName,
    required this.modified,
    required this.sizeBytes,
  });

  final String fileName;
  final DateTime modified;
  final int sizeBytes;
}

/// Хранилище автоматических копий, которые делаются перед восстановлением.
abstract interface class SafetyBackupStore {
  Future<void> save(String fileName, Uint8List bytes);

  /// Новые сначала.
  Future<List<SafetyBackupEntry>> list();

  Future<Uint8List> read(String fileName);
}