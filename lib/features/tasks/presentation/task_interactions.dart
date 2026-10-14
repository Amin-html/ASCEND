import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ascend/features/gamification/domain/completion_result.dart';
import 'package:ascend/features/gamification/presentation/level_up_dialog.dart';
import 'package:ascend/features/tasks/data/task_providers.dart';
import 'package:ascend/features/tasks/domain/task.dart';
import 'package:ascend/features/tasks/presentation/task_form_sheet.dart';
import 'package:ascend/shared/widgets/confirm_dialog.dart';

String rewardMessage(CompletionResult r) {
  final parts = <String>['+${r.xpGained} XP'];
  if (r.bonusXp > 0) parts.add('incl. ${r.bonusXp} bonus');
  if (r.leveledUp) parts.add('Level ${r.levelAfter}!');
  return parts.join('  •  ');
}

/// Отметить задачу выполненной или вернуть её в работу.
Future<void> toggleTask(BuildContext context, WidgetRef ref, Task task) async {
  final actions = ref.read(taskActionsProvider);
  final messenger = ScaffoldMessenger.of(context);

  if (task.isCompleted) {
    await actions.reopen(task.id);
    messenger
      ..clearSnackBars()
      ..showSnackBar(const SnackBar(content: Text('Task reopened')));
    return;
  }

  final result = await actions.complete(task.id);
  if (result == null) return;

  messenger
    ..clearSnackBars()
    ..showSnackBar(SnackBar(content: Text(rewardMessage(result))));

  if (result.leveledUp && context.mounted) {
    await showLevelUpDialog(context, result);
  }
}

Future<void> openTaskForm(
    BuildContext context, {
      Task? task,
      String? initialDayKey,
    }) async {
  final saved = await showTaskFormSheet(
    context,
    task: task,
    initialDayKey: initialDayKey,
  );
  if (!saved || !context.mounted) return;

  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(content: Text(task == null ? 'Task created' : 'Task saved')),
    );
}

/// Спрашивает подтверждение и удаляет задачу. true: задача удалена.
Future<bool> confirmDeleteTask(
    BuildContext context,
    WidgetRef ref,
    Task task,
    ) async {
  final ok = await showConfirmDialog(
    context,
    title: 'Delete task?',
    message: '"${task.title}" will be removed'
        '${task.isCompleted ? ' together with its XP' : ''}.',
    confirmLabel: 'Delete',
    destructive: true,
  );
  if (!ok || !context.mounted) return false;
  await ref.read(taskActionsProvider).delete(task.id);
  return true;
}