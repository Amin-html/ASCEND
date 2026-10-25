import 'package:flutter/material.dart';

import 'package:ascend/core/theme/app_dimens.dart';

/// Число, которое «досчитывает» от нуля до [value]. При изменении значения
/// плавно переходит к новому. Если анимации отключены, показывает сразу.
class CountUpText extends StatelessWidget {
  const CountUpText({
    required this.value,
    super.key,
    this.prefix = '',
    this.suffix = '',
    this.style,
    this.duration = const Duration(milliseconds: 900),
  });

  final int value;
  final String prefix;
  final String suffix;
  final TextStyle? style;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final effective =
        MediaQuery.disableAnimationsOf(context) ? Duration.zero : duration;
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: value),
      duration: effective,
      curve: AppMotion.curve,
      builder: (context, current, _) =>
          Text('$prefix$current$suffix', style: style),
    );
  }
}
