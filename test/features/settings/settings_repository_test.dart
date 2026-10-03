import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ascend/features/settings/data/shared_prefs_settings_repository.dart';
import 'package:ascend/features/settings/domain/app_settings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<SharedPrefsSettingsRepository> createRepo(
      Map<String, Object> initial,
      ) async {
    SharedPreferences.setMockInitialValues(initial);
    final prefs = await SharedPreferences.getInstance();
    return SharedPrefsSettingsRepository(prefs);
  }

  test('returns defaults when nothing is stored', () async {
    final repo = await createRepo({});
    expect(repo.load(), const AppSettings());
  });

  test('save then load roundtrip', () async {
    final repo = await createRepo({});
    const custom = AppSettings(
      notificationsEnabled: false,
      defaultReminderMinutesBefore: 30,
      dailyPlanReminderEnabled: false,
      dailyPlanReminderMinutes: 18 * 60 + 30,
      onboardingCompleted: true,
    );

    await repo.save(custom);

    expect(repo.load(), custom);
  });

  test('json roundtrip', () {
    const custom = AppSettings(
      notificationsEnabled: false,
      defaultReminderMinutesBefore: 5,
    );
    expect(AppSettings.fromJson(custom.toJson()), custom);
  });

  test('fromJson tolerates missing and wrong-typed fields', () {
    final s = AppSettings.fromJson({'notificationsEnabled': 'yes'});
    expect(s, const AppSettings());
  });
}