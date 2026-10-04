import 'package:drift/drift.dart';

import 'package:ascend/core/database/app_database.dart';
import 'package:ascend/features/backup/domain/backup_models.dart';
import 'package:ascend/features/tasks/domain/task_enums.dart';

class BackupSnapshot {
  const BackupSnapshot({required this.tables, required this.summary});

  final Map<String, Object?> tables;
  final BackupSummary summary;
}

List<Map<String, dynamic>> _json(Iterable<DataClass> rows) {
  return [for (final row in rows) row.toJson()];
}

List<D> _parse<D>(Object? raw, D Function(Map<String, dynamic>) fromJson) {
  if (raw is! List) {
    throw const FormatException('A table is missing in the backup.');
  }
  return [for (final item in raw) fromJson(item as Map<String, dynamic>)];
}

/// Чтение и полная замена содержимого БД. Единственное место, которое
/// знает список таблиц. При добавлении таблицы обновить export и replaceAll.
class BackupDatabaseIo {
  BackupDatabaseIo(this._db);

  final AppDatabase _db;

  /// Консистентный снимок всех таблиц в одной транзакции.
  Future<BackupSnapshot> export() {
    return _db.transaction(() async {
      final profiles = await _db.select(_db.userProfiles).get();
      final categories = await _db.select(_db.categories).get();
      final rules = await _db.select(_db.recurrenceRules).get();
      final goals = await _db.select(_db.goals).get();
      final milestones = await _db.select(_db.milestones).get();
      final habits = await _db.select(_db.habits).get();
      final tasks = await _db.select(_db.tasks).get();
      final notes = await _db.select(_db.notes).get();
      final habitLogs = await _db.select(_db.habitLogs).get();
      final sessions = await _db.select(_db.focusSessions).get();
      final xpEvents = await _db.select(_db.xpEvents).get();
      final achievements = await _db.select(_db.achievements).get();
      final stats = await _db.select(_db.dailyStats).get();

      return BackupSnapshot(
        tables: {
          'userProfiles': _json(profiles),
          'categories': _json(categories),
          'recurrenceRules': _json(rules),
          'goals': _json(goals),
          'milestones': _json(milestones),
          'habits': _json(habits),
          'tasks': _json(tasks),
          'notes': _json(notes),
          'habitLogs': _json(habitLogs),
          'focusSessions': _json(sessions),
          'xpEvents': _json(xpEvents),
          'achievements': _json(achievements),
          'dailyStats': _json(stats),
        },
        summary: BackupSummary(
          tasks: tasks.length,
          completedTasks: tasks
              .where((t) => t.status == TaskStatus.completed.index)
              .length,
          goals: goals.length,
          habits: habits.length,
          notes: notes.length,
          totalXp: xpEvents.fold<int>(0, (sum, e) => sum + e.amount),
        ),
      );
    });
  }

  /// Сначала разбирает весь файл, потом в одной транзакции удаляет
  /// старые данные и вставляет новые. Любая ошибка откатывает всё.
  Future<void> replaceAll(Map<String, Object?> tables) async {
    final profiles = _parse(tables['userProfiles'], UserProfileRow.fromJson);
    final categories = _parse(tables['categories'], CategoryRow.fromJson);
    final rules = _parse(tables['recurrenceRules'], RecurrenceRuleRow.fromJson);
    final goals = _parse(tables['goals'], GoalRow.fromJson);
    final milestones = _parse(tables['milestones'], MilestoneRow.fromJson);
    final habits = _parse(tables['habits'], HabitRow.fromJson);
    final tasks = _parse(tables['tasks'], TaskRow.fromJson);
    final notes = _parse(tables['notes'], NoteRow.fromJson);
    final habitLogs = _parse(tables['habitLogs'], HabitLogRow.fromJson);
    final sessions = _parse(tables['focusSessions'], FocusSessionRow.fromJson);
    final xpEvents = _parse(tables['xpEvents'], XpEventRow.fromJson);
    final achievements =
    _parse(tables['achievements'], AchievementRow.fromJson);
    final stats = _parse(tables['dailyStats'], DailyStatRow.fromJson);

    await _db.transaction(() async {
      // Сначала таблицы-потомки, потом родители (внешние ключи включены).
      await _db.delete(_db.notes).go();
      await _db.delete(_db.focusSessions).go();
      await _db.delete(_db.habitLogs).go();
      await _db.delete(_db.tasks).go();
      await _db.delete(_db.milestones).go();
      await _db.delete(_db.goals).go();
      await _db.delete(_db.habits).go();
      await _db.delete(_db.recurrenceRules).go();
      await _db.delete(_db.categories).go();
      await _db.delete(_db.xpEvents).go();
      await _db.delete(_db.achievements).go();
      await _db.delete(_db.dailyStats).go();
      await _db.delete(_db.userProfiles).go();

      // Родители раньше потомков.
      await _db.batch((b) {
        b.insertAll(_db.userProfiles, profiles);
        b.insertAll(_db.categories, categories);
        b.insertAll(_db.recurrenceRules, rules);
        b.insertAll(_db.goals, goals);
        b.insertAll(_db.milestones, milestones);
        b.insertAll(_db.habits, habits);
        b.insertAll(_db.tasks, tasks);
        b.insertAll(_db.notes, notes);
        b.insertAll(_db.habitLogs, habitLogs);
        b.insertAll(_db.focusSessions, sessions);
        b.insertAll(_db.xpEvents, xpEvents);
        b.insertAll(_db.achievements, achievements);
        b.insertAll(_db.dailyStats, stats);
      });

      if (profiles.isEmpty) {
        final now = DateTime.now();
        await _db.into(_db.userProfiles).insert(
          UserProfilesCompanion.insert(
            id: const Value(1),
            createdAt: now,
            updatedAt: now,
          ),
        );
      }
    });
  }
}