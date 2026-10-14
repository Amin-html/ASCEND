/// Вечернее напоминание о плане дня.
const String planPayload = 'plan';

const String _taskPrefix = 'task:';

String taskPayload(String taskId) => '$_taskPrefix$taskId';

/// null, если payload не относится к задаче.
String? taskIdFromPayload(String? payload) {
  if (payload == null || !payload.startsWith(_taskPrefix)) return null;
  final id = payload.substring(_taskPrefix.length);
  return id.isEmpty ? null : id;
}