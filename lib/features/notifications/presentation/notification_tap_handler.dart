import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ascend/core/router/app_router.dart';
import 'package:ascend/features/notifications/data/notification_providers.dart';
import 'package:ascend/features/notifications/domain/notification_service.dart';
import 'package:ascend/features/notifications/presentation/notification_routing.dart';

/// Открывает нужный экран, когда пользователь нажал на уведомление:
/// и в работающем приложении, и если оно запустилось от уведомления.
class NotificationTapHandler extends ConsumerStatefulWidget {
  const NotificationTapHandler({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<NotificationTapHandler> createState() =>
      _NotificationTapHandlerState();
}

class _NotificationTapHandlerState
    extends ConsumerState<NotificationTapHandler> {
  StreamSubscription<String>? _subscription;

  @override
  void initState() {
    super.initState();
    final service = ref.read(notificationServiceProvider);
    _subscription = service.taps.listen(_open);
    unawaited(_openLaunchNotification(service));
  }

  Future<void> _openLaunchNotification(NotificationService service) async {
    final payload = await service.takeLaunchPayload();
    if (payload != null) _open(payload);
  }

  void _open(String payload) {
    final target = targetForPayload(payload);
    if (target == null) return;

    // Роутер к этому моменту уже может быть не готов, поэтому ждём кадр.
    WidgetsBinding.instance
      ..addPostFrameCallback((_) {
        if (!mounted) return;
        final router = ref.read(routerProvider);
        if (target.push) {
          unawaited(router.push<void>(target.path));
        } else {
          router.go(target.path);
        }
      })
      ..scheduleFrame();
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}