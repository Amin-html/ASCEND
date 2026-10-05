import 'package:flutter/painting.dart';

import 'package:ascend/core/theme/app_colors.dart';
import 'package:ascend/core/utils/formatters.dart';
import 'package:ascend/features/goals/domain/goal_models.dart';

extension GoalStatusX on GoalStatus {
  String get label => switch (this) {
    GoalStatus.active => 'Active',
    GoalStatus.completed => 'Completed',
    GoalStatus.archived => 'Archived',
  };

  Color get color => switch (this) {
    GoalStatus.active => AppColors.primaryLight,
    GoalStatus.completed => AppColors.success,
    GoalStatus.archived => AppColors.textMuted,
  };
}

enum DeadlineTone { none, normal, soon, overdue }

class DeadlineInfo {
  const DeadlineInfo(this.label, this.tone);

  final String label;
  final DeadlineTone tone;
}

/// Разница в календарных днях. Через UTC, чтобы переход на летнее время
/// не превращал 24 часа в 23.
int _daysBetween(DateTime from, DateTime to) {
  final a = DateTime.utc(from.year, from.month, from.day);
  final b = DateTime.utc(to.year, to.month, to.day);
  return b.difference(a).inDays;
}

DeadlineInfo deadlineInfo(DateTime? deadline, DateTime now) {
  if (deadline == null) {
    return const DeadlineInfo('No deadline', DeadlineTone.none);
  }
  final days = _daysBetween(now, deadline);
  if (days < 0) {
    final n = -days;
    return DeadlineInfo(
      'Overdue by $n ${n == 1 ? 'day' : 'days'}',
      DeadlineTone.overdue,
    );
  }
  if (days == 0) return const DeadlineInfo('Due today', DeadlineTone.soon);
  if (days == 1) return const DeadlineInfo('Due tomorrow', DeadlineTone.soon);
  if (days <= 7) return DeadlineInfo('Due in $days days', DeadlineTone.soon);
  return DeadlineInfo('Due ${shortDate(deadline)}', DeadlineTone.normal);
}

Color deadlineColor(DeadlineTone tone) => switch (tone) {
  DeadlineTone.none => AppColors.textMuted,
  DeadlineTone.normal => AppColors.textSecondary,
  DeadlineTone.soon => AppColors.warning,
  DeadlineTone.overdue => AppColors.danger,
};