/// Все семь дней. Бит 0 = понедельник, бит 6 = воскресенье.
const int allWeekdaysMask = 127;

bool isDayScheduled(int mask, DateTime date) {
  return ((mask >> (date.weekday - 1)) & 1) == 1;
}

class Habit {
  const Habit({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.weekdaysMask = allWeekdaysMask,
    this.xpReward = 5,
    this.isArchived = false,
  });

  final String id;
  final String name;
  final String? description;
  final int weekdaysMask;
  final int xpReward;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool isScheduledOn(DateTime date) => isDayScheduled(weekdaysMask, date);
}

/// Привычка вместе с днями, в которые она выполнена (dayKey: yyyy-MM-dd).
class HabitProgress {
  const HabitProgress({required this.habit, required this.doneDays});

  final Habit habit;
  final Set<String> doneDays;

  bool isDoneOn(String dayKey) => doneDays.contains(dayKey);
}