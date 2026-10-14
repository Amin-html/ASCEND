import 'package:ascend/core/utils/day_key.dart';
import 'package:ascend/core/utils/formatters.dart';
import 'package:ascend/features/notifications/domain/notification_models.dart';
import 'package:ascend/features/settings/domain/app_settings.dart';
import 'package:ascend/features/tasks/domain/task.dart';
import 'package:ascend/features/tasks/domain/task_enums.dart';

const int _idMask = 0x3FFFFFFF;

/// Идентификаторы вечерних напоминаний: база + смещение дня (0–6).
/// Больше любого id задачи (меньше 2^30), меньше 2^31.
const int dailyPlanIdBase = 1100000000;

/// Идентификатор тестового уведомления.
const int testNotificationId = 2000000000;

/// Стабильный между запусками id (String.hashCode для этого не годится).
/// FNV-1a, 30 бит.
int stableNotificationId(String key) {
  var hash = 0x811C9DC5;
  for (final unit in key.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0xFFFFFFFF;
  }
  return hash & _idMask;
}

/// Что и когда напомнить. Чистая функция: время приходит параметром.
///
/// [openTasks] — невыполненные задачи ближайших недель.
/// - Напоминание о задаче: у задачи есть время и «за сколько напомнить»,
///   момент напоминания ещё впереди и не дальше [reminderHorizonDays].
/// - Вечернее напоминание: на каждый из ближайших [planHorizonDays] дней,
///   где есть незавершённые задачи и время напоминания ещё не прошло.
/// Итог отсортирован по времени и обрезан до [maxCount] (iOS держит не
/// больше 64 запланированных уведомлений).
List<PlannedNotification> planNotifications({
  required DateTime now,
  required AppSettings settings,
  required List<Task> openTasks,
  int reminderHorizonDays = 14,
  int planHorizonDays = 7,
  int maxCount = 50,
}) {
  if (!settings.notificationsEnabled) return const [];

  final result = <PlannedNotification>[];
  final usedIds = <int>{};
  final horizon = now.add(Duration(days: reminderHorizonDays));

  for (final task in openTasks) {
    final start = task.startAt;
    final lead = task.reminderMinutesBefore;
    if (task.isCompleted ||
        task.status == TaskStatus.cancelled ||
        start == null ||
        lead == null) {
      continue;
    }
    final at = start.subtract(Duration(minutes: lead));
    if (!at.isAfter(now) || at.isAfter(horizon)) continue;

    var id = stableNotificationId('task:${task.id}');
    while (!usedIds.add(id)) {
      id = (id + 1) & _idMask;
    }
    result.add(
      PlannedNotification(
        id: id,
        title: task.title,
        body: lead == 0
            ? 'Starts now'
            : 'Starts in ${formatMinutes(lead)} (at ${timeLabel(start)})',
        at: at,
        payload: task.id,
      ),
    );
  }

  if (settings.dailyPlanReminderEnabled) {
    final minutes = settings.dailyPlanReminderMinutes.clamp(0, 1439).toInt();
    final openByDay = <String, int>{};
    for (final task in openTasks) {
      final key = task.dayKey;
      if (key == null || task.isCompleted) continue;
      openByDay[key] = (openByDay[key] ?? 0) + 1;
    }

    for (var i = 0; i < planHorizonDays; i++) {
      final day = DateTime(now.year, now.month, now.day + i);
      final at = DateTime(day.year, day.month, day.day, minutes ~/ 60, minutes % 60);
      if (!at.isAfter(now)) continue;

      final open = openByDay[dayKeyOf(day)] ?? 0;
      if (open == 0) continue;

      result.add(
        PlannedNotification(
          id: dailyPlanIdBase + i,
          title: "Today's plan",
          body: 'You still have ${plural(open, 'task')} to finish today.',
          at: at,
        ),
      );
    }
  }

  result.sort((a, b) => a.at.compareTo(b.at));
  return result.length > maxCount ? result.sublist(0, maxCount) : result;
}