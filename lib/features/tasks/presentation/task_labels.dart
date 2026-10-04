import 'package:flutter/material.dart';

import 'package:ascend/core/theme/app_colors.dart';
import 'package:ascend/features/tasks/domain/task_enums.dart';

extension TaskPriorityX on TaskPriority {
  String get label => switch (this) {
    TaskPriority.low => 'Low',
    TaskPriority.medium => 'Medium',
    TaskPriority.high => 'High',
    TaskPriority.urgent => 'Urgent',
  };

  Color get color => switch (this) {
    TaskPriority.low => AppColors.textMuted,
    TaskPriority.medium => AppColors.primaryLight,
    TaskPriority.high => AppColors.warning,
    TaskPriority.urgent => AppColors.danger,
  };
}