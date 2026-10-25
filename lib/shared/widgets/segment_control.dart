import 'package:flutter/material.dart';

import 'package:ascend/core/theme/app_colors.dart';
import 'package:ascend/core/theme/app_dimens.dart';

/// Переключатель из нескольких вариантов. Подписи сжимаются по ширине,
/// поэтому он помещается на узком экране при любом размере шрифта.
class SegmentControl<T> extends StatelessWidget {
  const SegmentControl({
    required this.segments,
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final List<(T, String)> segments;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelLarge;
    const idle = StadiumBorder();
    const active = StadiumBorder(
      side: BorderSide(color: AppColors.borderStrong),
    );

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          for (final (value, label) in segments)
            Expanded(
              child: Semantics(
                button: true,
                selected: value == selected,
                child: Material(
                  color: value == selected
                      ? AppColors.surfaceHighest
                      : Colors.transparent,
                  shape: value == selected ? active : idle,
                  animationDuration: AppMotion.fast,
                  child: InkWell(
                    customBorder: idle,
                    onTap: () => onChanged(value),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 11,
                      ),
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            label,
                            maxLines: 1,
                            style: style?.copyWith(
                              color: value == selected
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                            ),
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
    );
  }
}
