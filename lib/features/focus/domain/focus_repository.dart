import 'package:ascend/features/focus/domain/focus_models.dart';

abstract interface class FocusRepository {
  /// Суммарное время фокуса за локальный день, в секундах.
  Stream<int> watchSecondsForDay(String dayKey);

  /// Последние сессии, новые сначала.
  Stream<List<FocusSessionEntry>> watchRecent({int limit = 5});
}