import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ascend/core/database/database_providers.dart';
import 'package:ascend/core/services/service_providers.dart';
import 'package:ascend/features/gamification/data/gamification_providers.dart';
import 'package:ascend/features/habits/data/drift_habit_actions.dart';
import 'package:ascend/features/habits/data/drift_habit_repository.dart';
import 'package:ascend/features/habits/domain/habit_actions.dart';
import 'package:ascend/features/habits/domain/habit_models.dart';
import 'package:ascend/features/habits/domain/habit_repository.dart';

final habitRepositoryProvider = Provider<HabitRepository>(
      (ref) => DriftHabitRepository(ref.watch(appDatabaseProvider)),
);

final habitActionsProvider = Provider<HabitActions>(
      (ref) => DriftHabitActions(
    db: ref.watch(appDatabaseProvider),
    clock: ref.watch(clockProvider),
    ids: ref.watch(idGeneratorProvider),
    engine: ref.watch(xpEngineProvider),
  ),
);

final habitsProvider = StreamProvider<List<HabitProgress>>(
      (ref) => ref.watch(habitRepositoryProvider).watchAll(),
);