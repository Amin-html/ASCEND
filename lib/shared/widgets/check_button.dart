import 'package:flutter/material.dart';

import 'package:ascend/core/theme/app_colors.dart';
import 'package:ascend/core/theme/app_dimens.dart';

/// Круглая отметка «выполнено» с областью нажатия 44 px.
/// Галочка появляется с небольшим «отскоком».
class CheckButton extends StatelessWidget {
  const CheckButton({required this.done, required this.onTap, super.key});

  final bool done;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: done ? 'Mark as not done' : 'Mark as done',
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: AnimatedContainer(
              duration: AppMotion.fast,
              curve: AppMotion.curve,
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done ? AppColors.success : Colors.transparent,
                border: Border.all(
                  color: done ? AppColors.success : AppColors.textMuted,
                  width: 1.6,
                ),
              ),
              child: AnimatedSwitcher(
                duration: AppMotion.normal,
                switchInCurve: Curves.easeOutBack,
                transitionBuilder: (child, animation) =>
                    ScaleTransition(scale: animation, child: child),
                child: done
                    ? const Icon(
                        Icons.check_rounded,
                        key: ValueKey('done'),
                        size: 16,
                        color: AppColors.background,
                      )
                    : const SizedBox.shrink(key: ValueKey('todo')),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
