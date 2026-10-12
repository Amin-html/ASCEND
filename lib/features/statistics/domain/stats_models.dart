import 'package:ascend/core/utils/day_key.dart';

/// Итоги одного локального дня (строка кэша daily_stats).
class DayStat {
  const DayStat({
    required this.dayKey,
    this.tasksCompleted = 0,
    this.tasksPlanned = 0,
    this.focusSeconds = 0,
    this.xpEarned = 0,
    this.planCompleted = false,
  });

  final String dayKey;
  final int tasksCompleted;
  final int tasksPlanned;
  final int focusSeconds;
  final int xpEarned;
  final bool planCompleted;
}

class StatsSummary {
  const StatsSummary({
    required this.days,
    required this.tasksCompleted,
    required this.focusSeconds,
    required this.xpEarned,
    required this.activeDays,
    required this.perfectDays,
  });

  final int days;
  final int tasksCompleted;
  final int focusSeconds;
  final int xpEarned;

  /// Дни, в которые выполнена хотя бы одна задача.
  final int activeDays;

  /// Дни, в которые выполнен весь запланированный список.
  final int perfectDays;

  bool get hasActivity => tasksCompleted > 0 || focusSeconds > 0 || xpEarned > 0;

  int get avgFocusSeconds => days == 0 ? 0 : (focusSeconds / days).round();

  int get avgXp => days == 0 ? 0 : (xpEarned / days).round();
}

/// Ряд из [days] подряд идущих дней, заканчивающийся днём [today].
/// Дни без записи заполняются нулями. Старые дни идут первыми.
List<DayStat> buildSeries(List<DayStat> stored, DateTime today, int days) {
  final byKey = {for (final s in stored) s.dayKey: s};
  final result = <DayStat>[];
  for (var i = days - 1; i >= 0; i--) {
    final key = dayKeyOf(DateTime(today.year, today.month, today.day - i));
    result.add(byKey[key] ?? DayStat(dayKey: key));
  }
  return result;
}

StatsSummary summarize(List<DayStat> series) {
  var tasks = 0;
  var focus = 0;
  var xp = 0;
  var active = 0;
  var perfect = 0;
  for (final s in series) {
    tasks += s.tasksCompleted;
    focus += s.focusSeconds;
    xp += s.xpEarned;
    if (s.tasksCompleted > 0) active++;
    if (s.planCompleted) perfect++;
  }
  return StatsSummary(
    days: series.length,
    tasksCompleted: tasks,
    focusSeconds: focus,
    xpEarned: xp,
    activeDays: active,
    perfectDays: perfect,
  );
}