import 'package:ascend/features/achievements/domain/achievement_models.dart';

abstract interface class AchievementRepository {
  Stream<AchievementCounts> watchCounts();

  /// code -> когда открыто.
  Stream<Map<String, DateTime>> watchUnlocked();
}