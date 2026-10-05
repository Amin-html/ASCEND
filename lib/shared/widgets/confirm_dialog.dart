import 'package:flutter/material.dart';

import 'package:ascend/core/theme/app_colors.dart';

Future<bool> showConfirmDialog(
    BuildContext context, {
      required String title,
      required String message,
      required String confirmLabel,
      bool destructive = false,
    }) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: destructive
              ? TextButton.styleFrom(foregroundColor: AppColors.danger)
              : null,
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}