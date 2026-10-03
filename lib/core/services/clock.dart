/// Источник времени. В коде используем его вместо DateTime.now(),
/// чтобы тесты streak/XP были детерминированными.
abstract interface class Clock {
  DateTime now();
}

class SystemClock implements Clock {
  const SystemClock();

  @override
  DateTime now() => DateTime.now();
}