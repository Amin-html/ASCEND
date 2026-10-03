import 'package:drift/drift.dart';

@DataClassName('CategoryRow')
class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 60)();
  IntColumn get colorValue => integer()();
  TextColumn get iconKey => text()();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('RecurrenceRuleRow')
class RecurrenceRules extends Table {
  TextColumn get id => text()();

  /// 0 daily, 1 weekdays, 2 weekly, 3 custom
  IntColumn get type => integer()();
  IntColumn get repeatEvery => integer().withDefault(const Constant(1))();

  /// Битовая маска дней недели: Mon = bit0 ... Sun = bit6.
  IntColumn get weekdaysMask => integer().withDefault(const Constant(0))();
  TextColumn get startDayKey => text()();
  TextColumn get endDayKey => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('GoalRow')
class Goals extends Table {
  TextColumn get id => text()();
  TextColumn get title => text().withLength(min: 1, max: 200)();
  TextColumn get description => text().nullable()();
  TextColumn get categoryId => text()
      .nullable()
      .references(Categories, #id, onDelete: KeyAction.setNull)();
  DateTimeColumn get deadline => dateTime().nullable()();

  /// 0 active, 1 completed, 2 archived
  IntColumn get status => integer().withDefault(const Constant(0))();
  DateTimeColumn get completedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('MilestoneRow')
class Milestones extends Table {
  TextColumn get id => text()();
  TextColumn get goalId =>
      text().references(Goals, #id, onDelete: KeyAction.cascade)();
  TextColumn get title => text().withLength(min: 1, max: 200)();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  BoolColumn get isDone => boolean().withDefault(const Constant(false))();
  DateTimeColumn get completedAt => dateTime().nullable()();
  IntColumn get xpAwarded => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@TableIndex(name: 'idx_tasks_day_key', columns: {#dayKey})
@TableIndex(name: 'idx_tasks_status', columns: {#status})
@DataClassName('TaskRow')
class Tasks extends Table {
  TextColumn get id => text()();
  TextColumn get title => text().withLength(min: 1, max: 200)();
  TextColumn get description => text().nullable()();
  TextColumn get categoryId => text()
      .nullable()
      .references(Categories, #id, onDelete: KeyAction.setNull)();

  /// 0 low, 1 medium, 2 high, 3 urgent
  IntColumn get priority => integer().withDefault(const Constant(1))();

  /// 0 todo, 1 inProgress, 2 completed, 3 cancelled
  IntColumn get status => integer().withDefault(const Constant(0))();

  /// Локальный день плана, формат yyyy-MM-dd. null = без даты.
  TextColumn get dayKey => text().nullable()();
  DateTimeColumn get startAt => dateTime().nullable()();
  IntColumn get estimatedMinutes => integer().nullable()();
  IntColumn get actualMinutes => integer().nullable()();
  IntColumn get xpReward => integer().withDefault(const Constant(10))();
  IntColumn get reminderMinutesBefore => integer().nullable()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  TextColumn get goalId => text()
      .nullable()
      .references(Goals, #id, onDelete: KeyAction.setNull)();
  TextColumn get milestoneId => text()
      .nullable()
      .references(Milestones, #id, onDelete: KeyAction.setNull)();
  TextColumn get recurrenceRuleId => text()
      .nullable()
      .references(RecurrenceRules, #id, onDelete: KeyAction.setNull)();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('NoteRow')
class Notes extends Table {
  TextColumn get id => text()();
  TextColumn get title => text().withDefault(const Constant(''))();
  TextColumn get body => text().withDefault(const Constant(''))();
  TextColumn get taskId => text()
      .nullable()
      .references(Tasks, #id, onDelete: KeyAction.setNull)();
  TextColumn get goalId => text()
      .nullable()
      .references(Goals, #id, onDelete: KeyAction.setNull)();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('HabitRow')
class Habits extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get description => text().nullable()();

  /// 0 daily, 1 weekly
  IntColumn get frequencyType => integer().withDefault(const Constant(0))();
  IntColumn get targetPerPeriod => integer().withDefault(const Constant(1))();

  /// Маска дней недели (127 = каждый день).
  IntColumn get weekdaysMask => integer().withDefault(const Constant(127))();
  IntColumn get xpReward => integer().withDefault(const Constant(5))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('HabitLogRow')
class HabitLogs extends Table {
  TextColumn get id => text()();
  TextColumn get habitId =>
      text().references(Habits, #id, onDelete: KeyAction.cascade)();
  TextColumn get dayKey => text()();
  IntColumn get count => integer().withDefault(const Constant(1))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {habitId, dayKey},
  ];
}

@DataClassName('FocusSessionRow')
class FocusSessions extends Table {
  TextColumn get id => text()();
  TextColumn get taskId => text()
      .nullable()
      .references(Tasks, #id, onDelete: KeyAction.setNull)();

  /// 0 countdown, 1 stopwatch
  IntColumn get mode => integer().withDefault(const Constant(0))();
  IntColumn get plannedSeconds => integer().nullable()();
  IntColumn get actualSeconds => integer().withDefault(const Constant(0))();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime().nullable()();
  IntColumn get xpAwarded => integer().withDefault(const Constant(0))();
  TextColumn get dayKey => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('XpEventRow')
class XpEvents extends Table {
  TextColumn get id => text()();
  IntColumn get amount => integer()();
  TextColumn get sourceType => text()();
  TextColumn get sourceId => text()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {sourceType, sourceId},
  ];
}

@DataClassName('AchievementRow')
class Achievements extends Table {
  TextColumn get code => text()();
  DateTimeColumn get unlockedAt => dateTime().nullable()();
  IntColumn get progress => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {code};
}

@DataClassName('DailyStatRow')
class DailyStats extends Table {
  TextColumn get dayKey => text()();
  IntColumn get tasksPlanned => integer().withDefault(const Constant(0))();
  IntColumn get tasksCompleted => integer().withDefault(const Constant(0))();
  IntColumn get focusSeconds => integer().withDefault(const Constant(0))();
  IntColumn get xpEarned => integer().withDefault(const Constant(0))();
  BoolColumn get planCompleted =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {dayKey};
}

@DataClassName('UserProfileRow')
class UserProfiles extends Table {
  IntColumn get id => integer()();
  TextColumn get name => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}