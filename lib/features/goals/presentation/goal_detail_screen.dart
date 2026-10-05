import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:ascend/core/router/app_routes.dart';
import 'package:ascend/core/services/service_providers.dart';
import 'package:ascend/core/theme/app_colors.dart';
import 'package:ascend/core/theme/app_dimens.dart';
import 'package:ascend/core/theme/app_typography.dart';
import 'package:ascend/features/gamification/data/gamification_providers.dart';
import 'package:ascend/features/goals/data/goal_providers.dart';
import 'package:ascend/features/goals/domain/goal_models.dart';
import 'package:ascend/features/goals/presentation/goal_interactions.dart';
import 'package:ascend/features/goals/presentation/goal_labels.dart';
import 'package:ascend/features/tasks/data/task_providers.dart';
import 'package:ascend/features/tasks/domain/category.dart';
import 'package:ascend/shared/widgets/app_card.dart';
import 'package:ascend/shared/widgets/confirm_dialog.dart';
import 'package:ascend/shared/widgets/empty_state.dart';
import 'package:ascend/shared/widgets/error_state.dart';
import 'package:ascend/shared/widgets/progress_ring.dart';

enum _GoalMenu { edit, complete, reopen, archive, restore, delete }

class GoalDetailScreen extends ConsumerStatefulWidget {
  const GoalDetailScreen({required this.goalId, super.key});

  final String goalId;

  @override
  ConsumerState<GoalDetailScreen> createState() => _GoalDetailScreenState();
}

class _GoalDetailScreenState extends ConsumerState<GoalDetailScreen> {
  final _newMilestone = TextEditingController();
  final _focus = FocusNode();

  @override
  void dispose() {
    _newMilestone.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _addMilestone() async {
    final title = _newMilestone.text.trim();
    if (title.isEmpty) return;
    _newMilestone.clear();
    await ref.read(goalActionsProvider).addMilestone(widget.goalId, title);
    if (mounted) _focus.requestFocus();
  }

  Future<void> _rename(Milestone milestone) async {
    final title = await showDialog<String>(
      context: context,
      builder: (context) => _RenameDialog(initial: milestone.title),
    );
    if (title == null || title.trim().isEmpty || !mounted) return;
    await ref.read(goalActionsProvider).renameMilestone(milestone.id, title);
  }

  Future<void> _deleteMilestone(Milestone milestone) async {
    if (milestone.isDone) {
      final ok = await showConfirmDialog(
        context,
        title: 'Delete milestone?',
        message: '"${milestone.title}" will be removed together with '
            'the ${milestone.xpAwarded} XP it gave.',
        confirmLabel: 'Delete',
        destructive: true,
      );
      if (!ok || !mounted) return;
    }
    await ref.read(goalActionsProvider).deleteMilestone(milestone.id);
  }

  Future<void> _deleteGoal(GoalWithMilestones item) async {
    final earned = item.milestones
        .where((m) => m.isDone)
        .fold<int>(0, (sum, m) => sum + m.xpAwarded);
    final ok = await showConfirmDialog(
      context,
      title: 'Delete goal?',
      message: '"${item.goal.title}" and its milestones will be removed'
          '${earned > 0 ? ', together with $earned XP earned from them' : ''}. '
          'Linked tasks are kept.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!ok || !mounted) return;
    await ref.read(goalActionsProvider).deleteGoal(item.goal.id);
    if (mounted) context.go(AppRoutes.goals);
  }

  Future<void> _onMenu(_GoalMenu value, GoalWithMilestones item) async {
    final actions = ref.read(goalActionsProvider);
    final messenger = ScaffoldMessenger.of(context);
    final goal = item.goal;

    void say(String message) {
      messenger
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text(message)));
    }

    switch (value) {
      case _GoalMenu.edit:
        await editGoal(context, goal);
      case _GoalMenu.complete:
        await actions.setGoalStatus(goal.id, GoalStatus.completed);
        say('Goal completed');
      case _GoalMenu.reopen:
        await actions.setGoalStatus(goal.id, GoalStatus.active);
        say('Goal reopened');
      case _GoalMenu.archive:
        await actions.setGoalStatus(goal.id, GoalStatus.archived);
        say('Goal archived');
      case _GoalMenu.restore:
        await actions.setGoalStatus(goal.id, GoalStatus.active);
        say('Goal restored');
      case _GoalMenu.delete:
        await _deleteGoal(item);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(goalProvider(widget.goalId));

    return async.when(
      loading: () => Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(),
        body: ErrorState(
          message: 'Could not load the goal.',
          onRetry: () => ref.invalidate(goalProvider(widget.goalId)),
        ),
      ),
      data: (item) {
        if (item == null) {
          return Scaffold(
            appBar: AppBar(),
            body: EmptyState(
              icon: Icons.flag_outlined,
              title: 'Goal not found',
              message: 'It may have been deleted.',
              actionLabel: 'Back to goals',
              onAction: () => context.go(AppRoutes.goals),
            ),
          );
        }
        return _buildContent(context, item);
      },
    );
  }

