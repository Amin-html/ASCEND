import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:ascend/core/router/app_routes.dart';
import 'package:ascend/core/services/service_providers.dart';
import 'package:ascend/core/theme/app_colors.dart';
import 'package:ascend/core/theme/app_dimens.dart';
import 'package:ascend/core/theme/app_typography.dart';
import 'package:ascend/core/utils/day_key.dart';
import 'package:ascend/core/utils/formatters.dart';
import 'package:ascend/features/focus/data/focus_providers.dart';
import 'package:ascend/features/focus/domain/focus_models.dart';
import 'package:ascend/features/focus/domain/focus_timer.dart';
import 'package:ascend/features/focus/presentation/focus_summary_dialog.dart';
import 'package:ascend/features/gamification/data/gamification_providers.dart';
import 'package:ascend/features/gamification/domain/completion_result.dart';
import 'package:ascend/features/gamification/presentation/level_up_dialog.dart';
import 'package:ascend/features/tasks/data/task_providers.dart';
import 'package:ascend/features/tasks/domain/task.dart';
import 'package:ascend/features/tasks/domain/task_enums.dart';
import 'package:ascend/shared/widgets/app_card.dart';
import 'package:ascend/shared/widgets/confirm_dialog.dart';
import 'package:ascend/shared/widgets/progress_ring.dart';
import 'package:ascend/shared/widgets/split_row.dart';

enum _ExitChoice { keep, save, discard }

const _presetMinutes = [15, 25, 45, 60, 90];

class FocusScreen extends ConsumerStatefulWidget {
  const FocusScreen({super.key, this.taskId});

  final String? taskId;

  @override
  ConsumerState<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends ConsumerState<FocusScreen> {
  FocusMode _mode = FocusMode.countdown;
  int _minutes = 25;
  String? _taskId;

  /// null: настройка. Иначе сессия идёт, стоит на паузе или сохраняется.
  FocusTimer? _timer;
  Timer? _ticker;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _taskId = widget.taskId;
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _start() {
    final now = ref.read(clockProvider).now();
    final base = _mode == FocusMode.countdown
        ? FocusTimer.countdown(Duration(minutes: _minutes))
        : FocusTimer.stopwatch();
    setState(() => _timer = base.start(now));
    _ticker?.cancel();
    _ticker = Timer.periodic(
      const Duration(milliseconds: 250),
          (_) => _onTick(),
    );
  }

  void _onTick() {
    final timer = _timer;
    if (!mounted || timer == null || _saving) return;
    final now = ref.read(clockProvider).now();
    if (timer.isRunning && timer.isComplete(now)) {
      unawaited(_finish(auto: true));
      return;
    }
    setState(() {});
  }

  void _togglePause() {
    final timer = _timer;
    if (timer == null || _saving) return;
    final now = ref.read(clockProvider).now();
    setState(() {
      _timer = timer.isRunning ? timer.pause(now) : timer.resume(now);
    });
  }

  Future<void> _finish({bool auto = false}) async {
    final timer = _timer;
    if (timer == null || _saving) return;
    _ticker?.cancel();

    final now = ref.read(clockProvider).now();
    final done = timer.finish(now);
    final seconds = done.elapsed(now).inSeconds;
    final input = FocusSessionInput(
      mode: done.mode,
      plannedSeconds: done.planned?.inSeconds,
      actualSeconds: seconds,
      startedAt: done.startedAt ?? now,
      taskId: _taskId,
    );
    setState(() {
      _timer = done;
      _saving = true;
    });

    CompletionResult? result;
    var failed = false;
    try {
      result = await ref.read(focusActionsProvider).complete(input);
    } on Object {
      failed = true;
    }
    if (!mounted) return;

    setState(() {
      _timer = null;
      _saving = false;
    });

    if (failed) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(content: Text('Could not save the session.')),
        );
      return;
    }

