enum Rank {
  beginner('Beginner', 1),
  starter('Starter', 5),
  focused('Focused', 10),
  disciplined('Disciplined', 15),
  advanced('Advanced', 25),
  elite('Elite', 35),
  master('Master', 50);

  const Rank(this.label, this.minLevel);

  final String label;
  final int minLevel;

  /// Следующий ранг или null, если это высший.
  Rank? get next {
    final i = index + 1;
    return i < Rank.values.length ? Rank.values[i] : null;
  }
}