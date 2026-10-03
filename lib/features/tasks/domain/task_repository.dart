import 'package:ascend/features/tasks/domain/task.dart';

abstract interface class TaskRepository {
  Stream<List<Task>> watchByDay(String dayKey);
  Stream<List<Task>> watchAll();
  Future<Task?> getById(String id);
  Future<void> upsert(Task task);
  Future<void> delete(String id);
}