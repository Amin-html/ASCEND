import 'package:flutter/material.dart';

import 'package:ascend/core/theme/app_colors.dart';
import 'package:ascend/core/theme/app_dimens.dart';

/// Иконка в скруглённом тонированном квадрате: единый акцент для пунктов
/// меню, настроек и карточек действий.
class IconBadge extends StatelessWidget {
  const IconBadge({
    required this.icon,
    super.key,
    this.size = 44,
    this.color = AppColors.primary,
    this.iconColor = AppColors.primaryLight,
  });

  final IconData icon;
  final double size;
  final Color color;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppRadius.control),
      ),
      child: Icon(icon, color: iconColor, size: size * 0.5),
    );
  }
}
