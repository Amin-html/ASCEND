abstract final class AppRoutes {
  static const home = '/home';
  static const planner = '/planner';
  static const goals = '/goals';
  static const stats = '/stats';
  static const profile = '/profile';
  static const backup = '/settings/backup';
  static const notifications = '/settings/notifications';
  static const habits = '/habits';
  static const focus = '/focus';
  static const achievements = '/achievements';

  static String goalDetail(String id) => '/goals/$id';

  static String taskDetail(String id) => '/tasks/${Uri.encodeComponent(id)}';

  static String focusForTask(String taskId) =>
      Uri(path: focus, queryParameters: {'taskId': taskId}).toString();
}