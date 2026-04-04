import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moula_flow/providers.dart';

import 'category_management_page.dart';
import 'data/settings_repository.dart';
import 'responsive_layout.dart';
import 'utils/styles.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final theme = Theme.of(context);
    final settingsRepo = ref.read(settingsRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Paramètres',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.5),
        ),
        centerTitle: true,
      ),
      body: ResponsiveCenter(
        maxWidth: 800,
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          children: [
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(AppStyles.kDefaultRadius),
                border: Border.all(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                ),
              ),
              child: SwitchListTile(
                title: const Text(
                  'Mode Sombre',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                subtitle: const Text('Activer le thème sombre'),
                value: isDark,
                activeThumbColor: Colors.white,
                activeTrackColor: Colors.black,
                onChanged: (value) {
                  final newMode = value ? ThemeMode.dark : ThemeMode.light;
                  ref.read(themeModeProvider.notifier).update(newMode);
                  settingsRepo.saveIsDarkMode(value);
                },
                secondary: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(AppStyles.kDefaultRadius),
                border: Border.all(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                ),
              ),
              child: ListTile(
                leading: const Icon(Icons.category_outlined),
                title: const Text(
                  'Gérer les Catégories',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                subtitle: const Text('Ajouter, modifier ou supprimer des rubriques'),
                trailing: const Icon(Icons.keyboard_arrow_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CategoryManagementPage(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(AppStyles.kDefaultRadius),
                border: Border.all(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                ),
              ),
              child: ListTile(
                leading: const Icon(Icons.backup_outlined),
                title: const Text(
                  'Exporter la Sauvegarde',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                subtitle: const Text('Générer un code de sauvegarde (Binaire)'),
                trailing: const Icon(Icons.keyboard_arrow_right),
                onTap: () => _showExportBackupDialog(context, settingsRepo),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(AppStyles.kDefaultRadius),
                border: Border.all(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                ),
              ),
              child: ListTile(
                leading: const Icon(Icons.restore_outlined),
                title: const Text(
                  'Restaurer une Sauvegarde',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                subtitle: const Text(
                  'Restaurer depuis un code de sauvegarde',
                ),
                trailing: const Icon(Icons.keyboard_arrow_right),
                onTap: () => _showImportBackupDialog(context, settingsRepo, ref),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Zone de Danger',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.red.withValues(alpha: 0.8),
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
              ),
              child: ListTile(
                leading: const Icon(
                  Icons.delete_forever_outlined,
                  color: Colors.red,
                ),
                title: const Text(
                  'Réinitialiser les données',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Colors.red,
                  ),
                ),
                subtitle: const Text('Supprime toutes les transactions et wallets'),
                onTap: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Confirmation critique'),
                      content: const Text(
                        'Êtes-vous certain de vouloir supprimer l\'intégralité de vos données ? Cette action est irréversible.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Annuler'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text(
                            'TOUT SUPPRIMER',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await settingsRepo.clearAllDataExceptTheme();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Données réinitialisées')),
                      );
                      Navigator.pop(context);
                    }
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _showExportBackupDialog(
  BuildContext context,
  SettingsRepository settingsRepo,
) async {
  try {
    final bytes = await settingsRepo.exportBinaryBackup();
    final backupStr = base64Encode(bytes);
    if (!context.mounted) return;

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sauvegarde Binaire'),
        content: SizedBox(
          width: 580,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Ce code contient l\'intégralité de vos données (préférences et base de données).',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 16),
              Container(
                height: 200,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    backupStr,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 10),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: backupStr));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Sauvegarde copiée')),
              );
            },
            child: const Text('Copier'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  } catch (_) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Impossible d\'exporter la sauvegarde')),
    );
  }
}

Future<void> _showImportBackupDialog(
  BuildContext context,
  SettingsRepository settingsRepo,
  WidgetRef ref,
) async {
  final controller = TextEditingController();
  try {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restaurer Sauvegarde'),
        content: SizedBox(
          width: 580,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Collez le code de sauvegarde binaire ci-dessous. Toutes les données actuelles seront écrasées.',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                minLines: 8,
                maxLines: 12,
                decoration: const InputDecoration(
                  hintText: 'Collez le code ici...',
                  border: OutlineInputBorder(),
                ),
                style: const TextStyle(fontFamily: 'monospace', fontSize: 10),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Restaurer'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final trimmed = controller.text.trim();
    if (trimmed.isEmpty) return;

    final bytes = base64Decode(trimmed);
    await settingsRepo.importBinaryBackup(bytes);
    
    // Invalidate providers to refresh data
    ref.invalidate(walletsProvider);
    ref.invalidate(transactionsProvider);
    ref.invalidate(categoriesProvider);
    ref.invalidate(budgetsProvider);
    ref.invalidate(recurringPaymentsProvider);
    
    // Re-initialize theme and name
    final newName = await settingsRepo.loadUserName();
    final isDark = await settingsRepo.loadIsDarkMode();
    ref.read(userNameProvider.notifier).update(newName);
    ref.read(themeModeProvider.notifier).update(isDark ? ThemeMode.dark : ThemeMode.light);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Restauration réussie !')),
    );
    Navigator.pop(context);
  } on FormatException catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Code invalide: ${e.message}')),
    );
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Erreur: $e')),
    );
  } finally {
    controller.dispose();
  }
}
