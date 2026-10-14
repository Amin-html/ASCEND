import 'package:ascend/core/router/app_routes.dart';
import 'package:ascend/features/notifications/domain/notification_payload.dart';

class NotificationTarget {
  const NotificationTarget(this.path, {this.push = false});

  final String path;

  /// true: открыть поверх текущего экрана (по «назад» вернёмся).
  final bool push;
}

NotificationTarget? targetForPayload(String? payload) {
  if (payload == null || payload.isEmpty) return null;
  if (payload == planPayload) return const NotificationTarget(AppRoutes.planner);

  final taskId = taskIdFromPayload(payload);
  if (taskId != null) {
    return NotificationTarget(AppRoutes.taskDetail(taskId), push: true);
  }
  return null;
}