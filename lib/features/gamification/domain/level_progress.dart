class LevelProgress {
  const LevelProgress({
    required this.level,
    required this.xpIntoLevel,
    required this.xpForNextLevel,
    required this.totalXp,
  });

  final int level;

  /// Сколько XP набрано внутри текущего уровня.
  final int xpIntoLevel;

  /// Сколько XP нужно, чтобы перейти на следующий уровень.
  final int xpForNextLevel;
  final int totalXp;

  double get fraction => xpForNextLevel <= 0
      ? 0.0
      : (xpIntoLevel / xpForNextLevel).clamp(0.0, 1.0).toDouble();
}