  Widget _buildContent(BuildContext context, GoalWithMilestones item) {
    final text = Theme.of(context).textTheme;
    final goal = item.goal;
    final now = ref.watch(clockProvider).now();
    final milestoneXp = ref.watch(xpEngineProvider).xpForMilestone();
    final categories =
        ref.watch(categoriesProvider).value ?? const <Category>[];
    Category? category;
    for (final c in categories) {
      if (c.id == goal.categoryId) category = c;
    }

    final allDone = item.total > 0 && item.done == item.total;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Goal'),
        actions: [
          PopupMenuButton<_GoalMenu>(
            tooltip: 'More',
            onSelected: (value) => _onMenu(value, item),
            itemBuilder: (context) => [
              const PopupMenuItem(value: _GoalMenu.edit, child: Text('Edit')),
              if (goal.status == GoalStatus.active)
                const PopupMenuItem(
                  value: _GoalMenu.complete,
                  child: Text('Mark as completed'),
                ),
              if (goal.status == GoalStatus.completed && !allDone)
                const PopupMenuItem(
                  value: _GoalMenu.reopen,
                  child: Text('Reopen goal'),
                ),
              if (goal.status != GoalStatus.archived)
                const PopupMenuItem(
                  value: _GoalMenu.archive,
                  child: Text('Archive'),
                ),
              if (goal.status == GoalStatus.archived)
                const PopupMenuItem(
                  value: _GoalMenu.restore,
                  child: Text('Restore'),
                ),
              const PopupMenuItem(
                value: _GoalMenu.delete,
                child: Text('Delete'),
              ),
            ],
          ),
        ],
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.xs,
              AppSpacing.lg,
              96,
            ),
            children: [
              _Header(item: item, category: category, now: now),
              const SizedBox(height: AppSpacing.xxl),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Milestones', style: text.titleLarge),
                  if (item.total > 0)
                    Text(
                      '${item.done} of ${item.total}',
                      style: text.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              if (item.milestones.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Text(
                    'Break this goal into steps. Each completed milestone '
                        'gives +$milestoneXp XP.',
                    style: text.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              for (final m in item.milestones)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _MilestoneTile(
                    key: ValueKey(m.id),
                    milestone: m,
                    xp: milestoneXp,
                    onToggle: () => toggleMilestone(context, ref, m),
                    onRename: () => _rename(m),
                    onDelete: () => _deleteMilestone(m),
                  ),
                ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _newMilestone,
                focusNode: _focus,
                textInputAction: TextInputAction.done,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => _addMilestone(),
                decoration: InputDecoration(
                  hintText: 'Add a milestone',
                  suffixIcon: IconButton(
                    tooltip: 'Add milestone',
                    onPressed: _addMilestone,
                    icon: const Icon(Icons.add_rounded),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.item,
    required this.category,
    required this.now,
  });

  final GoalWithMilestones item;
  final Category? category;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final goal = item.goal;
    final cat = category;
    final description = goal.description;
    final info = deadlineInfo(goal.deadline, now);
    final showDeadline =
        goal.status == GoalStatus.active && goal.deadline != null;
    final percent = (item.progress * 100).round();

    return AppCard(
      glow: goal.status == GoalStatus.active && item.progress > 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ProgressRing(
                value: item.progress,
                size: 84,
                strokeWidth: 8,
                child: Text(
                  '$percent%',
                  style: AppTypography.numeric.copyWith(fontSize: 20),
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(goal.title, style: text.titleLarge),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.md,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _StatusChip(status: goal.status),
                        if (cat != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: Color(cat.colorValue),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                cat.name,
                                style: text.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        if (showDeadline)
                          Text(
                            info.label,
                            style: text.bodySmall?.copyWith(
                              color: deadlineColor(info.tone),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (description != null) ...[
            const SizedBox(height: AppSpacing.lg),
            Text(
              description,
              style: text.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final GoalStatus status;

  @override
  Widget build(BuildContext context) {
    final color = status.color;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        status.label,
        style: Theme.of(context)
            .textTheme
            .labelSmall
            ?.copyWith(color: color),
      ),
    );
  }
}

enum _MilestoneMenu { rename, delete }

class _MilestoneTile extends StatelessWidget {
  const _MilestoneTile({
    required this.milestone,
    required this.xp,
    required this.onToggle,
    required this.onRename,
    required this.onDelete,
    super.key,
  });

  final Milestone milestone;
  final int xp;
  final VoidCallback onToggle;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final done = milestone.isDone;
    final reward = done ? milestone.xpAwarded : xp;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.xs),
      child: Row(
        children: [
          Semantics(
            button: true,
            label: done ? 'Mark as not done' : 'Mark as done',
            child: InkWell(
              key: ValueKey('milestone-check-${milestone.id}'),
              customBorder: const CircleBorder(),
              onTap: onToggle,
              child: SizedBox(
                width: 44,
                height: 44,
                child: Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: done ? AppColors.primary : Colors.transparent,
                      border: Border.all(
                        color: done ? AppColors.primary : AppColors.textMuted,
                        width: 1.6,
                      ),
                    ),
                    child: done
                        ? const Icon(
                      Icons.check_rounded,
                      size: 16,
                      color: Colors.white,
                    )
                        : null,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Text(
                milestone.title,
                style: text.titleMedium?.copyWith(
                  decoration: done ? TextDecoration.lineThrough : null,
                  decorationColor: AppColors.textMuted,
                  color: done ? AppColors.textMuted : AppColors.textPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: done ? 0.08 : 0.16),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text(
              '+$reward XP',
              style: text.labelSmall?.copyWith(
                color: done ? AppColors.textMuted : AppColors.primaryLight,
              ),
            ),
          ),
          PopupMenuButton<_MilestoneMenu>(
            tooltip: 'More',
            icon: const Icon(Icons.more_vert_rounded, size: 20),
            onSelected: (value) {
              switch (value) {
                case _MilestoneMenu.rename:
                  onRename();
                case _MilestoneMenu.delete:
                  onDelete();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: _MilestoneMenu.rename, child: Text('Rename')),
              PopupMenuItem(value: _MilestoneMenu.delete, child: Text('Delete')),
            ],
          ),
        ],
      ),
    );
  }
}

class _RenameDialog extends StatefulWidget {
  const _RenameDialog({required this.initial});

  final String initial;

  @override
  State<_RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<_RenameDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initial);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Rename milestone'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        onSubmitted: (value) => Navigator.of(context).pop(value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text('Save'),
        ),
      ],
    );
  }
}