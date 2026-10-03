import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:ascend/core/theme/app_colors.dart';

class ProgressRing extends StatelessWidget {
  const ProgressRing({
    required this.value,
    super.key,
    this.size = 120,
    this.strokeWidth = 10,
    this.child,
  });

  /// 0.0 – 1.0
  final double value;
  final double size;
  final double strokeWidth;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value.clamp(0.0, 1.0).toDouble()),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      builder: (context, animated, inner) {
        return SizedBox.square(
          dimension: size,
          child: CustomPaint(
            painter: _RingPainter(progress: animated, strokeWidth: strokeWidth),
            child: Center(child: inner),
          ),
        );
      },
      child: child,
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({required this.progress, required this.strokeWidth});

  final double progress;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(strokeWidth / 2);

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = AppColors.surfaceHighest;
    canvas.drawArc(rect, 0, math.pi * 2, false, track);

    if (progress <= 0) return;

    final fill = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = const SweepGradient(
        colors: [AppColors.primary, AppColors.accent],
        transform: GradientRotation(-math.pi / 2),
      ).createShader(rect);
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * progress, false, fill);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.strokeWidth != strokeWidth;
}