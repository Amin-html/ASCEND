import 'package:ascend/features/focus/domain/focus_models.dart';
import 'package:ascend/features/gamification/domain/completion_result.dart';

abstract interface class FocusActions {
  /// Сохраняет завершённую сессию, начисляет XP, добавляет время к задаче
  /// и обновляет статистику дня, всё в одной транзакции.
  /// Возвращает null, если сессия слишком короткая и не сохранена.
  Future<CompletionResult?> complete(FocusSessionInput input);
}