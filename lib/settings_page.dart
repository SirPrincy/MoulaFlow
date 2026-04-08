import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moula_flow/providers.dart';
import 'package:moula_flow/l10n/generated/app_localizations.dart';
import 'package:moula_flow/data/export_service.dart';

import 'category_management_page.dart';
import 'data/settings_repository.dart';
import 'data/app_access_method.dart';
import 'responsive_layout.dart';
import 'utils/styles.dart';
import 'utils/currency_utils.dart';

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
    final locale = ref.watch(localeProvider);
    final currencySymbol = ref.watch(currencySymbolProvider);
    final baseCurrencyCode = ref.watch(baseCurrencyCodeProvider);
    final decimalDigits = ref.watch(decimalDigitsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.settings,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
      ),
      body: ResponsiveCenter(
        maxWidth: context.contentMaxWidth,
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          children: [
            // --- USER PROFILE SECTION ---
            _buildSectionHeader(l10n.userProfile),
            _buildProfileCard(context, userName, userColor, userAvatar),
            const SizedBox(height: 24),

            // --- APPEARANCE SECTION ---
            _buildAccentColorPicker(ref, accentColor),
            const SizedBox(height: 24),

            // --- LOCALIZATION & FORMATTING ---
            _buildSectionHeader(l10n.localizationAndFormat),
            _buildSettingsContainer(
              child: Column(
                children: [
                  _buildLanguagePicker(ref, locale),
                  const Divider(height: 1, indent: 56),
                  _buildCurrencySettings(
                    ref,
                    currencySymbol,
                    baseCurrencyCode,
                    decimalDigits,
                    accentColor,
                    l10n,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildSettingsContainer(
              child: SwitchListTile(
                title: Text(
                  l10n.darkMode,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                subtitle: Text(l10n.darkModeSubtitle),
                value: isDark,
                activeThumbColor: accentColor,
                onChanged: (value) {
                  final newMode = value ? ThemeMode.dark : ThemeMode.light;
                  ref.read(themeModeProvider.notifier).update(newMode);
                },
                secondary: Icon(
                  isDark ? Icons.dark_mode : Icons.light_mode,
                  color: accentColor,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // --- SECURITY SECTION ---
            _buildSectionHeader(l10n.biometrics),
            _buildSettingsContainer(
              child: SwitchListTile(
                title: Text(
                  l10n.biometrics,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                subtitle: Text(l10n.biometricsSubtitle),
                value: biometricsEnabled,
                activeThumbColor: accentColor,
                onChanged: (value) {
                  ref.read(biometricsEnabledProvider.notifier).update(value);
                  ref.read(appAccessMethodProvider.notifier).update(
                        value ? AppAccessMethod.biometric : AppAccessMethod.none,
                      );
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
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
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
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(Icons.table_chart_outlined, color: accentColor),
                title: Text(
                  l10n.exportCSV,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                subtitle: Text(l10n.exportCSVSubtitle),
                onTap: _isExportingCSV ? null : () => _handleCSVExport(),
              ),
            ),
            const SizedBox(height: 16),
            _buildSettingsContainer(
              child: ListTile(
                leading: _isExportingStr
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(Icons.backup_outlined, color: accentColor),
                title: Text(
                  l10n.exportBackup,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                subtitle: Text(l10n.exportBackupSubtitle),
                onTap: _isExportingStr
                    ? null
                    : () => _handleExportBackup(context, settingsRepo),
              ),
            ),
            const SizedBox(height: 16),
            _buildSettingsContainer(
              child: ListTile(
                leading: _isImportingStr
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(Icons.restore_outlined, color: accentColor),
                title: Text(
                  l10n.importBackup,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                subtitle: Text(l10n.importBackupSubtitle),
                onTap: _isImportingStr
                    ? null
                    : () => _showImportBackupDialog(context, settingsRepo, ref),
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

  Widget _buildProfileCard(
    BuildContext context,
    String? name,
    int color,
    int avatar,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(color), Color(color).withValues(alpha: 0.8)],
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
              _getAvatarIcon(avatar), // On appelle une fonction qu'on va créer
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
            onPressed: () => _showProfileEditDialog(context, ref, name, color, avatar),
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
        separatorBuilder: (_, _) => const SizedBox(width: 12),
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
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.4),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white)
                  : null,
            ),
          );
        },
      ),
    );
  }

  Future<void> _handleCSVExport() async {
    setState(() => _isExportingCSV = true);
    try {
      final transactions = await ref
          .read(transactionRepositoryProvider)
          .loadTransactions();
      await ExportService.exportTransactionsToCSV(transactions);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur export CSV: $e')));
      }
    } finally {
      setState(() => _isExportingCSV = false);
    }
  }

  Future<void> _handleExportBackup(
    BuildContext context,
    SettingsRepository settingsRepo,
  ) async {
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
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      backupStr,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10,
                      ),
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

  Future<void> _handleResetData(
    BuildContext context,
    SettingsRepository settingsRepo,
    AppLocalizations l10n,
  ) async {
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.dataReset)));
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
      ref
          .read(themeModeProvider.notifier)
          .update(isDark ? ThemeMode.dark : ThemeMode.light);
      if (userColor != null) {
        ref.read(userColorProvider.notifier).update(userColor);
      }
      if (userAvatar != null) {
        ref.read(userAvatarProvider.notifier).update(userAvatar);
      }
      if (accentColor != null) {
        ref.read(accentColorProvider.notifier).update(Color(accentColor));
      }

      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Restauration réussie !')));
      Navigator.pop(context);
    } on FormatException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Code invalide: ${e.message}')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    } finally {
      setState(() => _isImportingStr = false);
      controller.dispose();
    }
  }

  // --- INSÈRE LA FONCTION ICI ---
  // --- NEW SETTINGS UI HELPERS ---

  Widget _buildLanguagePicker(WidgetRef ref, Locale? currentLocale) {
    final l10n = AppLocalizations.of(context)!;
    final isEn = currentLocale?.languageCode == 'en';
    
    return ListTile(
      leading: Icon(Icons.language, color: Theme.of(context).colorScheme.primary),
      title: Text(
        l10n.language,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLanguageChip(ref, 'FR', !isEn, 'fr'),
          const SizedBox(width: 8),
          _buildLanguageChip(ref, 'EN', isEn, 'en'),
        ],
      ),
    );
  }

  Widget _buildLanguageChip(WidgetRef ref, String label, bool isSelected, String code) {
    final accentColor = ref.watch(accentColorProvider);
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) {
        if (val) ref.read(localeProvider.notifier).update(code);
      },
      selectedColor: accentColor.withValues(alpha: 0.2),
      checkmarkColor: accentColor,
      labelStyle: TextStyle(
        color: isSelected ? accentColor : null,
        fontWeight: isSelected ? FontWeight.bold : null,
      ),
    );
  }

  Widget _buildCurrencySettings(
    WidgetRef ref, 
    String currency, 
    String baseCurrencyCode,
    int decimals, 
    Color accent, 
    AppLocalizations l10n
  ) {
    return Column(
      children: [
        ListTile(
          leading: Icon(Icons.payments_outlined, color: accent),
          title: Text(
            l10n.currencySymbol,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          trailing: SizedBox(
            width: 80,
            child: TextField(
              textAlign: TextAlign.end,
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                fillColor: Colors.transparent,
              ),
              controller: TextEditingController(text: currency)..selection = TextSelection.fromPosition(TextPosition(offset: currency.length)),
              onChanged: (val) => ref.read(currencySymbolProvider.notifier).update(val),
            ),
          ),
        ),
        ListTile(
          leading: Icon(Icons.public_rounded, color: accent),
          title: const Text(
            'Devise de référence',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          trailing: DropdownButton<String>(
            value: baseCurrencyCode,
            underline: const SizedBox.shrink(),
            items: kSupportedCurrencies
                .map(
                  (e) => DropdownMenuItem<String>(
                    value: e.code,
                    child: Text(e.code),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) return;
              ref.read(baseCurrencyCodeProvider.notifier).update(value);
            },
          ),
        ),
        ListTile(
          leading: Icon(Icons.numbers_outlined, color: accent),
          title: Text(
            l10n.decimalDigits,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.remove),
                onPressed: decimals > 0 ? () => ref.read(decimalDigitsProvider.notifier).update(decimals - 1) : null,
              ),
              Text('$decimals', style: const TextStyle(fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: decimals < 4 ? () => ref.read(decimalDigitsProvider.notifier).update(decimals + 1) : null,
              ),
            ],
          ),
        ),
        ListTile(
          leading: Icon(Icons.currency_exchange_rounded, color: accent),
          title: const Text(
            'Taux de change',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          subtitle: const Text('Ajouter / modifier un taux manuel'),
          trailing: TextButton(
            onPressed: () => _showExchangeRateDialog(context, ref, baseCurrencyCode),
            child: const Text('Configurer'),
          ),
        ),
      ],
    );
  }

  Future<void> _showExchangeRateDialog(
    BuildContext context,
    WidgetRef ref,
    String baseCurrencyCode,
  ) async {
    String fromCode = baseCurrencyCode;
    String toCode = 'EUR';
    DateTime effectiveDate = DateTime.now();
    final rateController = TextEditingController();
    if (toCode == fromCode) toCode = 'USD';

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx2, setDialogState) => AlertDialog(
            title: const Text('Configurer un taux'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: fromCode,
                  decoration: const InputDecoration(labelText: 'De'),
                  items: kSupportedCurrencies
                      .map((e) => DropdownMenuItem(value: e.code, child: Text(e.code)))
                      .toList(),
                  onChanged: (v) => setDialogState(() => fromCode = v ?? fromCode),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: toCode,
                  decoration: const InputDecoration(labelText: 'Vers'),
                  items: kSupportedCurrencies
                      .map((e) => DropdownMenuItem(value: e.code, child: Text(e.code)))
                      .toList(),
                  onChanged: (v) => setDialogState(() => toCode = v ?? toCode),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: rateController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Taux',
                    hintText: 'ex: 0.92',
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: ctx2,
                      initialDate: effectiveDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setDialogState(() {
                        effectiveDate = DateTime(picked.year, picked.month, picked.day);
                      });
                    }
                  },
                  icon: const Icon(Icons.calendar_today_rounded, size: 16),
                  label: Text(
                    'Date du taux: ${effectiveDate.day.toString().padLeft(2, '0')}/${effectiveDate.month.toString().padLeft(2, '0')}/${effectiveDate.year}',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Annuler'),
              ),
              FilledButton(
                onPressed: () async {
                  final rate = double.tryParse(rateController.text.replaceAll(',', '.'));
                  if (rate == null || rate <= 0 || fromCode == toCode) return;
                  await ref.read(exchangeRateServiceProvider).setRate(
                        fromCode: fromCode,
                        toCode: toCode,
                        rate: rate,
                        effectiveDate: effectiveDate,
                      );
                  ref.invalidate(exchangeRatesProvider);
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text('Enregistrer'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showProfileEditDialog(
    BuildContext context, 
    WidgetRef ref, 
    String? currentName, 
    int currentColor, 
    int currentAvatar
  ) async {
    final nameController = TextEditingController(text: currentName);
    int selectedColor = currentColor;
    int selectedAvatar = currentAvatar;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Modifier le profil'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nom d\'utilisateur'),
                ),
                const SizedBox(height: 24),
                const Text('Couleur de profil', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    0xFF6200EE, 0xFF00C853, 0xFFFFB300, 0xFFEF5350, 0xFF78909C, 0xFFE91E63
                  ].map((c) => GestureDetector(
                    onTap: () => setDialogState(() => selectedColor = c),
                    child: Container(
                      width: 35,
                      height: 35,
                      decoration: BoxDecoration(
                        color: Color(c),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selectedColor == c ? Colors.black : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                  )).toList(),
                ),
                const SizedBox(height: 24),
                const Text('Avatar', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [59475, 58713, 58241, 57744, 58160].map((a) => IconButton(
                    icon: Icon(_getAvatarIcon(a)),
                    color: selectedAvatar == a ? Color(selectedColor) : null,
                    onPressed: () => setDialogState(() => selectedAvatar = a),
                    style: IconButton.styleFrom(
                      backgroundColor: selectedAvatar == a ? Color(selectedColor).withValues(alpha: 0.1) : null,
                    ),
                  )).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                ref.read(userNameProvider.notifier).update(nameController.text);
                ref.read(userColorProvider.notifier).update(selectedColor);
                ref.read(userAvatarProvider.notifier).update(selectedAvatar);
                Navigator.pop(context);
              },
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getAvatarIcon(int codePoint) {
    switch (codePoint) {
      case 59475:
        return Icons.person;
      case 58713:
        return Icons.account_circle;
      case 58241:
        return Icons.face;
      case 57744:
        return Icons.pets;
      case 58160:
        return Icons.star;
      default:
        return Icons.person;
    }
  }
} // <--- C'est la toute dernière accolade du fichier
