import 'package:flutter_test/flutter_test.dart';

import 'package:ascend/features/habits/domain/habit_streak.dart';
import 'package:ascend/features/habits/presentation/habit_labels.dart';

void main() {
  const daily = 127;
  const weekdays = 31;

  HabitStreak streak(Set<String> done, int mask, String today) {
    return calculateHabitStreak(
      doneDays: done,
      weekdaysMask: mask,
      today: today,
    );
  }

  test('nothing done', () {
    final s = streak({}, daily, '2026-10-05');
    expect(s.current, 0);
    expect(s.best, 0);
  });

  test('empty schedule gives zeros', () {
    final s = streak({'2026-10-05'}, 0, '2026-10-05');
    expect(s.current, 0);
    expect(s.best, 0);
  });

  test('only today', () {
    final s = streak({'2026-10-05'}, daily, '2026-10-05');
    expect(s.current, 1);
    expect(s.best, 1);
  });

  test('streak stays alive while today is still pending', () {
    final s = streak({'2026-10-02', '2026-10-03', '2026-10-04'}, daily, '2026-10-05');
    expect(s.current, 3);
    expect(s.best, 3);
  });

  test('a missed day resets the current streak', () {
    final s = streak({'2026-10-03', '2026-10-04'}, daily, '2026-10-06');
    expect(s.current, 0);
    expect(s.best, 2);
  });

  test('best streak is found in the history', () {
    final s = streak(
      {'2026-09-01', '2026-09-02', '2026-09-03', '2026-09-04', '2026-09-10'},
      daily,
      '2026-10-05',
    );
    expect(s.current, 0);
    expect(s.best, 4);
  });

  test('works across a month boundary', () {
    final s = streak(
      {'2026-09-30', '2026-10-01', '2026-10-02'},
      daily,
      '2026-10-02',
    );
    expect(s.current, 3);
  });

  test('days off do not break a weekday streak over the weekend', () {
    // Чт и Пт выполнены, сегодня понедельник: Сб и Вс не запланированы.
    final s = streak({'2026-10-01', '2026-10-02'}, weekdays, '2026-10-05');
    expect(s.current, 2);
    expect(s.best, 2);
  });

  test('skipping a scheduled weekday breaks it', () {
    // Те же отметки, но сегодня вторник: понедельник был пропущен.
    final s = streak({'2026-10-01', '2026-10-02'}, weekdays, '2026-10-06');
    expect(s.current, 0);
    expect(s.best, 2);
  });

  group('labels', () {
    test('scheduleLabel', () {
      expect(scheduleLabel(127), 'Every day');
      expect(scheduleLabel(31), 'Weekdays');
      expect(scheduleLabel(96), 'Weekends');
      expect(scheduleLabel(21), 'Mon, Wed, Fri');
    });

    test('streakLabel', () {
      expect(streakLabel(0), 'No streak yet');
      expect(streakLabel(1), '1-day streak');
      expect(streakLabel(12), '12-day streak');
    });
  });
}