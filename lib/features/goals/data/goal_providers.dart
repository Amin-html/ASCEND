import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ascend/core/database/database_providers.dart';
import 'package:ascend/core/services/service_providers.dart';
import 'package:ascend/features/gamification/data/gamification_providers.dart';
import 'package:ascend/features/goals/data/drift_goal_actions.dart';
import 'package:ascend/features/goals/data/drift_goal_repository.dart';
import 'package:ascend/features/goals/domain/goal_actions.dart';
import 'package:ascend/features/goals/domain/goal_models.dart';
import 'package:ascend/features/goals/domain/goal_repository.dart';

final goalRepositoryProvider = Provider<GoalRepository>(
      (ref) => DriftGoalRepository(ref.watch(appDatabaseProvider)),
);

final goalActionsProvider = Provider<GoalActions>(
      (ref) => DriftGoalActions(
    db: ref.watch(appDatabaseProvider),
    clock: ref.watch(clockProvider),
    ids: ref.watch(idGeneratorProvider),
    engine: ref.watch(xpEngineProvider),
  ),
);

final goalsProvider = StreamProvider<List<GoalWithMilestones>>(
      (ref) => ref.watch(goalRepositoryProvider).watchAll(),
);

final goalProvider = StreamProvider.family<GoalWithMilestones?, String>(
      (ref, id) => ref.watch(goalRepositoryProvider).watchById(id),
);