import 'package:ascend/features/gamification/domain/completion_result.dart';
import 'package:ascend/features/tasks/domain/task.dart';

/// Все изменения задач проходят через этот интерфейс.
/// Реализация обязана делать каждую операцию атомарно.
abstract interface class TaskActions {
  /// Создать или обновить задачу и пересчитать статистику затронутых дней.
  Future<void> save(Task task);

  /// Завершить задачу. null, если задачи нет или она уже выполнена.
  Future<CompletionResult?> complete(String taskId);

  /// Вернуть выполненную задачу в Todo и забрать начисленный XP.
  Future<void> reopen(String taskId);

  /// Удалить задачу вместе с её XP.
  Future<void> delete(String taskId);
}