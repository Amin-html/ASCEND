import 'package:flutter/material.dart';

import 'package:ascend/core/theme/app_colors.dart';
import 'package:ascend/core/theme/app_dimens.dart';
import 'package:ascend/features/goals/domain/goal_models.dart';
import 'package:ascend/features/goals/presentation/goal_labels.dart';
import 'package:ascend/features/tasks/domain/category.dart';
import 'package:ascend/shared/widgets/app_card.dart';

class GoalCard extends StatelessWidget {
  const GoalCard({
    required this.item,
    required this.now,
    required this.onTap,
    super.key,
    this.category,
  });

  final GoalWithMilestones item;
  final Category? category;
  final DateTime now;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final goal = item.goal;
    final cat = category;
    final showDeadline =
        goal.status == GoalStatus.active && goal.deadline != null;
    final info = deadlineInfo(goal.deadline, now);
    final percent = (item.progress * 100).round();

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  goal.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: text.titleMedium,
                ),
              ),
              if (goal.status == GoalStatus.completed)
                const Padding(
                  padding: EdgeInsets.only(left: AppSpacing.sm),
                  child: Icon(
                    Icons.check_circle_rounded,
                    size: 20,
                    color: AppColors.success,
                  ),
                ),
            ],
          ),
          if (cat != null || showDeadline) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: 4,
              children: [
                if (cat != null)
                  _Meta(
                    leading: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Color(cat.colorValue),
                        shape: BoxShape.circle,
                      ),
                    ),
                    label: cat.name,
                    color: AppColors.textSecondary,
                  ),
                if (showDeadline)
                  _Meta(
                    leading: Icon(
                      Icons.event_rounded,
                      size: 13,
                      color: deadlineColor(info.tone),
                    ),
                    label: info.label,
                    color: deadlineColor(info.tone),
                  ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                item.total == 0
                    ? 'No milestones yet'
                    : '${item.done} of ${item.total} milestones',
                style: text.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                '$percent%',
                style: text.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(value: item.progress, minHeight: 6),
          ),
        ],
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({
    required this.leading,
    required this.label,
    required this.color,
  });

  final Widget leading;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        leading,
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color),
        ),
      ],
    );
  }
}