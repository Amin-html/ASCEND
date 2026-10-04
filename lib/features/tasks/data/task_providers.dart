import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ascend/core/database/database_providers.dart';
import 'package:ascend/core/services/service_providers.dart';
import 'package:ascend/features/gamification/data/gamification_providers.dart';
import 'package:ascend/features/tasks/data/drift_category_repository.dart';
import 'package:ascend/features/tasks/data/drift_task_actions.dart';
import 'package:ascend/features/tasks/data/drift_task_repository.dart';
import 'package:ascend/features/tasks/domain/category.dart';
import 'package:ascend/features/tasks/domain/category_repository.dart';
import 'package:ascend/features/tasks/domain/task.dart';
import 'package:ascend/features/tasks/domain/task_actions.dart';
import 'package:ascend/features/tasks/domain/task_repository.dart';

final taskRepositoryProvider = Provider<TaskRepository>(
      (ref) => DriftTaskRepository(ref.watch(appDatabaseProvider)),
);

final categoryRepositoryProvider = Provider<CategoryRepository>(
      (ref) => DriftCategoryRepository(ref.watch(appDatabaseProvider)),
);

final taskActionsProvider = Provider<TaskActions>(
      (ref) => DriftTaskActions(
    db: ref.watch(appDatabaseProvider),
    clock: ref.watch(clockProvider),
    ids: ref.watch(idGeneratorProvider),
    engine: ref.watch(xpEngineProvider),
  ),
);

final tasksByDayProvider = StreamProvider.family<List<Task>, String>(
      (ref, dayKey) => ref.watch(taskRepositoryProvider).watchByDay(dayKey),
);

final categoriesProvider = StreamProvider<List<Category>>(
      (ref) => ref.watch(categoryRepositoryProvider).watchAll(),
);