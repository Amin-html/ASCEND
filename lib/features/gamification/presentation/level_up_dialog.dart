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
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: 1),
          duration: reduceMotion
              ? Duration.zero
              : const Duration(milliseconds: 600),
          curve: Curves.easeOutBack,
          builder: (context, t, child) => Opacity(
            opacity: t.clamp(0.0, 1.0).toDouble(),
            child: Transform.scale(scale: 0.8 + 0.2 * t, child: child),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 128,
                  height: 96,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.primary,
                              AppColors.sunsetPink,
                              AppColors.sunsetOrange,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.sunsetPink.withValues(
                                alpha: 0.45,
                              ),
                              blurRadius: 32,
                              spreadRadius: -2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.bolt_rounded,
                          size: 42,
                          color: Colors.white,
                        ),
                      ),
                      const Positioned(
                        top: 4,
                        right: 14,
                        child: Icon(
                          Icons.auto_awesome_rounded,
                          size: 18,
                          color: AppColors.sunsetOrange,
                        ),
                      ),
                      const Positioned(
                        bottom: 8,
                        left: 10,
                        child: Icon(
                          Icons.auto_awesome_rounded,
                          size: 14,
                          color: AppColors.primaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text('Level Up!', style: text.headlineMedium),
                const SizedBox(height: AppSpacing.sm),
                ShaderMask(
                  blendMode: BlendMode.srcIn,
                  shaderCallback: (rect) =>
                      AppColors.sunsetGradient.createShader(rect),
                  child: Text(
                    'Level ${result.levelAfter}',
                    style: AppTypography.numeric.copyWith(
                      fontSize: 36,
                      color: Colors.white,
                    ),
                  ),
                ),
                if (result.rankChanged) ...[
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      'New rank: ${result.rankAfter.label}',
                      style: text.titleMedium,
                    ),
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
