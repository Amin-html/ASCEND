import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

import 'package:ascend/features/backup/domain/backup_format.dart';
import 'package:ascend/features/backup/domain/safety_backup_store.dart';

class FileSafetyBackupStore implements SafetyBackupStore {
  FileSafetyBackupStore({this.keep = 3});

  /// Сколько последних копий хранить.
  final int keep;

  static const String _suffix = '.${BackupFormat.fileExtension}';

  Future<Directory> _directory() async {
    final base = await getApplicationSupportDirectory();
    final dir = Directory('${base.path}${Platform.pathSeparator}safety_backups');
    await dir.create(recursive: true);
    return dir;
  }

  @override
  Future<void> save(String fileName, Uint8List bytes) async {
    final dir = await _directory();
    final file = File('${dir.path}${Platform.pathSeparator}$fileName');
    await file.writeAsBytes(bytes, flush: true);
    await _prune(dir);
  }

  @override
  Future<List<SafetyBackupEntry>> list() async {
    final dir = await _directory();
    final entries = <SafetyBackupEntry>[];
    await for (final entity in dir.list()) {
      if (entity is! File || !entity.path.endsWith(_suffix)) continue;
      final stat = await entity.stat();
      entries.add(
        SafetyBackupEntry(
          fileName: entity.uri.pathSegments.last,
          modified: stat.modified,
          sizeBytes: stat.size,
        ),
      );
    }
    entries.sort((a, b) => b.modified.compareTo(a.modified));
    return entries;
  }

  @override
  Future<Uint8List> read(String fileName) async {
    if (fileName.contains('/') ||
        fileName.contains(r'\') ||
        fileName.contains('..')) {
      throw ArgumentError.value(fileName, 'fileName', 'Invalid file name');
    }
    final dir = await _directory();
    return File('${dir.path}${Platform.pathSeparator}$fileName').readAsBytes();
  }

  Future<void> _prune(Directory dir) async {
    final files = <File>[];
    await for (final entity in dir.list()) {
      if (entity is File && entity.path.endsWith(_suffix)) files.add(entity);
    }
    // Имена содержат метку времени, поэтому сортировка по имени = по дате.
    files.sort((a, b) => b.path.compareTo(a.path));
    for (final file in files.skip(keep)) {
      await file.delete();
    }
  }
}