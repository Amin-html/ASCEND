import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

import 'package:ascend/features/backup/domain/backup_file_gateway.dart';
import 'package:ascend/features/backup/domain/backup_format.dart';
import 'package:ascend/features/backup/domain/backup_models.dart';

class FilePickerBackupFileGateway implements BackupFileGateway {
  @override
  Future<bool> save(BackupFile file) async {
    final target = await FilePicker.saveFile(
      dialogTitle: 'Save backup',
      fileName: file.fileName,
      bytes: file.bytes,
    );
    return target != null;
  }

  @override
  Future<Uint8List?> pick() async {
    // Фильтр по неизвестному расширению надёжно работает только на десктопе.
    // На телефонах показываем все файлы, содержимое проверяется при чтении.
    final desktop = Platform.isWindows || Platform.isLinux || Platform.isMacOS;
    final picked = await FilePicker.pickFile(
      dialogTitle: 'Choose a backup',
      type: desktop ? FileType.custom : FileType.any,
      allowedExtensions: desktop ? const [BackupFormat.fileExtension] : null,
    );
    if (picked == null) return null;
    return picked.readAsBytes();
  }
}