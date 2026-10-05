import 'dart:typed_data';

import 'package:ascend/features/backup/data/backup_service.dart';
import 'package:ascend/features/backup/domain/backup_exceptions.dart';
import 'package:ascend/features/backup/domain/backup_file_gateway.dart';
import 'package:ascend/features/backup/domain/backup_models.dart';
import 'package:ascend/features/backup/domain/safety_backup_store.dart';

enum FlowStatus { done, cancelled, failed }

class FlowResult {
  const FlowResult._(this.status, this.message);
  const FlowResult.done(String message) : this._(FlowStatus.done, message);
  const FlowResult.failed(String message) : this._(FlowStatus.failed, message);
  const FlowResult.cancelled() : this._(FlowStatus.cancelled, '');

  final FlowStatus status;
  final String message;
}

/// Ответ пользователя в диалоге создания. password == null: без шифрования.
class CreateChoice {
  const CreateChoice({this.password});

  final String? password;
}

/// Подтверждение восстановления. password нужен только для зашифрованных.
class RestoreChoice {
  const RestoreChoice({this.password});

  final String? password;
}

/// Все вопросы пользователю. В приложении это диалоги, в тестах сценарий.
abstract interface class BackupPrompts {
  /// null — пользователь отменил.
  Future<CreateChoice?> askCreate();

  /// null — пользователь отменил. [error] — причина повторного вопроса.
  Future<RestoreChoice?> askRestore(BackupHeader header, {String? error});
}

/// Сценарии «создать» и «восстановить» целиком, без знания про виджеты.
class BackupFlow {
  BackupFlow({
    required this._service,
    required this._files,
    required this._safety,
    required this._prompts,
    this._onBusy,
  });

  final BackupService _service;
  final BackupFileGateway _files;
  final SafetyBackupStore _safety;
  final BackupPrompts _prompts;
  final void Function(bool busy)? _onBusy;

  /// Оборачивает тяжёлую работу, чтобы UI мог показать индикатор.
  Future<T> _heavy<T>(Future<T> Function() work) async {
    _onBusy?.call(true);
    try {
      return await work();
    } finally {
      _onBusy?.call(false);
    }
  }

  Future<FlowResult> create() async {
    final choice = await _prompts.askCreate();
    if (choice == null) return const FlowResult.cancelled();

    try {
      final file = await _heavy(
            () => _service.createBackup(password: choice.password),
      );
      final saved = await _files.save(file);
      if (!saved) return const FlowResult.cancelled();
      return FlowResult.done(
        choice.password == null ? 'Backup saved' : 'Encrypted backup saved',
      );
    } on BackupException catch (e) {
      return FlowResult.failed(e.message);
    } on Object {
      return const FlowResult.failed('Could not create the backup.');
    }
  }

  Future<FlowResult> restoreFromFile() async {
    final Uint8List? bytes;
    try {
      bytes = await _files.pick();
    } on Object {
      return const FlowResult.failed('Could not open the file.');
    }
    if (bytes == null) return const FlowResult.cancelled();
    return restoreBytes(bytes);
  }

  Future<FlowResult> restoreSafety(String fileName) async {
    final Uint8List bytes;
    try {
      bytes = await _safety.read(fileName);
    } on Object {
      return const FlowResult.failed('Could not read the safety copy.');
    }
    return restoreBytes(bytes);
  }

  Future<FlowResult> restoreBytes(Uint8List bytes) async {
    final ParsedBackup parsed;
    try {
      parsed = _service.inspect(bytes);
    } on BackupException catch (e) {
      return FlowResult.failed(e.message);
    } on Object {
      return const FlowResult.failed('This is not a valid ASCEND backup file.');
    }

    String? error;
    while (true) {
      final choice = await _prompts.askRestore(parsed.header, error: error);
      if (choice == null) return const FlowResult.cancelled();

      try {
        final header = await _heavy(
              () => _service.restore(bytes, password: choice.password),
        );
        final s = header.summary;
        return FlowResult.done(
          'Backup restored • ${s.tasks} tasks, ${s.goals} goals',
        );
      } on BackupWrongPasswordException catch (e) {
        error = e.message;
      } on BackupPasswordRequiredException catch (e) {
        error = e.message;
      } on BackupException catch (e) {
        return FlowResult.failed(e.message);
      } on Object {
        return const FlowResult.failed(
          'Restore failed. Your data was not changed.',
        );
      }
    }
  }
}