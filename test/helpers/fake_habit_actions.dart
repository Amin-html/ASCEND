import 'package:ascend/features/gamification/domain/completion_result.dart';
import 'package:ascend/features/habits/domain/habit_actions.dart';
import 'package:ascend/features/habits/domain/habit_models.dart';

class FakeHabitActions implements HabitActions {
  final List<String> calls = [];

  @override
  Future<void> saveHabit(Habit habit) async =>
      calls.add('saveHabit:${habit.name}');

  @override
  Future<void> deleteHabit(String habitId) async =>
      calls.add('deleteHabit:$habitId');

  @override
  Future<void> setArchived(String habitId, {required bool archived}) async =>
      calls.add('setArchived:$habitId:$archived');

  @override
  Future<CompletionResult?> setDone(
      String habitId, {
        required bool done,
      }) async {
    calls.add('setDone:$habitId:$done');
    return null;
  }
}