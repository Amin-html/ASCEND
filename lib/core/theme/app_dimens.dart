import 'package:flutter/animation.dart';

abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double huge = 40;
}

abstract final class AppRadius {
  static const double control = 12;
  static const double card = 16;
  static const double sheet = 24;
  static const double pill = 999;
}

/// Единые длительности и кривая анимаций (ненавязчивые, до 250 мс).
abstract final class AppMotion {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 500);
  static const Curve curve = Curves.easeOutCubic;
}
