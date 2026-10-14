import 'package:ascend/features/gamification/domain/completion_result.dart';
import 'package:ascend/features/tasks/domain/task.dart';
import 'package:ascend/features/tasks/domain/task_actions.dart';

class FakeTaskActions implements TaskActions {
  final List<Task> saved = [];

  @override
  Future<void> save(Task task) async => saved.add(task);

  @override
  Future<CompletionResult?> complete(String taskId) async => null;

  @override
  Future<void> reopen(String taskId) async {}

  @override
  Future<void> delete(String taskId) async {}
}