    final minutesPerXp = ref.read(xpEngineProvider).config.focusMinutesPerXp;
    await showFocusSummary(
      context,
      seconds: seconds,
      result: result,
      auto: auto,
      minutesPerXp: minutesPerXp,
    );
    if (result != null && result.leveledUp && mounted) {
      await showLevelUpDialog(context, result);
    }
  }

  Future<void> _discard() async {
    if (_saving) return;
    final ok = await showConfirmDialog(
      context,
      title: 'Discard session?',
      message: 'The time you have focused will not be saved.',
      confirmLabel: 'Discard',
      destructive: true,
    );
    if (!ok || !mounted) return;
    _ticker?.cancel();
    setState(() => _timer = null);
  }

  void _leave() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.home);
    }
  }

  Future<void> _onPopBlocked() async {
    if (_saving) return;
    final choice = await showDialog<_ExitChoice>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Session in progress'),
        content: const Text(
          'Save what you have focused so far, or discard it?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(_ExitChoice.keep),
            child: const Text('Keep going'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(_ExitChoice.discard),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Discard'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(_ExitChoice.save),
            child: const Text('Save and exit'),
          ),
        ],
      ),
    );
    if (!mounted) return;

    switch (choice) {
      case _ExitChoice.save:
        await _finish();
        if (mounted) _leave();
      case _ExitChoice.discard:
        _ticker?.cancel();
        setState(() => _timer = null);
        _leave();
      case _ExitChoice.keep:
      case null:
        break;
    }
  }

  Future<void> _pickTask(List<Task> open) async {
    final choice = await showModalBottomSheet<_TaskChoice>(
      context: context,
      constraints: const BoxConstraints(maxWidth: 560),
      builder: (context) => _TaskPickerSheet(tasks: open, selectedId: _taskId),
    );
    if (choice == null || !mounted) return;
    setState(() => _taskId = choice.taskId);
  }

  @override
  Widget build(BuildContext context) {
    final timer = _timer;

    return PopScope(
      canPop: timer == null,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) unawaited(_onPopBlocked());
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Focus')),
        body: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: timer == null
                  ? _buildSetup(context)
                  : _buildRunning(context, timer),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSetup(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final config = ref.watch(xpEngineProvider).config;
    final now = ref.watch(clockProvider).now();
    final todayKey = dayKeyOf(now);
    final todaySeconds =
        ref.watch(focusSecondsForDayProvider(todayKey)).value ?? 0;
    final recent =
        ref.watch(recentFocusProvider).value ?? const <FocusSessionEntry>[];

    final todayTasks =
        ref.watch(tasksByDayProvider(todayKey)).value ?? const <Task>[];
    final open = [
      for (final t in todayTasks)
        if (!t.isCompleted && t.status != TaskStatus.cancelled) t,
    ];
    final selectedId = _taskId;
    Task? selected;
    if (selectedId != null) {
      selected = open.where((t) => t.id == selectedId).firstOrNull ??
          ref.watch(focusTaskProvider(selectedId)).value;
    }

    final preview = _mode == FocusMode.countdown
        ? Duration(minutes: _minutes)
        : Duration.zero;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        SegmentedButton<FocusMode>(
          showSelectedIcon: false,
          style: SegmentedButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
            selectedForegroundColor: AppColors.textPrimary,
            selectedBackgroundColor: AppColors.primary.withValues(alpha: 0.25),
            side: const BorderSide(color: AppColors.border),
          ),
          segments: const [
            ButtonSegment(value: FocusMode.countdown, label: Text('Timer')),
            ButtonSegment(value: FocusMode.stopwatch, label: Text('Stopwatch')),
          ],
          selected: {_mode},
          onSelectionChanged: (selection) =>
              setState(() => _mode = selection.first),
        ),
        const SizedBox(height: AppSpacing.xxl),
        Center(
          child: ProgressRing(
            value: 0,
            size: 220,
            strokeWidth: 12,
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  formatClock(preview),
                  maxLines: 1,
                  softWrap: false,
                  style: AppTypography.numeric.copyWith(fontSize: 48),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        if (_mode == FocusMode.countdown)
          Wrap(
            alignment: WrapAlignment.center,
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final m in _presetMinutes)
                ChoiceChip(
                  showCheckmark: false,
                  label: Text(formatMinutes(m)),
                  selected: _minutes == m,
                  onSelected: (_) => setState(() => _minutes = m),
                ),
            ],
          ),
        const SizedBox(height: AppSpacing.xl),
        AppCard(
          onTap: () => _pickTask(open),
          child: Row(
            children: [
              const Icon(
                Icons.link_rounded,
                color: AppColors.primaryLight,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Task',
                      style: text.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      selected?.title ?? 'No task',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.titleMedium,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        FilledButton.icon(
          onPressed: _start,
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text('Start'),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          '${config.focusMinutesPerXp} min of focus = 1 XP, '
              'up to ${config.focusMaxXpPerSession} XP per session.',
          textAlign: TextAlign.center,
          style: text.bodySmall?.copyWith(color: AppColors.textMuted),
        ),
        const SizedBox(height: AppSpacing.xxl),
        SplitRow(
          left: Text('Today', style: text.titleMedium),
          right: Text(
            formatMinutes(todaySeconds ~/ 60),
            style: text.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        if (recent.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          for (final entry in recent)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _RecentTile(entry: entry),
            ),
        ],
      ],
    );
  }

  Widget _buildRunning(BuildContext context, FocusTimer timer) {
    final text = Theme.of(context).textTheme;
    final now = ref.watch(clockProvider).now();
    final elapsed = timer.elapsed(now);
    final remaining = timer.remaining(now);
    final planned = timer.planned;

    final shown = remaining != null ? ceilToSeconds(remaining) : elapsed;
    final fraction = (remaining != null && planned != null && planned > Duration.zero)
        ? elapsed.inMilliseconds / planned.inMilliseconds
        : (elapsed.inSeconds % 3600) / 3600;

    final running = timer.isRunning;
    final taskId = _taskId;
    final taskTitle = taskId == null
        ? null
        : ref.watch(focusTaskProvider(taskId)).value?.title;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.xl),
          ProgressRing(
            value: fraction.clamp(0.0, 1.0).toDouble(),
            size: 260,
            strokeWidth: 14,
            child: Padding(
              padding: const EdgeInsets.all(36),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      formatClock(shown),
                      maxLines: 1,
                      softWrap: false,
                      style: AppTypography.numeric.copyWith(fontSize: 52),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      running ? 'Stay focused' : 'Paused',
                      maxLines: 1,
                      softWrap: false,
                      style: text.bodyMedium?.copyWith(
                        color: running
                            ? AppColors.textSecondary
                            : AppColors.warning,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (taskTitle != null) ...[
            const SizedBox(height: AppSpacing.lg),
            Text(
              taskTitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: text.titleMedium,
            ),
          ],
          const SizedBox(height: AppSpacing.xxxl),
          if (_saving)
            const Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: CircularProgressIndicator(),
            )
          else ...[
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _togglePause,
                    icon: Icon(
                      running
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                    ),
                    label: Text(running ? 'Pause' : 'Resume'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _finish(),
                    icon: const Icon(Icons.stop_rounded),
                    label: const Text('Finish'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            TextButton(
              onPressed: _discard,
              style: TextButton.styleFrom(foregroundColor: AppColors.danger),
              child: const Text('Discard'),
            ),
          ],
        ],
      ),
    );
  }
}

class _TaskChoice {
  const _TaskChoice(this.taskId);

  final String? taskId;
}

class _TaskPickerSheet extends StatelessWidget {
  const _TaskPickerSheet({required this.tasks, required this.selectedId});

  final List<Task> tasks;
  final String? selectedId;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return SafeArea(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                0,
                AppSpacing.xl,
                AppSpacing.sm,
              ),
              child: Text('Link a task', style: text.titleLarge),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  _Option(
                    title: 'No task',
                    selected: selectedId == null,
                    onTap: () =>
                        Navigator.of(context).pop(const _TaskChoice(null)),
                  ),
                  for (final t in tasks)
                    _Option(
                      title: t.title,
                      selected: selectedId == t.id,
                      onTap: () =>
                          Navigator.of(context).pop(_TaskChoice(t.id)),
                    ),
                  if (tasks.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Text(
                        'No open tasks for today.',
                        style: text.bodyMedium?.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      title: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
      trailing: selected
          ? const Icon(Icons.check_rounded, color: AppColors.primaryLight)
          : null,
    );
  }
}

class _RecentTile extends StatelessWidget {
  const _RecentTile({required this.entry});

  final FocusSessionEntry entry;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final title = taskPart(entry);
    final modeLabel =
    entry.mode == FocusMode.countdown ? 'Timer' : 'Stopwatch';

    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Icon(
            entry.mode == FocusMode.countdown
                ? Icons.hourglass_bottom_rounded
                : Icons.timer_outlined,
            size: 20,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${formatMinutes(math.max(1, entry.actualSeconds ~/ 60))} • '
                      '$modeLabel',
                  style: text.titleMedium,
                ),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (entry.xpAwarded > 0)
            Text(
              '+${entry.xpAwarded} XP',
              style: text.labelSmall?.copyWith(color: AppColors.primaryLight),
            ),
        ],
      ),
    );
  }

  static String taskPart(FocusSessionEntry e) {
    final when = dateTimeLabel(e.startedAt);
    final task = e.taskTitle;
    return task == null ? when : '$when • $task';
  }
}