import 'package:flutter_test/flutter_test.dart';

import 'package:ascend/features/achievements/domain/achievement_models.dart';
import 'package:ascend/features/gamification/domain/rank.dart';

void main() {
  Set<String> codes(AchievementMetrics m, [Set<String> unlocked = const {}]) {
    return findNewlyUnlocked(m, unlocked).map((d) => d.code).toSet();
  }

  test('nothing is unlocked from scratch', () {
    expect(codes(const AchievementMetrics()), isEmpty);
  });

  test('first step needs one completed task', () {
    expect(codes(const AchievementMetrics(completedTasks: 1)), {'first_step'});
  });

  test('100 tasks also unlocks first step', () {
    expect(
      codes(const AchievementMetrics(completedTasks: 100)),
      {'first_step', 'tasks_100'},
    );
  });

  test('7 day focus needs a best streak of 7', () {
    expect(codes(const AchievementMetrics(bestStreak: 6)), isEmpty);
    expect(codes(const AchievementMetrics(bestStreak: 7)), {'streak_7'});
  });

  test('deep worker needs 10 hours of focus', () {
    expect(codes(const AchievementMetrics(focusSeconds: 36000 - 1)), isEmpty);
    expect(codes(const AchievementMetrics(focusSeconds: 36000)), {'deep_worker'});
  });

  test('goal crusher needs a completed goal', () {
    expect(codes(const AchievementMetrics(completedGoals: 1)), {'goal_crusher'});
  });

  test('elite needs the Elite rank level', () {
    expect(Rank.elite.minLevel, 35);
    expect(codes(const AchievementMetrics(level: 34)), isEmpty);
    expect(codes(const AchievementMetrics(level: 35)), {'elite'});
  });

  test('already unlocked achievements are not reported again', () {
    expect(
      codes(const AchievementMetrics(completedTasks: 1), {'first_step'}),
      isEmpty,
    );
  });

  test('every achievement has a unique code', () {
    final all = achievementDefs.map((d) => d.code).toList();
    expect(all.toSet().length, all.length);
    expect(all.length, 6);
  });

  group('entries', () {
    test('locked entries show clamped progress', () {
      final entries = buildAchievementEntries(
        const AchievementMetrics(completedTasks: 37, focusSeconds: 7300),
        const {},
      );
      AchievementEntry byCode(String c) =>
          entries.firstWhere((e) => e.def.code == c);

      expect(byCode('tasks_100').current, 37);
      expect(byCode('tasks_100').def.progressLabel(37), '37 / 100');
      expect(byCode('tasks_100').fraction, closeTo(0.37, 1e-9));
      expect(byCode('deep_worker').def.progressLabel(7300), '2 / 10 h');
      expect(byCode('streak_7').def.progressLabel(3), '3 / 7 days');
      expect(byCode('elite').def.progressLabel(12), 'Level 12 / 35');
      // Цель достигнута, но ещё не записана: прогресс не выше цели.
      expect(byCode('first_step').current, 1);
      expect(byCode('first_step').isUnlocked, isFalse);
    });

    test('an unlocked achievement stays unlocked after metrics drop', () {
      final entries = buildAchievementEntries(
        const AchievementMetrics(),
        {'tasks_100': DateTime(2026, 10, 1)},
      );
      final entry = entries.firstWhere((e) => e.def.code == 'tasks_100');

      expect(entry.isUnlocked, isTrue);
      expect(entry.current, 100);
      expect(entry.fraction, 1.0);
    });
  });

  test('Rank.next', () {
    expect(Rank.beginner.next, Rank.starter);
    expect(Rank.elite.next, Rank.master);
    expect(Rank.master.next, isNull);
  });

  test('metrics are compared by value', () {
    expect(
      const AchievementMetrics(completedTasks: 1),
      const AchievementMetrics(completedTasks: 1),
    );
    expect(
      const AchievementMetrics(completedTasks: 1) ==
          const AchievementMetrics(completedTasks: 2),
      isFalse,
    );
  });
}