import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ascend/core/services/service_providers.dart';
import 'package:ascend/core/utils/day_key.dart';
import 'package:ascend/features/notifications/data/local_notification_service.dart';
import 'package:ascend/features/notifications/domain/notification_models.dart';
import 'package:ascend/features/notifications/domain/notification_planner.dart';
import 'package:ascend/features/notifications/domain/notification_service.dart';
import 'package:ascend/features/settings/data/settings_providers.dart';
import 'package:ascend/features/tasks/data/task_providers.dart';
import 'package:ascend/features/tasks/domain/task.dart';

final notificationServiceProvider = Provider<NotificationService>(
      (ref) => LocalNotificationService(),
);

/// false: уведомления на этом устройстве недоступны.
final notificationsAvailableProvider = FutureProvider<bool>(
      (ref) => ref.watch(notificationServiceProvider).initialize(),
);

/// Невыполненные задачи на ближайшие две недели.
final openTasksWindowProvider = StreamProvider<List<Task>>((ref) {
  final now = ref.watch(clockProvider).now();
  final from = DateTime(now.year, now.month, now.day);
  final to = DateTime(from.year, from.month, from.day + 14);
  return ref
      .watch(taskRepositoryProvider)
      .watchOpenInRange(dayKeyOf(from), dayKeyOf(to));
});

/// Что должно быть запланировано сейчас. null, пока грузятся данные.
final plannedNotificationsProvider = Provider<List<PlannedNotification>?>((
    ref,
    ) {
  final tasks = ref.watch(openTasksWindowProvider).value;
  if (tasks == null) return null;
  final settings = ref.watch(settingsProvider);
  final now = ref.watch(clockProvider).now();
  return planNotifications(now: now, settings: settings, openTasks: tasks);
});