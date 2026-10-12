import 'package:ascend/features/achievements/domain/achievement_models.dart';

abstract interface class AchievementActions {
  /// Записывает в БД достижения, условие которых выполнено, и возвращает
  /// только те, что открылись впервые. Повторный вызов вернёт пустой список.
  Future<List<AchievementDef>> unlockNew(AchievementMetrics metrics);
}