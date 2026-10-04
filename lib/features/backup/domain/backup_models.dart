import 'dart:typed_data';

/// Краткое содержимое backup. Лежит в заголовке открыто, чтобы показать
/// предпросмотр до ввода пароля.
class BackupSummary {
  const BackupSummary({
    this.tasks = 0,
    this.completedTasks = 0,
    this.goals = 0,
    this.habits = 0,
    this.notes = 0,
    this.totalXp = 0,
  });

  factory BackupSummary.fromJson(Map<String, Object?> json) {
    int read(String key) {
      final value = json[key];
      return value is int ? value : 0;
    }

    return BackupSummary(
      tasks: read('tasks'),
      completedTasks: read('completedTasks'),
      goals: read('goals'),
      habits: read('habits'),
      notes: read('notes'),
      totalXp: read('totalXp'),
    );
  }

  final int tasks;
  final int completedTasks;
  final int goals;
  final int habits;
  final int notes;
  final int totalXp;

  Map<String, Object?> toJson() => {
    'tasks': tasks,
    'completedTasks': completedTasks,
    'goals': goals,
    'habits': habits,
    'notes': notes,
    'totalXp': totalXp,
  };
}

class BackupHeader {
  const BackupHeader({
    required this.backupVersion,
    required this.schemaVersion,
    required this.appVersion,
    required this.createdAt,
    required this.encrypted,
    required this.summary,
    this.kdfIterations,
    this.kdfSalt,
  });

  final int backupVersion;
  final int schemaVersion;
  final String appVersion;
  final DateTime createdAt;
  final bool encrypted;
  final BackupSummary summary;
  final int? kdfIterations;
  final Uint8List? kdfSalt;
}

/// Файл, прошедший проверку структуры и контрольной суммы.
class ParsedBackup {
  const ParsedBackup({required this.header, required this.payloadBytes});

  final BackupHeader header;

  /// Содержимое как хранится в файле: gzip или шифртекст.
  final Uint8List payloadBytes;
}

class BackupFile {
  const BackupFile({required this.fileName, required this.bytes});

  final String fileName;
  final Uint8List bytes;
}