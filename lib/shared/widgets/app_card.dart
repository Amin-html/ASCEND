import 'package:flutter/material.dart';

import 'package:ascend/core/theme/app_colors.dart';
import 'package:ascend/core/theme/app_dimens.dart';

/// Карточка с мягким градиентом поверхности. Если есть [onTap], на десктопе
/// подсвечивает рамку при наведении, а при нажатии слегка уменьшается.
class AppCard extends StatefulWidget {
  const AppCard({
    required this.child,
    super.key,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.onTap,
    this.color = AppColors.surfaceElevated,
    this.glow = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color color;

  /// Акцентная рамка и мягкое свечение для ключевых блоков
  /// (главный прогресс, Level Up). Использовать редко.
  final bool glow;

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  bool _hover = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final interactive = widget.onTap != null;
    final radius = BorderRadius.circular(AppRadius.card);
    final top = Color.alphaBlend(
      Colors.white.withValues(alpha: 0.04),
      widget.color,
    );

    final Color borderColor;
    if (widget.glow) {
      borderColor = AppColors.primary.withValues(alpha: 0.55);
    } else if (_hover && interactive) {
      borderColor = AppColors.borderStrong;
    } else {
      borderColor = AppColors.border;
    }

    return AnimatedScale(
      scale: _pressed && interactive ? 0.985 : 1,
      duration: AppMotion.fast,
      curve: AppMotion.curve,
      child: AnimatedContainer(
        duration: AppMotion.normal,
        curve: AppMotion.curve,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [top, widget.color],
          ),
          borderRadius: radius,
          border: Border.all(color: borderColor),
          boxShadow: widget.glow
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.22),
                    blurRadius: 28,
                    spreadRadius: -8,
                  ),
                ]
              : null,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: radius,
            onTap: widget.onTap,
            onHover: interactive ? (v) => setState(() => _hover = v) : null,
            onHighlightChanged:
                interactive ? (v) => setState(() => _pressed = v) : null,
            child: Padding(padding: widget.padding, child: widget.child),
          ),
        ),
      ),
    );
  }
}
