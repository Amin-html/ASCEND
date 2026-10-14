import 'package:ascend/features/gamification/domain/completion_result.dart';
import 'package:ascend/features/tasks/domain/task.dart';
import 'package:ascend/features/tasks/domain/task_actions.dart';

class FakeTaskActions implements TaskActions {
  final List<Task> saved = [];
  final List<String> calls = [];

  @override
  Future<void> save(Task task) async {
    saved.add(task);
    calls.add('save:${task.id}');
  }

  @override
  Future<CompletionResult?> complete(String taskId) async {
    calls.add('complete:$taskId');
    return null;
  }

  @override
  Future<void> reopen(String taskId) async {
    calls.add('reopen:$taskId');
  }

  @override
  Future<void> delete(String taskId) async {
    calls.add('delete:$taskId');
  }
}