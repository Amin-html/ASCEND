import 'package:ascend/features/habits/domain/habit_models.dart';

abstract interface class HabitRepository {
  /// Все привычки, включая архивные, вместе с днями выполнения.
  Stream<List<HabitProgress>> watchAll();
}