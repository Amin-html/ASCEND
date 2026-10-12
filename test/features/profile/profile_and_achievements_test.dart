import 'package:flutter/widgets.dart';

import 'package:flutter_test/flutter_test.dart';

import 'package:ascend/features/achievements/domain/achievement_models.dart';

import '../../helpers/fake_achievement_actions.dart';
import '../../helpers/test_app.dart';

void main() {
  final unlockedAt = DateTime(2026, 10, 1, 12);
  const counts = AchievementCounts(
    completedTasks: 37,
    focusSeconds: 7300,
    totalXp: 150,
  );

  Future<void> openProfile(WidgetTester tester, Widget app) async {
    useTallScreen(tester);
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
  }

  testWidgets('profile shows level, rank and totals', (tester) async {
    await openProfile(
      tester,
      testApp(
        totalXp: 150,
        counts: counts,
        unlocked: {'first_step': unlockedAt},
      ),
    );

    expect(find.text('Beginner'), findsOneWidget);
    expect(find.text('Next rank: Starter at level 5'), findsOneWidget);
    expect(find.text('50 / 283 XP to next level'), findsOneWidget);
    expect(find.text('Tasks done'), findsOneWidget);
    expect(find.text('37'), findsOneWidget);
    expect(find.text('Focus time'), findsOneWidget);
    expect(find.text('2h'), findsOneWidget);
    expect(find.text('Total XP'), findsOneWidget);
    expect(find.text('150'), findsOneWidget);
    expect(find.text('1 of 6'), findsOneWidget);
  });

  testWidgets('achievements screen lists progress and unlock dates',
          (tester) async {
        await openProfile(
          tester,
          testApp(
            totalXp: 150,
            counts: counts,
            unlocked: {'first_step': unlockedAt},
          ),
        );

        await tester.tap(find.text('See all'));
        await tester.pumpAndSettle();

        expect(find.text('1 of 6 unlocked'), findsOneWidget);
        expect(find.text('First Step'), findsOneWidget);
        expect(find.text('Unlocked 1 October 2026'), findsOneWidget);
        expect(find.text('100 Tasks'), findsOneWidget);
        expect(find.text('37 / 100'), findsOneWidget);
        expect(find.text('Deep Worker'), findsOneWidget);
        expect(find.text('2 / 10 h'), findsOneWidget);
        expect(find.text('0 / 7 days'), findsOneWidget);
        expect(find.text('Level 2 / 35'), findsOneWidget);
        expect(find.text('Goal Crusher'), findsOneWidget);
        expect(find.text('Elite'), findsOneWidget);
      });

  testWidgets('a newly earned achievement is announced once', (tester) async {
    final actions = FakeAchievementActions();
    await tester.pumpWidget(
      testApp(
        counts: const AchievementCounts(completedTasks: 1),
        achievementActions: actions,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Achievement unlocked: First Step'), findsOneWidget);
    expect(actions.unlockedCodes, {'first_step'});
  });

  testWidgets('already unlocked achievements are not announced',
          (tester) async {
        final actions = FakeAchievementActions();
        await tester.pumpWidget(
          testApp(
            counts: const AchievementCounts(completedTasks: 1),
            unlocked: {'first_step': unlockedAt},
            achievementActions: actions,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('unlocked:'), findsNothing);
        expect(actions.calls, isEmpty);
      });

  testWidgets('several achievements are announced together', (tester) async {
    final actions = FakeAchievementActions();
    await tester.pumpWidget(
      testApp(
        counts: const AchievementCounts(completedTasks: 100, completedGoals: 1),
        achievementActions: actions,
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Achievements unlocked: First Step, 100 Tasks, Goal Crusher',
      ),
      findsOneWidget,
    );
  });
}