import 'package:flutter/material.dart';

import 'package:ascend/core/theme/app_colors.dart';
import 'package:ascend/core/theme/app_dimens.dart';

/// Тонкая полоса прогресса с градиентом заката и плавным заполнением.
class GradientProgressBar extends StatelessWidget {
  const GradientProgressBar({
    required this.value,
    super.key,
    this.height = 6,
    this.gradient = AppColors.sunsetGradient,
  });

  /// 0.0 – 1.0
  final double value;
  final double height;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    final target = value.clamp(0.0, 1.0).toDouble();

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: SizedBox(
        height: height,
        child: Stack(
          children: [
            const Positioned.fill(child: ColoredBox(color: AppColors.border)),
            Positioned.fill(
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: target),
                duration: AppMotion.slow,
                curve: AppMotion.curve,
                builder: (context, animated, _) => FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: animated,
                  heightFactor: 1,
                  child: DecoratedBox(
                    decoration: BoxDecoration(gradient: gradient),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
