import 'package:flutter/painting.dart';

abstract final class AppColors {
  static const Color background = Color(0xFF07070A);
  static const Color surface = Color(0xFF101016);
  static const Color surfaceElevated = Color(0xFF15151D);
  static const Color surfaceHighest = Color(0xFF1A1822);

  static const Color primary = Color(0xFF7C3AED);
  static const Color primaryLight = Color(0xFF8B5CF6);
  static const Color accent = Color(0xFFA855F7);

  static const Color border = Color(0x12FFFFFF); // белый ~7%

  static const Color textPrimary = Color(0xFFF4F4F8);
  static const Color textSecondary = Color(0xFFA1A1B5);
  static const Color textMuted = Color(0xFF7A7A90);

  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [primary, accent],
  );
}