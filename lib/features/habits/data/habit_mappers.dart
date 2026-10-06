import 'package:drift/drift.dart';

import 'package:ascend/core/database/app_database.dart';
import 'package:ascend/features/habits/domain/habit_models.dart';

Habit habitFromRow(HabitRow r) => Habit(
  id: r.id,
  name: r.name,
  description: r.description,
  weekdaysMask: r.weekdaysMask,
  xpReward: r.xpReward,
  isArchived: r.isArchived,
  createdAt: r.createdAt,
  updatedAt: r.updatedAt,
);

/// frequencyType и targetPerPeriod намеренно не трогаем: при обновлении
/// они сохраняют значения из БД, при вставке берутся значения по умолчанию.
HabitsCompanion habitToCompanion(Habit h) => HabitsCompanion(
  id: Value(h.id),
  name: Value(h.name),
  description: Value(h.description),
  weekdaysMask: Value(h.weekdaysMask),
  xpReward: Value(h.xpReward),
  isArchived: Value(h.isArchived),
  createdAt: Value(h.createdAt),
  updatedAt: Value(h.updatedAt),
);