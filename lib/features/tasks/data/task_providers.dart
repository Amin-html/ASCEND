import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ascend/core/database/database_providers.dart';
import 'package:ascend/features/tasks/data/drift_category_repository.dart';
import 'package:ascend/features/tasks/data/drift_task_repository.dart';
import 'package:ascend/features/tasks/domain/category_repository.dart';
import 'package:ascend/features/tasks/domain/task_repository.dart';

final taskRepositoryProvider = Provider<TaskRepository>(
      (ref) => DriftTaskRepository(ref.watch(appDatabaseProvider)),
);

final categoryRepositoryProvider = Provider<CategoryRepository>(
      (ref) => DriftCategoryRepository(ref.watch(appDatabaseProvider)),
);