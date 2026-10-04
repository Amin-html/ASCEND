import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ascend/core/theme/app_colors.dart';
import 'package:ascend/features/gamification/domain/completion_result.dart';
import 'package:ascend/features/gamification/presentation/level_up_dialog.dart';
import 'package:ascend/features/tasks/data/task_providers.dart';
import 'package:ascend/features/tasks/domain/task.dart';
import 'package:ascend/features/tasks/presentation/task_form_sheet.dart';

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

Future<void> confirmDeleteTask(
    BuildContext context,
    WidgetRef ref,
    Task task,
    ) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete task?'),
      content: Text(
        '"${task.title}" will be removed'
            '${task.isCompleted ? ' together with its XP' : ''}.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: TextButton.styleFrom(foregroundColor: AppColors.danger),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  if (ok != true || !context.mounted) return;
  await ref.read(taskActionsProvider).delete(task.id);
}