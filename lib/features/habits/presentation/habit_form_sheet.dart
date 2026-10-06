import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ascend/core/services/service_providers.dart';
import 'package:ascend/core/theme/app_colors.dart';
import 'package:ascend/core/theme/app_dimens.dart';
import 'package:ascend/features/gamification/data/gamification_providers.dart';
import 'package:ascend/features/habits/data/habit_providers.dart';
import 'package:ascend/features/habits/domain/habit_models.dart';
import 'package:ascend/features/habits/presentation/habit_labels.dart';

/// Возвращает true, если привычка сохранена.
Future<bool> showHabitFormSheet(BuildContext context, {Habit? habit}) async {
  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    constraints: const BoxConstraints(maxWidth: 560),
    builder: (context) => HabitFormSheet(habit: habit),
  );
  return saved ?? false;
}

const _presets = <(String, int)>[
  ('Every day', 127),
  ('Weekdays', 31),
  ('Weekends', 96),
];

class HabitFormSheet extends ConsumerStatefulWidget {
  const HabitFormSheet({super.key, this.habit});

  final Habit? habit;

  @override
  ConsumerState<HabitFormSheet> createState() => _HabitFormSheetState();
}

class _HabitFormSheetState extends ConsumerState<HabitFormSheet> {
  late final TextEditingController _name;
  late final TextEditingController _description;
  late int _mask;
  String? _nameError;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final h = widget.habit;
    _name = TextEditingController(text: h?.name ?? '');
    _description = TextEditingController(text: h?.description ?? '');
    _mask = h?.weekdaysMask ?? allWeekdaysMask;
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  void _toggleDay(int index, bool selected) {
    setState(() {
      _mask = selected ? (_mask | (1 << index)) : (_mask & ~(1 << index));
    });
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = 'Enter a name');
      return;
    }
    setState(() => _saving = true);

    try {
      final now = ref.read(clockProvider).now();
      final existing = widget.habit;
      final description = _description.text.trim();

      final habit = Habit(
        id: existing?.id ?? ref.read(idGeneratorProvider).newId(),
        name: name,
        description: description.isEmpty ? null : description,
        weekdaysMask: _mask,
        xpReward: existing?.xpReward ?? ref.read(xpEngineProvider).xpForHabit(),
        isArchived: existing?.isArchived ?? false,
        createdAt: existing?.createdAt ?? now,
        updatedAt: now,
      );

      await ref.read(habitActionsProvider).saveHabit(habit);
      if (mounted) Navigator.of(context).pop(true);
    } on Object {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save the habit. Try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final existing = widget.habit;
    final reward =
        existing?.xpReward ?? ref.watch(xpEngineProvider).xpForHabit();

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
                existing == null ? 'New habit' : 'Edit habit',
                style: text.titleLarge,
              ),
            ),
            TextField(
              controller: _name,
              autofocus: existing == null,
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.sentences,
              inputFormatters: [LengthLimitingTextInputFormatter(100)],
              decoration: InputDecoration(
                labelText: 'Name',
                hintText: 'e.g. Read 20 pages',
                errorText: _nameError,
              ),
              onChanged: (_) {
                if (_nameError != null) setState(() => _nameError = null);
              },
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _description,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
              ),
            ),
            const _Label('Repeat'),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final preset in _presets)
                  ChoiceChip(
                    showCheckmark: false,
                    label: Text(preset.$1),
                    selected: _mask == preset.$2,
                    onSelected: (_) => setState(() => _mask = preset.$2),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (var i = 0; i < 7; i++)
                  FilterChip(
                    showCheckmark: false,
                    label: Text(weekdayShort[i]),
                    selected: ((_mask >> i) & 1) == 1,
                    onSelected: (selected) => _toggleDay(i, selected),
                  ),
              ],
            ),
            if (_mask == 0)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Text(
                  'Pick at least one day',
                  style: text.bodySmall?.copyWith(color: AppColors.danger),
                ),
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
                  Text('Reward: +$reward XP per check-in', style: text.titleMedium),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: (_saving || _mask == 0) ? null : _save,
                child: Text(existing == null ? 'Create habit' : 'Save changes'),
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