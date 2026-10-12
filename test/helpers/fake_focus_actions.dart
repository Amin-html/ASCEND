import 'package:ascend/features/focus/domain/focus_actions.dart';
import 'package:ascend/features/focus/domain/focus_models.dart';
import 'package:ascend/features/gamification/domain/completion_result.dart';
import 'package:ascend/features/gamification/domain/rank.dart';

CompletionResult sampleCompletion(int xp) {
  return CompletionResult(
    taskXp: xp,
    totalXpBefore: 0,
    totalXpAfter: xp,
    levelBefore: 1,
    levelAfter: 1,
    rankBefore: Rank.beginner,
    rankAfter: Rank.beginner,
    streakDays: 0,
  );
}

class FakeFocusActions implements FocusActions {
  FakeFocusActions({this.result});

  final List<FocusSessionInput> inputs = [];

  /// Что вернуть из complete(). null: сессия «слишком короткая».
  CompletionResult? result;

  @override
  Future<CompletionResult?> complete(FocusSessionInput input) async {
    inputs.add(input);
    return result;
  }
}