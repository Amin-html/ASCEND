import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ascend/core/services/service_providers.dart';
import 'package:ascend/core/theme/app_colors.dart';
import 'package:ascend/core/theme/app_dimens.dart';
import 'package:ascend/core/utils/day_key.dart';
import 'package:ascend/core/utils/formatters.dart';
import 'package:ascend/features/gamification/data/gamification_providers.dart';
import 'package:ascend/features/tasks/data/task_providers.dart';
import 'package:ascend/features/tasks/domain/category.dart';
import 'package:ascend/features/tasks/domain/task.dart';
import 'package:ascend/features/tasks/domain/task_enums.dart';
import 'package:ascend/features/tasks/presentation/task_labels.dart';

/// Возвращает true, если задача была сохранена.
Future<bool> showTaskFormSheet(
    BuildContext context, {
      Task? task,
      String? initialDayKey,
    }) async {
  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    constraints: const BoxConstraints(maxWidth: 560),
    builder: (context) =>
        TaskFormSheet(task: task, initialDayKey: initialDayKey),
  );
  return saved ?? false;
}

const _minuteOptions = [15, 30, 45, 60, 90, 120];

class TaskFormSheet extends ConsumerStatefulWidget {
  const TaskFormSheet({super.key, this.task, this.initialDayKey});

  final Task? task;
  final String? initialDayKey;

  @override
  ConsumerState<TaskFormSheet> createState() => _TaskFormSheetState();
}

class _TaskFormSheetState extends ConsumerState<TaskFormSheet> {
  late final TextEditingController _title;
  late final TextEditingController _description;
  String? _categoryId;
  late TaskPriority _priority;
  String? _dayKey;
  int? _minutes;
  String? _titleError;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final t = widget.task;
    _title = TextEditingController(text: t?.title ?? '');
    _description = TextEditingController(text: t?.description ?? '');
    _categoryId = t?.categoryId;
    _priority = t?.priority ?? TaskPriority.medium;
    _minutes = t?.estimatedMinutes;
    _dayKey = t != null
        ? t.dayKey
        : (widget.initialDayKey ?? dayKeyOf(ref.read(clockProvider).now()));
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickDate(DateTime now) async {
    final current = _dayKey;
    final initial = current != null
        ? dateFromDayKey(current)
        : DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null && mounted) {
      setState(() => _dayKey = dayKeyOf(picked));
    }
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    if (title.isEmpty) {
      setState(() => _titleError = 'Enter a title');
      return;
    }
    setState(() => _saving = true);

