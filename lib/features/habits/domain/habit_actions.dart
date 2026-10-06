import 'package:ascend/features/gamification/domain/completion_result.dart';
import 'package:ascend/features/habits/domain/habit_models.dart';

abstract interface class HabitActions {
  Future<void> saveHabit(Habit habit);

  /// Удаляет привычку, её отметки и XP за них.
  Future<void> deleteHabit(String habitId);

  Future<void> setArchived(String habitId, {required bool archived});

  /// Отметка за сегодняшний день. Возвращает результат с XP только
  /// при новой отметке; null при снятии, повторе или неизвестной привычке.
  Future<CompletionResult?> setDone(String habitId, {required bool done});
}