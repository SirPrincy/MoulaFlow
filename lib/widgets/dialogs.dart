import 'package:flutter/material.dart';
import '../utils/styles.dart';

Future<bool?> showDeleteConfirmDialog(BuildContext context, String title) {
  final theme = Theme.of(context);
  return showDialog<bool>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppStyles.kDefaultRadius)),
        title: Text('Confirmation', style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
        content: Text(title, style: TextStyle(color: theme.colorScheme.onSurface)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Annuler', style: TextStyle(color: theme.colorScheme.onSurface)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      );
    },
  );
}
