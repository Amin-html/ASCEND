import 'package:flutter/material.dart';

import 'package:ascend/core/theme/app_dimens.dart';

/// Плавное появление: прозрачность и сдвиг вверх. [delay] даёт каскад
/// из нескольких блоков. Без таймеров, поэтому безопасно для тестов.
/// Если в системе отключены анимации, показывается сразу.
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({
    required this.child,
    super.key,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 450),
    this.offset = 16,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;

  /// Начальный сдвиг вниз в логических пикселях.
  final double offset;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _progress;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    final total = widget.delay + widget.duration;
    _controller = AnimationController(vsync: this, duration: total);
    _progress = CurvedAnimation(
      parent: _controller,
      curve: Interval(
        widget.delay.inMilliseconds / total.inMilliseconds,
        1,
        curve: AppMotion.curve,
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _progress,
      child: AnimatedBuilder(
        animation: _progress,
        child: widget.child,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, (1 - _progress.value) * widget.offset),
          child: child,
        ),
      ),
    );
  }
}