    try {
      final now = ref.read(clockProvider).now();
      final engine = ref.read(xpEngineProvider);
      final existing = widget.task;
      final description = _description.text.trim();

      final xp = existing != null && existing.isCompleted
          ? existing.xpReward
          : engine.xpForNewTask(
        priority: _priority,
        estimatedMinutes: _minutes,
      );

      final task = Task(
        id: existing?.id ?? ref.read(idGeneratorProvider).newId(),
        title: title,
        description: description.isEmpty ? null : description,
        categoryId: _categoryId,
        priority: _priority,
        status: existing?.status ?? TaskStatus.todo,
        dayKey: _dayKey,
        startAt: existing?.startAt,
        estimatedMinutes: _minutes,
        actualMinutes: existing?.actualMinutes,
        xpReward: xp,
        reminderMinutesBefore: existing?.reminderMinutesBefore,
        completedAt: existing?.completedAt,
        goalId: existing?.goalId,
        milestoneId: existing?.milestoneId,
        recurrenceRuleId: existing?.recurrenceRuleId,
        createdAt: existing?.createdAt ?? now,
        updatedAt: now,
      );

      await ref.read(taskActionsProvider).save(task);
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save the task. Try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final engine = ref.watch(xpEngineProvider);
    final now = ref.watch(clockProvider).now();
    final todayKey = dayKeyOf(now);
    final tomorrowKey = dayKeyOf(DateTime(now.year, now.month, now.day + 1));
    final categories =
        ref.watch(categoriesProvider).value ?? const <Category>[];
    final existing = widget.task;
    final dayKey = _dayKey;

    final reward = existing != null && existing.isCompleted
        ? existing.xpReward
        : engine.xpForNewTask(priority: _priority, estimatedMinutes: _minutes);
    final isCustomDay =
        dayKey != null && dayKey != todayKey && dayKey != tomorrowKey;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: Text(
                existing == null ? 'New task' : 'Edit task',
                style: text.titleLarge,
              ),
            ),
            TextField(
              controller: _title,
              autofocus: existing == null,
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.sentences,
              inputFormatters: [LengthLimitingTextInputFormatter(200)],
              decoration: InputDecoration(
                labelText: 'Title',
                hintText: 'What needs to be done?',
                errorText: _titleError,
              ),
              onChanged: (_) {
                if (_titleError != null) setState(() => _titleError = null);
              },
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _description,
              minLines: 2,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
              ),
            ),
            const _Label('Category'),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final c in categories)
                  ChoiceChip(
                    showCheckmark: false,
                    avatar: CircleAvatar(
                      radius: 5,
                      backgroundColor: Color(c.colorValue),
                    ),
                    label: Text(c.name),
                    selected: _categoryId == c.id,
                    onSelected: (selected) =>
                        setState(() => _categoryId = selected ? c.id : null),
                  ),
              ],
            ),
            const _Label('Priority'),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<TaskPriority>(
                showSelectedIcon: false,
                style: SegmentedButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  selectedForegroundColor: AppColors.textPrimary,
                  selectedBackgroundColor:
                  AppColors.primary.withValues(alpha: 0.25),
                  side: const BorderSide(color: AppColors.border),
                ),
                segments: [
                  for (final p in TaskPriority.values)
                    ButtonSegment(value: p, label: Text(p.label)),
                ],
                selected: {_priority},
                onSelectionChanged: (selection) =>
                    setState(() => _priority = selection.first),
              ),
            ),
            const _Label('Date'),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                ChoiceChip(
                  showCheckmark: false,
                  label: const Text('Today'),
                  selected: dayKey == todayKey,
                  onSelected: (_) => setState(() => _dayKey = todayKey),
                ),
                ChoiceChip(
                  showCheckmark: false,
                  label: const Text('Tomorrow'),
                  selected: dayKey == tomorrowKey,
                  onSelected: (_) => setState(() => _dayKey = tomorrowKey),
                ),
                ChoiceChip(
                  showCheckmark: false,
                  avatar: const Icon(Icons.calendar_today_rounded, size: 14),
                  label: Text(
                    isCustomDay
                        ? shortDate(dateFromDayKey(dayKey))
                        : 'Pick date',
                  ),
                  selected: isCustomDay,
                  onSelected: (_) => _pickDate(now),
                ),
                ChoiceChip(
                  showCheckmark: false,
                  label: const Text('No date'),
                  selected: dayKey == null,
                  onSelected: (_) => setState(() => _dayKey = null),
                ),
              ],
            ),
            const _Label('Estimated time'),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                ChoiceChip(
                  showCheckmark: false,
                  label: const Text('None'),
                  selected: _minutes == null,
                  onSelected: (_) => setState(() => _minutes = null),
                ),
                for (final m in _minuteOptions)
                  ChoiceChip(
                    showCheckmark: false,
                    label: Text(formatMinutes(m)),
                    selected: _minutes == m,
                    onSelected: (_) => setState(() => _minutes = m),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.control),
              ),
              child: Row(
                children: [
                  const Icon(Icons.bolt_rounded, color: AppColors.primaryLight),
                  const SizedBox(width: AppSpacing.sm),
                  Text('Reward: +$reward XP', style: text.titleMedium),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: Text(existing == null ? 'Create task' : 'Save changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xl, bottom: AppSpacing.sm),
      child: Text(
        text,
        style: Theme.of(context)
            .textTheme
            .labelLarge
            ?.copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}