import 'package:flutter/material.dart';

import 'package:ascend/core/theme/app_colors.dart';
import 'package:ascend/core/theme/app_dimens.dart';
import 'package:ascend/core/theme/app_typography.dart';
import 'package:ascend/features/gamification/domain/completion_result.dart';

Future<void> showLevelUpDialog(
    BuildContext context,
    CompletionResult result,
    ) {
  return showDialog<void>(
    context: context,
    builder: (context) => _LevelUpDialog(result: result),
  );
}

class _LevelUpDialog extends StatelessWidget {
  const _LevelUpDialog({required this.result});

  final CompletionResult result;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.92, end: 1.0),
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutBack,
          builder: (context, scale, child) =>
              Transform.scale(scale: scale, child: child),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.primaryGradient,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.4),
                        blurRadius: 28,
                        spreadRadius: -4,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.bolt_rounded,
                    size: 38,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text('Level Up!', style: text.headlineMedium),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Level ${result.levelAfter}',
                  style: AppTypography.numeric.copyWith(
                    color: AppColors.primaryLight,
                  ),
                ),
                if (result.rankChanged) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'New rank: ${result.rankAfter.label}',
                    style: text.titleMedium,
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                Text(
                  '+${result.xpGained} XP earned',
                  style: text.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Continue'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}