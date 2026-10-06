import 'package:flutter/material.dart';

import 'package:ascend/core/theme/app_colors.dart';

/// Круглая отметка «выполнено» с областью нажатия 44 px.
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
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done ? AppColors.primary : Colors.transparent,
                border: Border.all(
                  color: done ? AppColors.primary : AppColors.textMuted,
                  width: 1.6,
                ),
              ),
              child: done
                  ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}