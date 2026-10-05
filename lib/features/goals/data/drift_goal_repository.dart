import 'package:drift/drift.dart';

import 'package:ascend/core/database/app_database.dart';
import 'package:ascend/features/goals/data/goal_mappers.dart';
import 'package:ascend/features/goals/domain/goal_models.dart';
import 'package:ascend/features/goals/domain/goal_repository.dart';

class DriftGoalRepository implements GoalRepository {
  DriftGoalRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<List<GoalWithMilestones>> watchAll() {
    final query = _db.select(_db.goals).join([
      leftOuterJoin(
        _db.milestones,
        _db.milestones.goalId.equalsExp(_db.goals.id),
      ),
    ])
      ..orderBy([
        OrderingTerm.desc(_db.goals.createdAt),
        OrderingTerm.asc(_db.goals.id),
        OrderingTerm.asc(_db.milestones.sortOrder),
        OrderingTerm.asc(_db.milestones.createdAt),
      ]);
    return query.watch().map(_group);
  }

  @override
  Stream<GoalWithMilestones?> watchById(String id) {
    final query = _db.select(_db.goals).join([
      leftOuterJoin(
        _db.milestones,
        _db.milestones.goalId.equalsExp(_db.goals.id),
      ),
    ])
      ..where(_db.goals.id.equals(id))
      ..orderBy([
        OrderingTerm.asc(_db.milestones.sortOrder),
        OrderingTerm.asc(_db.milestones.createdAt),
      ]);
    return query.watch().map((rows) {
      final grouped = _group(rows);
      return grouped.isEmpty ? null : grouped.first;
    });
  }

  List<GoalWithMilestones> _group(List<TypedResult> rows) {
    final goals = <String, Goal>{};
    final milestones = <String, List<Milestone>>{};

    for (final row in rows) {
      final goalRow = row.readTable(_db.goals);
      goals.putIfAbsent(goalRow.id, () => goalFromRow(goalRow));
      final list = milestones.putIfAbsent(goalRow.id, () => <Milestone>[]);
      final milestoneRow = row.readTableOrNull(_db.milestones);
      if (milestoneRow != null) list.add(milestoneFromRow(milestoneRow));
    }

    return [
      for (final entry in goals.entries)
        GoalWithMilestones(
          goal: entry.value,
          milestones: milestones[entry.key] ?? const <Milestone>[],
        ),
    ];
  }
}