import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:ascend/core/router/app_routes.dart';
import 'package:ascend/core/theme/app_colors.dart';
import 'package:ascend/core/theme/app_dimens.dart';
import 'package:ascend/features/profile/data/profile_providers.dart';
import 'package:ascend/features/profile/domain/user_profile.dart';
import 'package:ascend/features/settings/data/settings_providers.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  final _name = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    if (_busy) return;
    setState(() => _busy = true);

    try {
      final name = normalizeName(_name.text);
      if (name.isNotEmpty) {
        await ref.read(profileActionsProvider).setName(name);
      }
      await ref
          .read(settingsProvider.notifier)
          .update((s) => s.copyWith(onboardingCompleted: true));
      if (mounted) context.go(AppRoutes.home);
    } on Object {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Something went wrong. Try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: Column(
                children: [
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.primaryGradient,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.4),
                          blurRadius: 28,
                          spreadRadius: -4,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.bolt_rounded,
                      size: 44,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    'ASCEND',
                    style: text.displayLarge?.copyWith(letterSpacing: 2),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Plan. Focus. Complete. Ascend.',
                    style: text.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxxl),
                  const _Feature(
                    icon: Icons.checklist_rounded,
                    title: 'Plan your day',
                    subtitle: 'Tasks, goals and habits in one place.',
                  ),
                  const _Feature(
                    icon: Icons.timer_rounded,
                    title: 'Stay focused',
                    subtitle: 'A timer and stopwatch tied to your tasks.',
                  ),
                  const _Feature(
                    icon: Icons.bolt_rounded,
                    title: 'Level up',
                    subtitle: 'Earn XP, keep streaks, unlock achievements.',
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  TextField(
                    controller: _name,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.done,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(maxNameLength),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Your name (optional)',
                    ),
                    onSubmitted: (_) => _start(),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _busy ? null : _start,
                      child: const Text('Get started'),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => context.push(AppRoutes.backup),
                    child: const Text('Restore from a backup'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Everything stays on this device.',
                    style: text.bodySmall?.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  const _Feature({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadius.control),
            ),
            child: Icon(icon, color: AppColors.primaryLight),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: text.titleMedium),
                Text(
                  subtitle,
                  style: text.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}