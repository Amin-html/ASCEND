import 'package:flutter/material.dart';

import 'package:ascend/core/theme/app_colors.dart';
import 'package:ascend/core/theme/app_dimens.dart';
import 'package:ascend/core/utils/formatters.dart';
import 'package:ascend/features/backup/domain/backup_models.dart';
import 'package:ascend/features/backup/presentation/backup_flow.dart';

const _minPasswordLength = 6;

class DialogBackupPrompts implements BackupPrompts {
  const DialogBackupPrompts(this.context);

  final BuildContext context;

  @override
  Future<CreateChoice?> askCreate() {
    if (!context.mounted) return Future<CreateChoice?>.value();
    return showDialog<CreateChoice>(
      context: context,
      builder: (context) => const _CreateBackupDialog(),
    );
  }

  @override
  Future<RestoreChoice?> askRestore(BackupHeader header, {String? error}) {
    if (!context.mounted) return Future<RestoreChoice?>.value();
    return showDialog<RestoreChoice>(
      context: context,
      builder: (context) => _RestoreDialog(header: header, error: error),
    );
  }
}

class _CreateBackupDialog extends StatefulWidget {
  const _CreateBackupDialog();

  @override
  State<_CreateBackupDialog> createState() => _CreateBackupDialogState();
}

class _CreateBackupDialogState extends State<_CreateBackupDialog> {
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _protect = false;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  bool get _tooShort =>
      _password.text.isNotEmpty && _password.text.length < _minPasswordLength;

  bool get _mismatch =>
      _confirm.text.isNotEmpty && _confirm.text != _password.text;

  bool get _valid =>
      !_protect ||
          (_password.text.length >= _minPasswordLength &&
              _password.text == _confirm.text);

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return AlertDialog(
      title: const Text('Create backup'),
      content: SizedBox(
        width: 380,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Saves your tasks, goals, habits and progress to one file.',
                style: text.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Protect with password'),
                value: _protect,
                onChanged: (value) => setState(() => _protect = value),
              ),
              if (_protect) ...[
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: _password,
                  obscureText: true,
                  enableSuggestions: false,
                  autocorrect: false,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    errorText: _tooShort
                        ? 'Use at least $_minPasswordLength characters'
                        : null,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _confirm,
                  obscureText: true,
                  enableSuggestions: false,
                  autocorrect: false,
                  decoration: InputDecoration(
                    labelText: 'Confirm password',
                    errorText: _mismatch ? 'Passwords do not match' : null,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'If you forget the password, this backup cannot be recovered.',
                  style: text.bodySmall?.copyWith(color: AppColors.warning),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _valid
              ? () => Navigator.of(context).pop(
            CreateChoice(password: _protect ? _password.text : null),
          )
              : null,
          child: const Text('Create'),
        ),
      ],
    );
  }
}

class _RestoreDialog extends StatefulWidget {
  const _RestoreDialog({required this.header, this.error});

  final BackupHeader header;
  final String? error;

  @override
  State<_RestoreDialog> createState() => _RestoreDialogState();
}

class _RestoreDialogState extends State<_RestoreDialog> {
  final _password = TextEditingController();

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  bool get _canRestore =>
      !widget.header.encrypted || _password.text.isNotEmpty;

  void _submit() {
    if (!_canRestore) return;
    Navigator.of(context).pop(
      RestoreChoice(
        password: widget.header.encrypted ? _password.text : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final header = widget.header;
    final s = header.summary;

    return AlertDialog(
      title: const Text('Restore backup?'),
      content: SizedBox(
        width: 380,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SummaryRow('Created', dateTimeLabel(header.createdAt.toLocal())),
              _SummaryRow('Tasks', '${s.tasks} (${s.completedTasks} done)'),
              _SummaryRow('Goals', '${s.goals}'),
              _SummaryRow('Habits', '${s.habits}'),
              _SummaryRow('Notes', '${s.notes}'),
              _SummaryRow('Total XP', '${s.totalXp}'),
              if (header.encrypted) ...[
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    const Icon(
                      Icons.lock_rounded,
                      size: 16,
                      color: AppColors.primaryLight,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'This backup is password protected',
                        style: text.bodySmall,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _password,
                  autofocus: true,
                  obscureText: true,
                  enableSuggestions: false,
                  autocorrect: false,
                  decoration: InputDecoration(
                    labelText: 'Backup password',
                    errorText: widget.error,
                  ),
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) => _submit(),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.control),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      size: 18,
                      color: AppColors.warning,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'This replaces all current data on this device. '
                            'A safety copy of your current data is saved first.',
                        style: text.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _canRestore ? _submit : null,
          child: const Text('Restore'),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: text.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          Flexible(
            child: Text(
              value,
              style: text.bodyMedium,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}