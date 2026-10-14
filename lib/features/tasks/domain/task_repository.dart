import 'package:ascend/features/tasks/domain/task.dart';

abstract interface class TaskRepository {
  Stream<List<Task>> watchByDay(String dayKey);
  Stream<List<Task>> watchAll();

  /// Невыполненные и неотменённые задачи с датой в диапазоне
  /// [fromDayKey, toDayKey] включительно, по дню и времени.
  Stream<List<Task>> watchOpenInRange(String fromDayKey, String toDayKey);

  Future<Task?> getById(String id);
  Future<void> upsert(Task task);
  Future<void> delete(String id);
}