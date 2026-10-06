import 'package:flutter_test/flutter_test.dart';

import 'package:ascend/features/gamification/domain/rank.dart';
import 'package:ascend/features/gamification/domain/xp_engine.dart';
import 'package:ascend/features/tasks/domain/task_enums.dart';

void main() {
  const engine = XpEngine();

  group('xpForNewTask', () {
    test('base XP by priority', () {
      expect(engine.xpForNewTask(priority: TaskPriority.low), 10);
      expect(engine.xpForNewTask(priority: TaskPriority.medium), 15);
      expect(engine.xpForNewTask(priority: TaskPriority.high), 25);
      expect(engine.xpForNewTask(priority: TaskPriority.urgent), 35);
    });

    test('duration bonus is +5 per full 30 minutes, capped at +15', () {
      int xp(int minutes) => engine.xpForNewTask(
        priority: TaskPriority.low,
        estimatedMinutes: minutes,
      );

      expect(xp(29), 10);
      expect(xp(30), 15);
      expect(xp(60), 20);
      expect(xp(90), 25);
      expect(xp(600), 25);
    });

    test('zero or negative duration gives no bonus', () {
      expect(
        engine.xpForNewTask(priority: TaskPriority.high, estimatedMinutes: 0),
        25,
      );
      expect(
        engine.xpForNewTask(priority: TaskPriority.high, estimatedMinutes: -10),
        25,
      );
    });

    test('maximum is 50', () {
      expect(
        engine.xpForNewTask(
          priority: TaskPriority.urgent,
          estimatedMinutes: 1000,
        ),
        50,
      );
    });
  });

  group('fixed rewards', () {
    test('habit check-in', () {
      expect(engine.xpForHabit(), 5);
    });

    test('milestone and daily plan', () {
      expect(engine.xpForMilestone(), 100);
      expect(engine.xpForDailyPlan(), 20);
    });

    test('streak bonus only on exact thresholds', () {
      expect(engine.xpForStreak(1), 0);
      expect(engine.xpForStreak(3), 10);
      expect(engine.xpForStreak(4), 0);
      expect(engine.xpForStreak(7), 30);
      expect(engine.xpForStreak(30), 100);
    });

    test('focus XP: 1 per 5 full minutes, capped at 20', () {
      expect(engine.xpForFocus(0), 0);
      expect(engine.xpForFocus(299), 0);
      expect(engine.xpForFocus(300), 1);
      expect(engine.xpForFocus(3600), 12);
      expect(engine.xpForFocus(7200), 20);
      expect(engine.xpForFocus(-5), 0);
    });
  });

  group('levels', () {
    test('xpToNextLevel curve', () {
      expect(engine.xpToNextLevel(1), 100);
      expect(engine.xpToNextLevel(2), 283);
      expect(engine.xpToNextLevel(3), 520);
      expect(engine.xpToNextLevel(4), 800);
    });

    test('totalXpForLevel is cumulative', () {
      expect(engine.totalXpForLevel(1), 0);
      expect(engine.totalXpForLevel(2), 100);
      expect(engine.totalXpForLevel(3), 383);
    });

    test('progressFor at boundaries', () {
      final p0 = engine.progressFor(0);
      expect(p0.level, 1);
      expect(p0.xpIntoLevel, 0);
      expect(p0.xpForNextLevel, 100);

      expect(engine.progressFor(99).level, 1);

      final p100 = engine.progressFor(100);
      expect(p100.level, 2);
      expect(p100.xpIntoLevel, 0);
      expect(p100.xpForNextLevel, 283);

      final p150 = engine.progressFor(150);
      expect(p150.level, 2);
      expect(p150.xpIntoLevel, 50);

      expect(engine.progressFor(383).level, 3);
    });

    test('negative total is treated as zero', () {
      final p = engine.progressFor(-50);
      expect(p.level, 1);
      expect(p.totalXp, 0);
    });

    test('progressFor and totalXpForLevel agree', () {
      for (var level = 1; level <= 60; level++) {
        final start = engine.totalXpForLevel(level);
        expect(engine.progressFor(start).level, level);
        expect(engine.progressFor(start).xpIntoLevel, 0);
        if (level > 1) {
          expect(engine.progressFor(start - 1).level, level - 1);
        }
      }
    });

    test('fraction is between 0 and 1', () {
      final p = engine.progressFor(150);
      expect(p.fraction, closeTo(50 / 283, 1e-9));
    });
  });

  group('ranks', () {
    test('rank by level', () {
      expect(engine.rankForLevel(1), Rank.beginner);
      expect(engine.rankForLevel(4), Rank.beginner);
      expect(engine.rankForLevel(5), Rank.starter);
      expect(engine.rankForLevel(9), Rank.starter);
      expect(engine.rankForLevel(10), Rank.focused);
      expect(engine.rankForLevel(15), Rank.disciplined);
      expect(engine.rankForLevel(24), Rank.disciplined);
      expect(engine.rankForLevel(25), Rank.advanced);
      expect(engine.rankForLevel(35), Rank.elite);
      expect(engine.rankForLevel(50), Rank.master);
      expect(engine.rankForLevel(120), Rank.master);
    });
  });
}