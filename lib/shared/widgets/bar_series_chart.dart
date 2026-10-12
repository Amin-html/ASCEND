import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:ascend/core/theme/app_colors.dart';

/// Простой столбчатый график. Последний столбец (сегодня) выделен.
/// Списки [values], [labels] и [tooltips] должны быть одной длины.
class BarSeriesChart extends StatelessWidget {
  const BarSeriesChart({
    required this.values,
    required this.labels,
    required this.tooltips,
    super.key,
    this.height = 120,
  });

  final List<double> values;
  final List<String> labels;
  final List<String> tooltips;
  final double height;

  double _factor(double value, double maxValue) {
    final floor = 2 / height;
    if (maxValue <= 0 || value <= 0) return floor;
    return math.max(value / maxValue, floor).clamp(0.0, 1.0).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final n = values.length;
    if (n == 0) return SizedBox(height: height);

    final maxValue = values.fold<double>(0, (a, b) => math.max(a, b));
    // Подписываем примерно семь столбцов, чтобы подписи не слипались.
    final step = (n / 7).ceil();
    final gap = n > 14 ? 1.5 : 4.0;
    final labelStyle = Theme.of(context)
        .textTheme
        .labelSmall
        ?.copyWith(color: AppColors.textMuted, fontSize: 10);

    bool showLabel(int i) => i % step == 0 || i == n - 1;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: height,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < n; i++)
                Expanded(
                  child: Tooltip(
                    message: tooltips[i],
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: gap),
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: FractionallySizedBox(
                          widthFactor: 1,
                          heightFactor: _factor(values[i], maxValue),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: values[i] <= 0
                                  ? AppColors.surfaceHighest
                                  : (i == n - 1
                                  ? AppColors.primaryLight
                                  : AppColors.primary
                                  .withValues(alpha: 0.6)),
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            for (var i = 0; i < n; i++)
              Expanded(
                child: SizedBox(
                  height: 14,
                  child: showLabel(i)
                      ? OverflowBox(
                    minWidth: 0,
                    maxWidth: 56,
                    child: Text(
                      labels[i],
                      softWrap: false,
                      overflow: TextOverflow.visible,
                      textAlign: TextAlign.center,
                      style: labelStyle,
                    ),
                  )
                      : null,
                ),
              ),
          ],
        ),
      ],
    );
  }
}