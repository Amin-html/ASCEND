import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ascend/core/database/database_providers.dart';
import 'package:ascend/core/services/service_providers.dart';
import 'package:ascend/features/focus/data/drift_focus_actions.dart';
import 'package:ascend/features/focus/data/drift_focus_repository.dart';
import 'package:ascend/features/focus/domain/focus_actions.dart';
import 'package:ascend/features/focus/domain/focus_models.dart';
import 'package:ascend/features/focus/domain/focus_repository.dart';
import 'package:ascend/features/gamification/data/gamification_providers.dart';
import 'package:ascend/features/tasks/data/task_providers.dart';
import 'package:ascend/features/tasks/domain/task.dart';

final focusRepositoryProvider = Provider<FocusRepository>(
      (ref) => DriftFocusRepository(ref.watch(appDatabaseProvider)),
);

final focusActionsProvider = Provider<FocusActions>(
      (ref) => DriftFocusActions(
    db: ref.watch(appDatabaseProvider),
    clock: ref.watch(clockProvider),
    ids: ref.watch(idGeneratorProvider),
    engine: ref.watch(xpEngineProvider),
  ),
);

final focusSecondsForDayProvider = StreamProvider.family<int, String>(
      (ref, dayKey) =>
      ref.watch(focusRepositoryProvider).watchSecondsForDay(dayKey),
);

final recentFocusProvider = StreamProvider<List<FocusSessionEntry>>(
      (ref) => ref.watch(focusRepositoryProvider).watchRecent(),
);

/// Задача, переданная в экран фокуса по ссылке (может быть не на сегодня).
final focusTaskProvider = FutureProvider.autoDispose.family<Task?, String>(
      (ref, id) => ref.watch(taskRepositoryProvider).getById(id),
);