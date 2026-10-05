import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:ascend/core/router/app_routes.dart';
import 'package:ascend/features/gamification/domain/completion_result.dart';
import 'package:ascend/features/gamification/presentation/level_up_dialog.dart';
import 'package:ascend/features/goals/data/goal_providers.dart';
import 'package:ascend/features/goals/domain/goal_models.dart';
import 'package:ascend/features/goals/presentation/goal_form_sheet.dart';

/// Форма новой цели. После сохранения открывает экран цели,
/// чтобы сразу добавить milestones.
Future<void> createGoalAndOpen(BuildContext context) async {
  final id = await showGoalFormSheet(context);
  if (id == null || !context.mounted) return;
  context.go(AppRoutes.goalDetail(id));
}

Future<void> editGoal(BuildContext context, Goal goal) async {
  final id = await showGoalFormSheet(context, goal: goal);
  if (id == null || !context.mounted) return;
  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(const SnackBar(content: Text('Goal saved')));
}

String milestoneRewardMessage(CompletionResult r) {
  final parts = <String>['Milestone completed', '+${r.xpGained} XP'];
  if (r.leveledUp) parts.add('Level ${r.levelAfter}!');
  return parts.join('  •  ');
}

/// Отметить milestone выполненным или снять отметку.
Future<void> toggleMilestone(
    BuildContext context,
    WidgetRef ref,
    Milestone milestone,
    ) async {
  final messenger = ScaffoldMessenger.of(context);
  final result = await ref
      .read(goalActionsProvider)
      .setMilestoneDone(milestone.id, done: !milestone.isDone);
  if (result == null) return;

  messenger
    ..clearSnackBars()
    ..showSnackBar(SnackBar(content: Text(milestoneRewardMessage(result))));

  if (result.leveledUp && context.mounted) {
    await showLevelUpDialog(context, result);
  }
}