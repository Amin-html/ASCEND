import 'dart:math' as math;

import 'package:ascend/core/utils/day_key.dart';
import 'package:ascend/features/habits/domain/habit_models.dart';

class HabitStreak {
  const HabitStreak({required this.current, required this.best});

  final int current;
  final int best;
}

DateTime _nextDay(DateTime d) => DateTime(d.year, d.month, d.day + 1);

/// Нет ли запланированных дней строго между [a] и [b].
/// Цикл короткий: при непустой маске запланированный день находится
/// максимум за 7 шагов.
bool _noScheduledBetween(DateTime a, DateTime b, int mask) {
  var d = _nextDay(a);
  while (d.isBefore(b)) {
    if (isDayScheduled(mask, d)) return false;
    d = _nextDay(d);
  }
  return true;
}

/// Серия считается по запланированным дням: незапланированные дни её
/// не рвут. Текущая серия жива, пока не пропущен ни один запланированный
/// день между последней отметкой и сегодняшним днём (сегодня ещё можно успеть).
HabitStreak calculateHabitStreak({
  required Set<String> doneDays,
  required int weekdaysMask,
  required String today,
}) {
  final mask = weekdaysMask & allWeekdaysMask;
  if (doneDays.isEmpty || mask == 0) {
    return const HabitStreak(current: 0, best: 0);
  }

  final days = doneDays.map(dateFromDayKey).toList()..sort();

  var run = 1;
  var best = 1;
  for (var i = 1; i < days.length; i++) {
    if (_noScheduledBetween(days[i - 1], days[i], mask)) {
      run++;
    } else {
      run = 1;
    }
    best = math.max(best, run);
  }

  final last = days.last;
  final now = dateFromDayKey(today);
  final alive = !last.isBefore(now) || _noScheduledBetween(last, now, mask);

  return HabitStreak(current: alive ? run : 0, best: best);
}