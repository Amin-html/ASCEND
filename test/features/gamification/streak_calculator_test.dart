import 'package:flutter_test/flutter_test.dart';

import 'package:ascend/features/gamification/domain/streak_calculator.dart';

void main() {
  const today = '2026-10-03';

  test('empty set gives zeros', () {
    final s = calculateStreak(activeDays: {}, today: today);
    expect(s.current, 0);
    expect(s.best, 0);
  });

  test('only today', () {
    final s = calculateStreak(activeDays: {today}, today: today);
    expect(s.current, 1);
    expect(s.best, 1);
  });

  test('three consecutive days ending today', () {
    final s = calculateStreak(
      activeDays: {'2026-10-01', '2026-10-02', today},
      today: today,
    );
    expect(s.current, 3);
    expect(s.best, 3);
  });

  test('gap breaks the current streak', () {
    final s = calculateStreak(
      activeDays: {'2026-10-01', today},
      today: today,
    );
    expect(s.current, 1);
    expect(s.best, 1);
  });

  test('streak stays alive if today has no activity yet', () {
    final s = calculateStreak(
      activeDays: {'2026-10-01', '2026-10-02'},
      today: today,
    );
    expect(s.current, 2);
  });

  test('streak is lost if neither today nor yesterday is active', () {
    final s = calculateStreak(
      activeDays: {'2026-09-30', '2026-10-01'},
      today: today,
    );
    expect(s.current, 0);
    expect(s.best, 2);
  });

  test('best streak is found in history', () {
    final s = calculateStreak(
      activeDays: {
        '2026-09-01',
        '2026-09-02',
        '2026-09-03',
        '2026-09-04',
        '2026-09-10',
      },
      today: today,
    );
    expect(s.current, 0);
    expect(s.best, 4);
  });

  test('works across a month boundary', () {
    final s = calculateStreak(
      activeDays: {'2026-09-30', '2026-10-01', '2026-10-02', today},
      today: today,
    );
    expect(s.current, 4);
    expect(s.best, 4);
  });
}