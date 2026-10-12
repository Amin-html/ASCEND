import 'package:flutter/material.dart';

import 'package:ascend/core/theme/app_colors.dart';
import 'package:ascend/core/theme/app_dimens.dart';
import 'package:ascend/core/theme/app_typography.dart';
import 'package:ascend/shared/widgets/app_card.dart';

class StatTile extends StatelessWidget {
  const StatTile({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    super.key,
    this.caption,
  });

  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final cap = caption;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(height: AppSpacing.md),
          Text(value, style: AppTypography.numeric.copyWith(fontSize: 26)),
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