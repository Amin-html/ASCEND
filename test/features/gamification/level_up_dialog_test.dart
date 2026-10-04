import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ascend/core/theme/app_theme.dart';
import 'package:ascend/features/gamification/domain/completion_result.dart';
import 'package:ascend/features/gamification/domain/rank.dart';
import 'package:ascend/features/gamification/presentation/level_up_dialog.dart';

void main() {
  testWidgets('level up dialog shows level, rank and XP', (tester) async {
    const result = CompletionResult(
      taskXp: 100,
      totalXpBefore: 1000,
      totalXpAfter: 1120,
      levelBefore: 4,
      levelAfter: 5,
      rankBefore: Rank.beginner,
      rankAfter: Rank.starter,
      streakDays: 1,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showLevelUpDialog(context, result),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Level Up!'), findsOneWidget);
    expect(find.text('Level 5'), findsOneWidget);
    expect(find.text('New rank: Starter'), findsOneWidget);
    expect(find.text('+120 XP earned'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Level Up!'), findsNothing);
  });
}