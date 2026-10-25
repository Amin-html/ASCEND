import 'package:flutter/material.dart';

import 'package:ascend/core/theme/app_colors.dart';
import 'package:ascend/core/theme/app_dimens.dart';
import 'package:ascend/shared/widgets/split_row.dart';

class XpBar extends StatelessWidget {
  const XpBar({
    required this.level,
    required this.currentXp,
    required this.nextLevelXp,
    super.key,
  });

  final int level;
  final int currentXp;
  final int nextLevelXp;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final progress = nextLevelXp <= 0
        ? 0.0
        : (currentXp / nextLevelXp).clamp(0.0, 1.0).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SplitRow(
          left: Text('Level $level', style: text.titleMedium),
          right: Text(
            '$currentXp / $nextLevelXp XP',
            style: text.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: SizedBox(
            height: 6,
            child: Stack(
              children: [
                const Positioned.fill(
                  child: ColoredBox(color: AppColors.border),
                ),
                Positioned.fill(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: progress),
                    duration: AppMotion.slow,
                    curve: AppMotion.curve,
                    builder: (context, value, _) {
                      return FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: value,
                        heightFactor: 1,
                        child: const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: AppColors.sunsetGradient,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
