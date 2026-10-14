import 'package:ascend/features/notifications/domain/notification_models.dart';

abstract interface class NotificationService {
  /// Подготовка к работе. false: на этом устройстве уведомления недоступны.
  Future<bool> initialize();

  /// Запрос системного разрешения. true: показывать уведомления можно.
  Future<bool> requestPermission();

  /// Отменяет все ожидающие уведомления и планирует переданные.
  Future<void> replaceAll(List<PlannedNotification> items);

  /// Планирует тестовое уведомление через несколько секунд.
  Future<bool> showTest();
}