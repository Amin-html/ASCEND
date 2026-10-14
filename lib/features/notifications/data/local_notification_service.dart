import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import 'package:ascend/features/notifications/domain/notification_models.dart';
import 'package:ascend/features/notifications/domain/notification_planner.dart';
import 'package:ascend/features/notifications/domain/notification_service.dart';

/// Реализация на flutter_local_notifications. Любая ошибка платформы
/// превращается в «уведомления недоступны», приложение продолжает работать.
class LocalNotificationService implements NotificationService {
  LocalNotificationService() : _plugin = FlutterLocalNotificationsPlugin();

  static const _channelId = 'ascend_reminders';
  static const _windowsGuid = '6f1c8d52-3b7e-4a94-9c1d-2e5a7b0f4c38';

  static const NotificationDetails _details = NotificationDetails(
    android: AndroidNotificationDetails(
      _channelId,
      'Reminders',
      channelDescription: 'Task reminders and daily plan alerts',
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
    macOS: DarwinNotificationDetails(),
    linux: LinuxNotificationDetails(),
    windows: WindowsNotificationDetails(),
  );

  final FlutterLocalNotificationsPlugin _plugin;
  Future<bool>? _init;

  @override
  Future<bool> initialize() => _init ??= _doInitialize();

  Future<bool> _doInitialize() async {
    try {
      final ok = await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
          macOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
          linux: LinuxInitializationSettings(defaultActionName: 'Open ASCEND'),
          windows: WindowsInitializationSettings(
            appName: 'ASCEND',
            appUserModelId: 'com.example.ascend',
            guid: _windowsGuid,
          ),
        ),
      );
      return ok ?? true;
    } on Object {
      return false;
    }
  }

  @override
  Future<bool> requestPermission() async {
    if (!await initialize()) return false;
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        return await android.requestNotificationsPermission() ?? false;
      }
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (ios != null) {
        return await ios.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        ) ??
            false;
      }
      final mac = _plugin.resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin>();
      if (mac != null) {
        return await mac.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        ) ??
            false;
      }
      // Десктоп: отдельного запроса нет.
      return true;
    } on Object {
      return false;
    }
  }

  @override
  Future<void> replaceAll(List<PlannedNotification> items) async {
    if (!await initialize()) return;
    await _cancelPending();

    // Запланированное «в прошлом» платформы отклоняют, поэтому отсеиваем.
    final threshold = DateTime.now().add(const Duration(seconds: 2));
    for (final item in items) {
      if (!item.at.isAfter(threshold)) continue;
      await _schedule(item);
    }
  }

  @override
  Future<bool> showTest() async {
    if (!await initialize()) return false;
    return _schedule(
      PlannedNotification(
        id: testNotificationId,
        title: 'ASCEND',
        body: 'Notifications are working.',
        at: DateTime.now().add(const Duration(seconds: 3)),
      ),
    );
  }

  Future<void> _cancelPending() async {
    try {
      await _plugin.cancelAllPendingNotifications();
    } on Object {
      await _plugin.cancelAll();
    }
  }

  Future<bool> _schedule(PlannedNotification item) async {
    try {
      await _plugin.zonedSchedule(
        id: item.id,
        title: item.title,
        body: item.body,
        // Одноразовые уведомления на конкретный момент: достаточно UTC,
        // локальный часовой пояс нужен только повторяющимся.
        scheduledDate: tz.TZDateTime.from(item.at, tz.UTC),
        notificationDetails: _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: item.payload,
      );
      return true;
    } on Object {
      return false;
    }
  }
}