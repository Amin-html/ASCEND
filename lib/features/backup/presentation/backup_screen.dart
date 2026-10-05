import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ascend/core/theme/app_colors.dart';
import 'package:ascend/core/theme/app_dimens.dart';
import 'package:ascend/core/utils/formatters.dart';
import 'package:ascend/features/backup/data/backup_providers.dart';
import 'package:ascend/features/backup/domain/safety_backup_store.dart';
import 'package:ascend/features/backup/presentation/backup_dialogs.dart';
import 'package:ascend/features/backup/presentation/backup_flow.dart';
import 'package:ascend/features/settings/data/settings_providers.dart';
import 'package:ascend/shared/widgets/app_card.dart';

class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  /// Идёт сценарий (в том числе открыт диалог): кнопки заблокированы.
  bool _running = false;

  /// Идёт тяжёлая работа: показываем индикатор.
  bool _working = false;

  Future<void> _run(Future<FlowResult> Function(BackupFlow flow) action) async {
    if (_running) return;
    final messenger = ScaffoldMessenger.of(context);
    final flow = BackupFlow(
      service: ref.read(backupServiceProvider),
      files: ref.read(backupFileGatewayProvider),
      safety: ref.read(safetyBackupStoreProvider),
      prompts: DialogBackupPrompts(context),
      onBusy: (busy) {
        if (mounted) setState(() => _working = busy);
      },
    );

    setState(() => _running = true);
    final FlowResult result;
    try {
      result = await action(flow);
    } finally {
      if (mounted) {
        setState(() {
          _running = false;
          _working = false;
        });
      }
    }
    if (!mounted) return;

    if (result.status == FlowStatus.done) {
      // Настройки могли измениться, список safety-копий точно изменился.
      ref.invalidate(settingsProvider);
      ref.invalidate(safetyBackupsProvider);
    }
    if (result.status != FlowStatus.cancelled) {
      messenger
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text(result.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final safety = ref.watch(safetyBackupsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Data & Backup')),
      body: Column(
        children: [
          SizedBox(
            height: 3,
            child: _working ? const LinearProgressIndicator() : null,
          ),
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [
                    _ActionCard(
                      icon: Icons.upload_file_rounded,
                      title: 'Create a backup',
                      description:
                      'Save all your tasks, goals, habits and progress to '
                          'one file. You can protect it with a password.',
                      button: FilledButton.icon(
                        onPressed:
                        _running ? null : () => _run((f) => f.create()),
                        icon: const Icon(Icons.save_alt_rounded),
                        label: const Text('Create backup'),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _ActionCard(
                      icon: Icons.download_rounded,
                      title: 'Restore from a file',
                      description:
                      'Replaces all current data with the content of a '
                          'backup file. A safety copy of your current data is '
                          'saved first.',
                      button: OutlinedButton.icon(
                        onPressed: _running
                            ? null
                            : () => _run((f) => f.restoreFromFile()),
                        icon: const Icon(Icons.folder_open_rounded),
                        label: const Text('Choose backup file'),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    Text('Safety copies', style: text.titleMedium),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Automatic copies made right before each restore. '
                          'The last 3 are kept on this device.',
                      style: text.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    safety.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.all(AppSpacing.lg),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (error, stack) => Text(
                        'Could not load safety copies.',
                        style: text.bodyMedium?.copyWith(
                          color: AppColors.danger,
                        ),
                      ),
                      data: (entries) {
                        if (entries.isEmpty) {
                          return Text(
                            'No safety copies yet.',
                            style: text.bodyMedium?.copyWith(
                              color: AppColors.textMuted,
                            ),
                          );
                        }
                        return Column(
                          children: [
                            for (final entry in entries)
                              Padding(
                                padding: const EdgeInsets.only(
                                  bottom: AppSpacing.md,
                                ),
                                child: _SafetyTile(
                                  entry: entry,
                                  enabled: !_running,
                                  onRestore: () => _run(
                                        (f) => f.restoreSafety(entry.fileName),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.button,
  });

  final IconData icon;
  final String title;
  final String description;
  final Widget button;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primaryLight),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: Text(title, style: text.titleMedium)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            description,
            style: text.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.lg),
          button,
        ],
      ),
    );
  }
}

class _SafetyTile extends StatelessWidget {
  const _SafetyTile({
    required this.entry,
    required this.enabled,
    required this.onRestore,
  });

  final SafetyBackupEntry entry;
  final bool enabled;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final title = entry.fileName.startsWith('safety-before-restore')
        ? 'Before restore'
        : entry.fileName;

    return AppCard(
      child: Row(
        children: [
          const Icon(Icons.history_rounded, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: text.titleMedium),
                Text(
                  '${dateTimeLabel(entry.modified)} • '
                      '${formatBytes(entry.sizeBytes)}',
                  style: text.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: enabled ? onRestore : null,
            child: const Text('Restore'),
          ),
        ],
      ),
    );
  }
}