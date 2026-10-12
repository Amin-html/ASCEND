import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ascend/core/services/messenger.dart';
import 'package:ascend/features/achievements/data/achievement_providers.dart';
import 'package:ascend/features/achievements/domain/achievement_models.dart';

/// Следит за метриками и открывает достижения. Работает всё время,
/// пока открыто приложение, поэтому не важно, откуда пришло действие
/// (задача, фокус, цель, привычка, восстановление из backup).
class AchievementWatcher extends ConsumerStatefulWidget {
  const AchievementWatcher({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<AchievementWatcher> createState() =>
      _AchievementWatcherState();
}

class _AchievementWatcherState extends ConsumerState<AchievementWatcher> {
  bool _busy = false;

  Future<void> _check() async {
    if (_busy) return;
    final metrics = ref.read(achievementMetricsProvider);
    final unlocked = ref.read(unlockedAchievementsProvider).value;
    if (metrics == null || unlocked == null) return;
    if (findNewlyUnlocked(metrics, unlocked.keys.toSet()).isEmpty) return;

    _busy = true;
    try {
      final fresh =
      await ref.read(achievementActionsProvider).unlockNew(metrics);
      if (fresh.isNotEmpty) _announce(fresh);
    } on Object {
      // Повторим при следующем изменении данных.
    } finally {
      _busy = false;
    }
  }

  void _announce(List<AchievementDef> fresh) {
    final names = fresh.map((d) => d.title).join(', ');
    final message = fresh.length == 1
        ? 'Achievement unlocked: $names'
        : 'Achievements unlocked: $names';
    appMessengerKey.currentState?.showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 5)),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(
      achievementMetricsProvider,
          (previous, next) => unawaited(_check()),
    );
    ref.listen(
      unlockedAchievementsProvider,
          (previous, next) => unawaited(_check()),
    );
    return widget.child;
  }
}