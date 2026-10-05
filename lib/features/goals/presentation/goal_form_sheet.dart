import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ascend/core/services/service_providers.dart';
import 'package:ascend/core/theme/app_dimens.dart';
import 'package:ascend/core/utils/formatters.dart';
import 'package:ascend/features/goals/data/goal_providers.dart';
import 'package:ascend/features/goals/domain/goal_models.dart';
import 'package:ascend/features/tasks/data/task_providers.dart';
import 'package:ascend/features/tasks/domain/category.dart';

/// Возвращает id сохранённой цели или null, если форму закрыли.
Future<String?> showGoalFormSheet(BuildContext context, {Goal? goal}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    constraints: const BoxConstraints(maxWidth: 560),
    builder: (context) => GoalFormSheet(goal: goal),
  );
}

class GoalFormSheet extends ConsumerStatefulWidget {
  const GoalFormSheet({super.key, this.goal});

  final Goal? goal;

  @override
  ConsumerState<GoalFormSheet> createState() => _GoalFormSheetState();
}

class _GoalFormSheetState extends ConsumerState<GoalFormSheet> {
  late final TextEditingController _title;
  late final TextEditingController _description;
  String? _categoryId;
  DateTime? _deadline;
  String? _titleError;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final g = widget.goal;
    _title = TextEditingController(text: g?.title ?? '');
    _description = TextEditingController(text: g?.description ?? '');
    _categoryId = g?.categoryId;
    final d = g?.deadline;
    _deadline = d == null ? null : DateTime(d.year, d.month, d.day);
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  bool _sameDay(DateTime? a, DateTime b) =>
      a != null && a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> _pickDate(DateTime now) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline ?? DateTime(now.year, now.month, now.day),
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 10),
    );
    if (picked != null && mounted) {
      setState(() => _deadline = DateTime(picked.year, picked.month, picked.day));
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
      final existing = widget.goal;
      final description = _description.text.trim();

      final goal = Goal(
        id: existing?.id ?? ref.read(idGeneratorProvider).newId(),
        title: title,
        description: description.isEmpty ? null : description,
        categoryId: _categoryId,
        deadline: _deadline,
        status: existing?.status ?? GoalStatus.active,
        completedAt: existing?.completedAt,
        createdAt: existing?.createdAt ?? now,
        updatedAt: now,
      );

      await ref.read(goalActionsProvider).saveGoal(goal);
      if (mounted) Navigator.of(context).pop(goal.id);
    } on Object {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save the goal. Try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final now = ref.watch(clockProvider).now();
    final today = DateTime(now.year, now.month, now.day);
    final inWeek = DateTime(today.year, today.month, today.day + 7);
    final inMonth = DateTime(today.year, today.month + 1, today.day);
    final categories =
        ref.watch(categoriesProvider).value ?? const <Category>[];
    final existing = widget.goal;
    final deadline = _deadline;
    final isCustom = deadline != null &&
        !_sameDay(deadline, inWeek) &&
        !_sameDay(deadline, inMonth);

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
                existing == null ? 'New goal' : 'Edit goal',
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
                hintText: 'What do you want to achieve?',
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
            const _Label('Deadline'),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                ChoiceChip(
                  showCheckmark: false,
                  label: const Text('No deadline'),
                  selected: deadline == null,
                  onSelected: (_) => setState(() => _deadline = null),
                ),
                ChoiceChip(
                  showCheckmark: false,
                  label: const Text('In 1 week'),
                  selected: _sameDay(deadline, inWeek),
                  onSelected: (_) => setState(() => _deadline = inWeek),
                ),
                ChoiceChip(
                  showCheckmark: false,
                  label: const Text('In 1 month'),
                  selected: _sameDay(deadline, inMonth),
                  onSelected: (_) => setState(() => _deadline = inMonth),
                ),
                ChoiceChip(
                  showCheckmark: false,
                  avatar: const Icon(Icons.calendar_today_rounded, size: 14),
                  label: Text(isCustom ? shortDate(deadline) : 'Pick date'),
                  selected: isCustom,
                  onSelected: (_) => _pickDate(now),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: Text(existing == null ? 'Create goal' : 'Save changes'),
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
        style: Theme.of(context).textTheme.labelLarge,
      ),
    );
  }
}