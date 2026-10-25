import 'package:flutter/material.dart';

import 'package:ascend/core/theme/app_colors.dart';
import 'package:ascend/core/theme/app_dimens.dart';
import 'package:ascend/core/theme/app_typography.dart';
import 'package:ascend/shared/widgets/app_card.dart';
import 'package:ascend/shared/widgets/count_up_text.dart';

class StatTile extends StatelessWidget {
  const StatTile({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    super.key,
    this.caption,
    this.countTo,
    this.prefix = '',
  });

  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  final String? caption;

  /// Если задано, число анимированно досчитывается до этого значения
  /// (с необязательным [prefix], например «+»). Иначе показывается [value].
  final int? countTo;
  final String prefix;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final cap = caption;
    final target = countTo;
    final valueStyle = AppTypography.numeric.copyWith(fontSize: 26);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(height: AppSpacing.md),
          if (target != null)
            CountUpText(value: target, prefix: prefix, style: valueStyle)
          else
            Text(value, style: valueStyle),
          const SizedBox(height: 2),
          Text(
            label,
            style: text.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
          if (cap != null)
            Text(
              cap,
              style: text.labelSmall?.copyWith(color: AppColors.textMuted),
            ),
        ],
      ),
    );
  }
}
