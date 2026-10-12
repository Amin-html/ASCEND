enum FocusMode { countdown, stopwatch }

/// То, что нужно сохранить по окончании сессии.
class FocusSessionInput {
  const FocusSessionInput({
    required this.mode,
    required this.actualSeconds,
    required this.startedAt,
    this.plannedSeconds,
    this.taskId,
  });

  final FocusMode mode;
  final int actualSeconds;
  final DateTime startedAt;
  final int? plannedSeconds;
  final String? taskId;
}

/// Сессия для списка истории.
class FocusSessionEntry {
  const FocusSessionEntry({
    required this.id,
    required this.mode,
    required this.actualSeconds,
    required this.startedAt,
    required this.xpAwarded,
    this.taskTitle,
  });

  final String id;
  final FocusMode mode;
  final int actualSeconds;
  final DateTime startedAt;
  final int xpAwarded;
  final String? taskTitle;
}