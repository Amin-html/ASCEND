import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ascend/features/gamification/presentation/level_up_dialog.dart';
import 'package:ascend/features/habits/data/habit_providers.dart';
import 'package:ascend/features/habits/domain/habit_models.dart';
import 'package:ascend/features/habits/presentation/habit_form_sheet.dart';
import 'package:ascend/shared/widgets/confirm_dialog.dart';

void _say(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(SnackBar(content: Text(message)));
}

Future<void> createHabit(BuildContext context) async {
  final saved = await showHabitFormSheet(context);
  if (saved && context.mounted) _say(context, 'Habit created');
}

Future<void> editHabit(BuildContext context, Habit habit) async {
  final saved = await showHabitFormSheet(context, habit: habit);
  if (saved && context.mounted) _say(context, 'Habit saved');
}

/// Отметить привычку за сегодня или снять отметку.
Future<void> toggleHabitToday(
    BuildContext context,
    WidgetRef ref,
    HabitProgress progress,
    String todayKey,
    ) async {
  final messenger = ScaffoldMessenger.of(context);
  final done = progress.isDoneOn(todayKey);

  final result = await ref
      .read(habitActionsProvider)
      .setDone(progress.habit.id, done: !done);
  if (result == null) return;

  final message = result.leveledUp
      ? '+${result.xpGained} XP  •  Level ${result.levelAfter}!'
      : 'Habit done  •  +${result.xpGained} XP';
  messenger
    ..clearSnackBars()
    ..showSnackBar(SnackBar(content: Text(message)));

  if (result.leveledUp && context.mounted) {
    await showLevelUpDialog(context, result);
  }
}

Future<void> setHabitArchived(
    BuildContext context,
    WidgetRef ref,
    Habit habit, {
      required bool archived,
    }) async {
  await ref
      .read(habitActionsProvider)
      .setArchived(habit.id, archived: archived);
  if (context.mounted) {
    _say(context, archived ? 'Habit archived' : 'Habit restored');
  }
}

Future<void> confirmDeleteHabit(
    BuildContext context,
    WidgetRef ref,
    HabitProgress progress,
    ) async {
  final habit = progress.habit;
  final checkIns = progress.doneDays.length;
  final ok = await showConfirmDialog(
    context,
    title: 'Delete habit?',
    message: '"${habit.name}" and its history will be removed'
        '${checkIns > 0 ? ', together with the XP from $checkIns check-ins' : ''}.',
    confirmLabel: 'Delete',
    destructive: true,
  );
  if (!ok || !context.mounted) return;
  await ref.read(habitActionsProvider).deleteHabit(habit.id);
}