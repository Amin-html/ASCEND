class AppSettings {
  const AppSettings({
    this.notificationsEnabled = true,
    this.defaultReminderMinutesBefore = 10,
    this.dailyPlanReminderEnabled = true,
    this.dailyPlanReminderMinutes = 20 * 60,
    this.onboardingCompleted = false,
  });

  factory AppSettings.fromJson(Map<String, Object?> json) {
    const d = AppSettings();

    bool readBool(String key, bool fallback) {
      final v = json[key];
      return v is bool ? v : fallback;
    }

    int readInt(String key, int fallback) {
      final v = json[key];
      return v is int ? v : fallback;
    }

    return AppSettings(
      notificationsEnabled:
      readBool('notificationsEnabled', d.notificationsEnabled),
      defaultReminderMinutesBefore: readInt(
        'defaultReminderMinutesBefore',
        d.defaultReminderMinutesBefore,
      ),
      dailyPlanReminderEnabled:
      readBool('dailyPlanReminderEnabled', d.dailyPlanReminderEnabled),
      dailyPlanReminderMinutes: readInt(
        'dailyPlanReminderMinutes',
        d.dailyPlanReminderMinutes,
      ),
      onboardingCompleted:
      readBool('onboardingCompleted', d.onboardingCompleted),
    );
  }

  final bool notificationsEnabled;
  final int defaultReminderMinutesBefore;
  final bool dailyPlanReminderEnabled;

  /// Время вечернего напоминания в минутах от полуночи (20:00 = 1200).
  final int dailyPlanReminderMinutes;
  final bool onboardingCompleted;

  AppSettings copyWith({
    bool? notificationsEnabled,
    int? defaultReminderMinutesBefore,
    bool? dailyPlanReminderEnabled,
    int? dailyPlanReminderMinutes,
    bool? onboardingCompleted,
  }) {
    return AppSettings(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      defaultReminderMinutesBefore:
      defaultReminderMinutesBefore ?? this.defaultReminderMinutesBefore,
      dailyPlanReminderEnabled:
      dailyPlanReminderEnabled ?? this.dailyPlanReminderEnabled,
      dailyPlanReminderMinutes:
      dailyPlanReminderMinutes ?? this.dailyPlanReminderMinutes,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
    );
  }

  /// Используется при экспорте в backup.
  Map<String, Object?> toJson() => {
    'notificationsEnabled': notificationsEnabled,
    'defaultReminderMinutesBefore': defaultReminderMinutesBefore,
    'dailyPlanReminderEnabled': dailyPlanReminderEnabled,
    'dailyPlanReminderMinutes': dailyPlanReminderMinutes,
    'onboardingCompleted': onboardingCompleted,
  };

  @override
  bool operator ==(Object other) =>
      other is AppSettings &&
          other.notificationsEnabled == notificationsEnabled &&
          other.defaultReminderMinutesBefore == defaultReminderMinutesBefore &&
          other.dailyPlanReminderEnabled == dailyPlanReminderEnabled &&
          other.dailyPlanReminderMinutes == dailyPlanReminderMinutes &&
          other.onboardingCompleted == onboardingCompleted;

  @override
  int get hashCode => Object.hash(
    notificationsEnabled,
    defaultReminderMinutesBefore,
    dailyPlanReminderEnabled,
    dailyPlanReminderMinutes,
    onboardingCompleted,
  );
}