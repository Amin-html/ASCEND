import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:ascend/core/theme/app_colors.dart';
import 'package:ascend/core/theme/app_dimens.dart';
import 'package:ascend/core/theme/app_typography.dart';
import 'package:ascend/core/utils/formatters.dart';
import 'package:ascend/features/gamification/domain/completion_result.dart';

/// Итог сессии. [result] == null: сессия слишком короткая и не сохранена.
Future<void> showFocusSummary(
    BuildContext context, {
      required int seconds,
      required CompletionResult? result,
      required bool auto,
      required int minutesPerXp,
    }) {
  return showDialog<void>(
    context: context,
    builder: (context) => _FocusSummaryDialog(
      seconds: seconds,
      result: result,
      auto: auto,
      minutesPerXp: minutesPerXp,
    ),
  );
}

class _FocusSummaryDialog extends StatelessWidget {
  const _FocusSummaryDialog({
    required this.seconds,
    required this.result,
    required this.auto,
    required this.minutesPerXp,
  });

  final int seconds;
  final CompletionResult? result;
  final bool auto;
  final int minutesPerXp;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final r = result;

    final String title;
    final String duration;
    final String detail;
    final IconData icon;

    if (r == null) {
      title = 'Session too short';
      duration = '';
      detail = 'Sessions under 1 minute are not saved.';
      icon = Icons.timer_off_outlined;
    } else {
      title = auto ? 'Session complete' : 'Session saved';
      duration = formatMinutes(math.max(1, seconds ~/ 60));
      detail = r.xpGained > 0
          ? '+${r.xpGained} XP'
          : 'Focus $minutesPerXp minutes or more to earn XP.';
      icon = Icons.check_circle_rounded;
    }

    return AlertDialog(
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (r == null ? AppColors.textMuted : AppColors.success)
                    .withValues(alpha: 0.16),
              ),
              child: Icon(
                icon,
                size: 38,
                color: r == null ? AppColors.textMuted : AppColors.success,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(title, style: text.titleLarge),
            if (duration.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                duration,
                style: AppTypography.numeric.copyWith(
                  fontSize: 28,
                  color: AppColors.primaryLight,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            Text(
              detail,
              textAlign: TextAlign.center,
              style: text.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Continue'),
        ),
      ],
    );
  }
}