import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moula_flow/providers.dart';
import 'package:moula_flow/l10n/generated/app_localizations.dart';
import 'package:moula_flow/data/export_service.dart';

import 'category_management_page.dart';
import 'data/settings_repository.dart';
import 'responsive_layout.dart';
import 'utils/styles.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _isExportingStr = false;
  bool _isImportingStr = false;
  bool _isExportingCSV = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final theme = Theme.of(context);
    final settingsRepo = ref.read(settingsRepositoryProvider);
    
    final userName = ref.watch(userNameProvider);
    final userColor = ref.watch(userColorProvider);
    final userAvatar = ref.watch(userAvatarProvider);
    final accentColor = ref.watch(accentColorProvider);
    final biometricsEnabled = ref.watch(biometricsEnabledProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.settings,
          style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.5),
        ),
        centerTitle: true,
      ),
      body: ResponsiveCenter(
        maxWidth: 800,
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          children: [
            // --- USER PROFILE SECTION ---
            _buildSectionHeader(l10n.userProfile),
            _buildProfileCard(context, userName, userColor, userAvatar),
            const SizedBox(height: 24),

            // --- APPEARANCE SECTION ---
            _buildSectionHeader(l10n.accentColor),
            _buildAccentColorPicker(ref, accentColor),
            const SizedBox(height: 16),
            _buildSettingsContainer(
              child: SwitchListTile(
                title: Text(
                  l10n.darkMode,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                subtitle: Text(l10n.darkModeSubtitle),
                value: isDark,
                activeThumbColor: accentColor,
                onChanged: (value) {
                  final newMode = value ? ThemeMode.dark : ThemeMode.light;
                  ref.read(themeModeProvider.notifier).update(newMode);
                },
                secondary: Icon(isDark ? Icons.dark_mode : Icons.light_mode, color: accentColor),
              ),
            ),
            const SizedBox(height: 24),

            // --- SECURITY SECTION ---
            _buildSectionHeader(l10n.biometrics),
            _buildSettingsContainer(
              child: SwitchListTile(
                title: Text(
                  l10n.biometrics,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                subtitle: Text(l10n.biometricsSubtitle),
                value: biometricsEnabled,
                activeThumbColor: accentColor,
                onChanged: (value) {
                  ref.read(biometricsEnabledProvider.notifier).update(value);
                },
                secondary: Icon(Icons.fingerprint, color: accentColor),
              ),
            ),
            const SizedBox(height: 24),

            // --- DATA MANAGEMENT SECTION ---
            _buildSectionHeader(l10n.manageCategories),
            _buildSettingsContainer(
              child: ListTile(
                leading: Icon(Icons.category_outlined, color: accentColor),
                title: Text(
                  l10n.manageCategories,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                subtitle: Text(l10n.manageCategoriesSubtitle),
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
            _buildSettingsContainer(
              child: ListTile(
                leading: _isExportingCSV 
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                  : Icon(Icons.table_chart_outlined, color: accentColor),
                title: Text(
                  l10n.exportCSV,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                subtitle: Text(l10n.exportCSVSubtitle),
                onTap: _isExportingCSV ? null : () => _handleCSVExport(),
              ),
            ),
            const SizedBox(height: 16),
            _buildSettingsContainer(
              child: ListTile(
                leading: _isExportingStr
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                  : Icon(Icons.backup_outlined, color: accentColor),
                title: Text(
                  l10n.exportBackup,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                subtitle: Text(l10n.exportBackupSubtitle),
                onTap: _isExportingStr ? null : () => _handleExportBackup(context, settingsRepo),
              ),
            ),
            const SizedBox(height: 16),
            _buildSettingsContainer(
              child: ListTile(
                leading: _isImportingStr
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                  : Icon(Icons.restore_outlined, color: accentColor),
                title: Text(
                  l10n.importBackup,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                subtitle: Text(l10n.importBackupSubtitle),
                onTap: _isImportingStr ? null : () => _showImportBackupDialog(context, settingsRepo, ref),
              ),
            ),
            const SizedBox(height: 32),

            // --- DANGER ZONE ---
            Text(
              l10n.dangerZone.toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Colors.red.withValues(alpha: 0.8),
                letterSpacing: 1.2,
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
                title: Text(
                  l10n.resetData,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Colors.red,
                  ),
                ),
                subtitle: Text(l10n.resetDataSubtitle),
                onTap: () => _handleResetData(context, settingsRepo, l10n),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingsContainer({required Widget child}) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppStyles.kDefaultRadius),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
        ),
      ),
      child: child,
    );
  }

  Widget _buildProfileCard(BuildContext context, String? name, int color, int avatar) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(color),
            Color(color).withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Color(color).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 35,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            child: Icon(
              IconData(avatar, fontFamily: 'MaterialIcons'),
              size: 40,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name ?? 'Utilisateur',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Moula Flow Premium',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              // TODO: Open Profile Edit Dialog
            },
            icon: const Icon(Icons.edit_outlined, color: Colors.white),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccentColorPicker(WidgetRef ref, Color currentAccent) {
    final colors = [
      const Color(0xFFBCC2FF), // Original Moula
      const Color(0xFF00C853), // Emerald
      const Color(0xFF5C6BC0), // Royal
      const Color(0xFFFFB300), // Amber
      const Color(0xFFEF5350), // Ruby
      const Color(0xFF78909C), // Slate
    ];

    return SizedBox(
      height: 60,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: colors.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final color = colors[index];
          final isSelected = color.toARGB32() == currentAccent.toARGB32();
          return GestureDetector(
            onTap: () => ref.read(accentColorProvider.notifier).update(color),
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Colors.white : Colors.transparent,
                  width: 3,
                ),
                boxShadow: isSelected ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 10,
                    spreadRadius: 2,
                  )
                ] : null,
              ),
              child: isSelected ? const Icon(Icons.check, color: Colors.white) : null,
            ),
          );
        },
      ),
    );
  }

  Future<void> _handleCSVExport() async {
    setState(() => _isExportingCSV = true);
    try {
      final transactions = await ref.read(transactionRepositoryProvider).loadTransactions();
      await ExportService.exportTransactionsToCSV(transactions);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur export CSV: $e')),
        );
      }
    } finally {
      setState(() => _isExportingCSV = false);
    }
  }

  Future<void> _handleExportBackup(BuildContext context, SettingsRepository settingsRepo) async {
    setState(() => _isExportingStr = true);
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
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible d\'exporter la sauvegarde')),
        );
      }
    } finally {
      setState(() => _isExportingStr = false);
    }
  }

  Future<void> _handleResetData(BuildContext context, SettingsRepository settingsRepo, AppLocalizations l10n) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.confirmReset),
        content: Text(l10n.confirmResetMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              l10n.deleteAll,
              style: const TextStyle(
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
          SnackBar(content: Text(l10n.dataReset)),
        );
        Navigator.pop(context);
      }
    }
  }

  Future<void> _showImportBackupDialog(
    BuildContext context,
    SettingsRepository settingsRepo,
    WidgetRef ref,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.importBackup),
          content: SizedBox(
            width: 580,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.importBackupSubtitle,
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  minLines: 8,
                  maxLines: 12,
                  decoration: const InputDecoration(
                    hintText: 'Code...',
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
              child: Text(l10n.cancel),
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

      setState(() => _isImportingStr = true);
      
      final bytes = base64Decode(trimmed);
      
      final db = ref.read(databaseProvider);
      await db.hardClose();
      await settingsRepo.importBinaryBackup(bytes);
      
      ref.invalidate(databaseProvider);
      ref.invalidate(walletsProvider);
      ref.invalidate(transactionsProvider);
      ref.invalidate(categoriesProvider);
      ref.invalidate(budgetsProvider);
      ref.invalidate(recurringPaymentsProvider);
      ref.invalidate(dashboardConfigProvider);
      
      final newName = await settingsRepo.loadUserName();
      final isDark = await settingsRepo.loadIsDarkMode();
      final userColor = await settingsRepo.loadUserColor();
      final userAvatar = await settingsRepo.loadUserAvatar();
      final accentColor = await settingsRepo.loadAccentColor();
      
      ref.read(userNameProvider.notifier).update(newName);
      ref.read(themeModeProvider.notifier).update(isDark ? ThemeMode.dark : ThemeMode.light);
      if (userColor != null) ref.read(userColorProvider.notifier).update(userColor);
      if (userAvatar != null) ref.read(userAvatarProvider.notifier).update(userAvatar);
      if (accentColor != null) ref.read(accentColorProvider.notifier).update(Color(accentColor));

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
      setState(() => _isImportingStr = false);
      controller.dispose();
    }
  }
}
