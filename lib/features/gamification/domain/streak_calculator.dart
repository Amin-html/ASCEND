import 'dart:math' as math;

import 'package:ascend/core/utils/day_key.dart';

class StreakInfo {
  const StreakInfo({required this.current, required this.best});

  final int current;
  final int best;
}

DateTime _previousDay(DateTime d) => DateTime(d.year, d.month, d.day - 1);

DateTime _nextDay(DateTime d) => DateTime(d.year, d.month, d.day + 1);

/// [activeDays] — множество dayKey (yyyy-MM-dd), в которые была активность.
/// Текущая серия не обрывается, пока сегодняшний день не закончился:
/// если сегодня активности ещё нет, считаем серию, заканчивающуюся вчера.
StreakInfo calculateStreak({
  required Set<String> activeDays,
  required String today,
}) {
  if (activeDays.isEmpty) return const StreakInfo(current: 0, best: 0);

  var cursor = dateFromDayKey(today);
  if (!activeDays.contains(today)) cursor = _previousDay(cursor);

  var current = 0;
  while (activeDays.contains(dayKeyOf(cursor))) {
    current++;
    cursor = _previousDay(cursor);
  }

  final days = activeDays.map(dateFromDayKey).toList()..sort();
  var best = 0;
  var run = 0;
  DateTime? previous;
  for (final day in days) {
    if (previous != null && _nextDay(previous) == day) {
      run++;
    } else {
      run = 1;
    }
    best = math.max(best, run);
    previous = day;
  }

  return StreakInfo(current: current, best: best);
}