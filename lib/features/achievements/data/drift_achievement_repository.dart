import 'package:drift/drift.dart';

import 'package:ascend/core/database/app_database.dart';
import 'package:ascend/features/achievements/domain/achievement_models.dart';
import 'package:ascend/features/achievements/domain/achievement_repository.dart';
import 'package:ascend/features/goals/domain/goal_models.dart';
import 'package:ascend/features/tasks/domain/task_enums.dart';

class DriftAchievementRepository implements AchievementRepository {
  DriftAchievementRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<AchievementCounts> watchCounts() {
    // Один запрос на все счётчики. Обновляется при любом изменении
    // перечисленных таблиц.
    final query = _db.customSelect(
      'SELECT '
          '(SELECT COUNT(*) FROM tasks WHERE status = ?) AS completed_tasks, '
          '(SELECT COALESCE(SUM(actual_seconds), 0) FROM focus_sessions) '
          'AS focus_seconds, '
          '(SELECT COUNT(*) FROM goals WHERE status = ?) AS completed_goals, '
          '(SELECT COALESCE(SUM(amount), 0) FROM xp_events) AS total_xp',
      variables: [
        Variable.withInt(TaskStatus.completed.index),
        Variable.withInt(GoalStatus.completed.index),
      ],
      readsFrom: {_db.tasks, _db.focusSessions, _db.goals, _db.xpEvents},
    );

    return query.watchSingle().map(
          (row) => AchievementCounts(
        completedTasks: row.read<int>('completed_tasks'),
        focusSeconds: row.read<int>('focus_seconds'),
        completedGoals: row.read<int>('completed_goals'),
        totalXp: row.read<int>('total_xp'),
      ),
    );
  }

  @override
  Stream<Map<String, DateTime>> watchUnlocked() {
    final query = _db.select(_db.achievements)
      ..where((a) => a.unlockedAt.isNotNull());
    return query.watch().map(
          (rows) => {for (final r in rows) r.code: r.unlockedAt!},
    );
  }
}