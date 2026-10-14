import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ascend/features/notifications/data/notification_providers.dart';
import 'package:ascend/features/notifications/domain/notification_models.dart';

/// Держит расписание уведомлений в соответствии с задачами и настройками.
/// Работает, пока открыто приложение; при запуске один раз пересобирает
/// расписание (в том числе очищает устаревшее).
class NotificationSync extends ConsumerStatefulWidget {
  const NotificationSync({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<NotificationSync> createState() => _NotificationSyncState();
}

class _NotificationSyncState extends ConsumerState<NotificationSync> {
  List<PlannedNotification>? _lastSynced;
  bool _syncing = false;
  bool _pending = false;
  bool _permissionAsked = false;

  @override
  void initState() {
    super.initState();
    ref.listenManual<List<PlannedNotification>?>(
      plannedNotificationsProvider,
          (previous, next) => unawaited(_sync()),
      fireImmediately: true,
    );
  }

  Future<void> _sync() async {
    if (_syncing) {
      _pending = true;
      return;
    }
    _syncing = true;
    try {
      do {
        _pending = false;
        if (!mounted) break;

        final plan = ref.read(plannedNotificationsProvider);
        if (plan == null) break;
        final last = _lastSynced;
        if (last != null && listEquals(last, plan)) break;

        final service = ref.read(notificationServiceProvider);
        // Разрешение просим в тот момент, когда есть что напоминать.
        if (plan.isNotEmpty && !_permissionAsked) {
          _permissionAsked = true;
          await service.requestPermission();
        }
        await service.replaceAll(plan);
        _lastSynced = plan;
      } while (_pending);
    } on Object {
      // Повторим при следующем изменении данных.
    } finally {
      _syncing = false;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}