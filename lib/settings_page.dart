import 'package:flutter/material.dart';
import 'responsive_layout.dart';
import 'category_management_page.dart';
import 'data/settings_repository.dart';
import 'utils/styles.dart';

class SettingsPage extends StatelessWidget {
  final ValueNotifier<ThemeMode> themeNotifier;

  const SettingsPage({super.key, required this.themeNotifier});

  @override
  Widget build(BuildContext context) {
    final isDark = themeNotifier.value == ThemeMode.dark;
    final theme = Theme.of(context);
    final settingsRepo = SettingsRepository();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.5)),
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
              border: Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.1)),
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
                themeNotifier.value = value ? ThemeMode.dark : ThemeMode.light;
              },
              secondary: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(AppStyles.kDefaultRadius),
              border: Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.1)),
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
                  MaterialPageRoute(builder: (context) => const CategoryManagementPage()),
                );
              },
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
              leading: const Icon(Icons.delete_forever_outlined, color: Colors.red),
              title: const Text(
                'Réinitialiser les données',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.red),
              ),
              subtitle: const Text('Supprime toutes les transactions et wallets'),
              onTap: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Confirmation critique'),
                    content: const Text('Êtes-vous certain de vouloir supprimer l\'intégralité de vos données ? Cette action est irréversible.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true), 
                        child: const Text('TOUT SUPPRIMER', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                   await settingsRepo.clearAllDataExceptTheme();
                   if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Données réinitialisées')));
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
