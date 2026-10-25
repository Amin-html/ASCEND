import 'package:flutter/painting.dart';

/// Палитра ASCEND: тёмный интерфейс с яркими, но чистыми акцентами
/// (фиолетовый, голубой и тёплые цвета заката для наград и прогресса).
abstract final class AppColors {
  // Фоны
  static const Color background = Color(0xFF090E1A);
  static const Color surface = Color(0xFF0C1220); // боковая и нижняя панели
  static const Color surfaceElevated = Color(0xFF121A2B); // карточки
  static const Color surfaceHighest = Color(0xFF18223A); // вложенные элементы, поля

  // Акценты
  static const Color primary = Color(0xFF8B7DF5);
  static const Color primaryLight = Color(0xFFB8AEFF);
  static const Color accent = Color(0xFF5E9BFF);

  // Цвета заката: прогресс, XP, награды
  static const Color sunsetPink = Color(0xFFF0709A);
  static const Color sunsetOrange = Color(0xFFFFA06B);

  // Границы
  static const Color border = Color(0xFF2A3550);
  static const Color borderStrong = Color(0xFF3B4A6B);

  // Текст
  static const Color textPrimary = Color(0xFFF0F3FA);
  static const Color textSecondary = Color(0xFF9AA6BC);
  static const Color textMuted = Color(0xFF7683A0);

  // Состояния
  static const Color success = Color(0xFF63D4A0);
  static const Color warning = Color(0xFFFFB454);
  static const Color danger = Color(0xFFFF6B7A);

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [primary, accent],
  );

  /// Прогресс, XP и уровни: от фиолетового через розовый к оранжевому.
  static const LinearGradient sunsetGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [primary, sunsetPink, sunsetOrange],
  );
}
