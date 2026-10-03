import 'package:shared_preferences/shared_preferences.dart';

import 'package:ascend/features/settings/domain/app_settings.dart';
import 'package:ascend/features/settings/domain/settings_repository.dart';

class SharedPrefsSettingsRepository implements SettingsRepository {
  SharedPrefsSettingsRepository(this._prefs);

  final SharedPreferences _prefs;

  static const _notifications = 'settings.notificationsEnabled';
  static const _reminderBefore = 'settings.defaultReminderMinutesBefore';
  static const _dailyEnabled = 'settings.dailyPlanReminderEnabled';
  static const _dailyMinutes = 'settings.dailyPlanReminderMinutes';
  static const _onboarding = 'settings.onboardingCompleted';

  @override
  AppSettings load() {
    const d = AppSettings();
    return AppSettings(
      notificationsEnabled:
      _prefs.getBool(_notifications) ?? d.notificationsEnabled,
      defaultReminderMinutesBefore:
      _prefs.getInt(_reminderBefore) ?? d.defaultReminderMinutesBefore,
      dailyPlanReminderEnabled:
      _prefs.getBool(_dailyEnabled) ?? d.dailyPlanReminderEnabled,
      dailyPlanReminderMinutes:
      _prefs.getInt(_dailyMinutes) ?? d.dailyPlanReminderMinutes,
      onboardingCompleted: _prefs.getBool(_onboarding) ?? d.onboardingCompleted,
    );
  }

  @override
  Future<void> save(AppSettings settings) async {
    await Future.wait([
      _prefs.setBool(_notifications, settings.notificationsEnabled),
      _prefs.setInt(_reminderBefore, settings.defaultReminderMinutesBefore),
      _prefs.setBool(_dailyEnabled, settings.dailyPlanReminderEnabled),
      _prefs.setInt(_dailyMinutes, settings.dailyPlanReminderMinutes),
      _prefs.setBool(_onboarding, settings.onboardingCompleted),
    ]);
  }
}