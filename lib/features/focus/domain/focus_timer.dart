import 'package:ascend/features/focus/domain/focus_models.dart';

enum FocusPhase { idle, running, paused, finished }

/// Таймер без собственных часов: время приходит параметром, поэтому
/// результат не зависит от частоты тиков и легко проверяется в тестах.
class FocusTimer {
  const FocusTimer._({
    required this.mode,
    required this.phase,
    required this.accumulated,
    this.planned,
    this.startedAt,
    this.runningSince,
  });

  factory FocusTimer.countdown(Duration planned) => FocusTimer._(
    mode: FocusMode.countdown,
    phase: FocusPhase.idle,
    accumulated: Duration.zero,
    planned: planned,
  );

  factory FocusTimer.stopwatch() => const FocusTimer._(
    mode: FocusMode.stopwatch,
    phase: FocusPhase.idle,
    accumulated: Duration.zero,
  );

  final FocusMode mode;
  final FocusPhase phase;

  /// Для обратного отсчёта: запланированная длительность.
  final Duration? planned;

  /// Время, накопленное до последней паузы.
  final Duration accumulated;

  /// Когда сессия началась (не меняется при паузах).
  final DateTime? startedAt;

  /// С какого момента идёт текущий отрезок (только в состоянии running).
  final DateTime? runningSince;

  bool get isIdle => phase == FocusPhase.idle;
  bool get isRunning => phase == FocusPhase.running;
  bool get isPaused => phase == FocusPhase.paused;
  bool get isFinished => phase == FocusPhase.finished;

  FocusTimer _with({
    FocusPhase? phase,
    Duration? accumulated,
    DateTime? startedAt,
    DateTime? runningSince,
    bool clearRunning = false,
  }) {
    return FocusTimer._(
      mode: mode,
      planned: planned,
      phase: phase ?? this.phase,
      accumulated: accumulated ?? this.accumulated,
      startedAt: startedAt ?? this.startedAt,
      runningSince: clearRunning ? null : (runningSince ?? this.runningSince),
    );
  }

  /// Сколько времени прошло. Если часы ушли назад, время не уменьшается.
  /// У обратного отсчёта результат не превышает запланированного.
  Duration elapsed(DateTime now) {
    var total = accumulated;
    final since = runningSince;
    if (phase == FocusPhase.running && since != null) {
      final delta = now.difference(since);
      if (!delta.isNegative) total += delta;
    }
    final limit = planned;
    if (mode == FocusMode.countdown && limit != null && total > limit) {
      return limit;
    }
    return total;
  }

  /// Сколько осталось (только для обратного отсчёта).
  Duration? remaining(DateTime now) {
    final limit = planned;
    if (mode != FocusMode.countdown || limit == null) return null;
    final left = limit - elapsed(now);
    return left.isNegative ? Duration.zero : left;
  }

  bool isComplete(DateTime now) {
    final limit = planned;
    return mode == FocusMode.countdown &&
        limit != null &&
        elapsed(now) >= limit;
  }

  FocusTimer start(DateTime now) {
    if (phase != FocusPhase.idle) return this;
    return _with(phase: FocusPhase.running, startedAt: now, runningSince: now);
  }

  FocusTimer pause(DateTime now) {
    if (phase != FocusPhase.running) return this;
    return _with(
      phase: FocusPhase.paused,
      accumulated: elapsed(now),
      clearRunning: true,
    );
  }

  FocusTimer resume(DateTime now) {
    if (phase != FocusPhase.paused) return this;
    return _with(phase: FocusPhase.running, runningSince: now);
  }

  FocusTimer finish(DateTime now) {
    if (phase != FocusPhase.running && phase != FocusPhase.paused) return this;
    return _with(
      phase: FocusPhase.finished,
      accumulated: elapsed(now),
      clearRunning: true,
    );
  }
}

/// Округление вверх до секунды, чтобы обратный отсчёт показывал 25:00
/// в момент старта, а не 24:59.
Duration ceilToSeconds(Duration d) {
  if (d <= Duration.zero) return Duration.zero;
  return Duration(seconds: (d.inMilliseconds + 999) ~/ 1000);
}