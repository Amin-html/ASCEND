import 'package:ascend/features/achievements/domain/achievement_actions.dart';
import 'package:ascend/features/achievements/domain/achievement_models.dart';

class FakeAchievementActions implements AchievementActions {
  final List<AchievementMetrics> calls = [];
  final Set<String> unlockedCodes = {};

  @override
  Future<List<AchievementDef>> unlockNew(AchievementMetrics metrics) async {
    calls.add(metrics);
    final fresh = findNewlyUnlocked(metrics, unlockedCodes);
    unlockedCodes.addAll(fresh.map((d) => d.code));
    return fresh;
  }
}