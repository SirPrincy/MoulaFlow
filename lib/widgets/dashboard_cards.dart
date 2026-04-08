import 'package:flutter/material.dart';
import '../responsive_layout.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import '../models.dart';
import '../providers.dart';
import '../data/dashboard_repository.dart';
import '../utils/styles.dart';
import '../utils/app_icons.dart';
import '../pages/projects_page.dart';
import 'tag_edit_dialog.dart';

/// Base class for all dashboard widget cards.
abstract class DashboardCard extends StatelessWidget {
  final VoidCallback? onToggle;
  final bool isEditMode;

  const DashboardCard({super.key, this.onToggle, this.isEditMode = false});

  Widget buildHeader(BuildContext context, String title, {Widget? trailing}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              letterSpacing: 1.2,
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }

  Widget buildContainer(BuildContext context, {required Widget child}) {
    final theme = Theme.of(context);
    
    // Responsive padding and shadow for a premium feel
    final paddingValue = context.responsiveValue(compact: 20.0, medium: 24.0, expanded: 28.0);
    final shadowOpacity = context.responsiveValue(compact: 0.03, medium: 0.02, expanded: 0.015);
    
    return Container(
      padding: EdgeInsets.all(paddingValue),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppStyles.kDefaultRadius),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: context.isCompactScreen ? 0.05 : 0.03)
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: shadowOpacity),
            blurRadius: context.responsiveValue(compact: 20.0, medium: 30.0, expanded: 40.0),
            offset: Offset(0, context.responsiveValue(compact: 10.0, medium: 15.0, expanded: 20.0)),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// 1. Solde Total & Wallets — Dashboard card
class BalanceSummaryCard extends ConsumerWidget {
  final double totalBalance;
  final List<Wallet> wallets;
  final Set<String> selectedWalletIds;
  final Function(String?) onWalletTap;
  final double Function(String) getWalletBalance;
  final bool isEditMode;

  const BalanceSummaryCard({
    super.key,
    required this.totalBalance,
    required this.wallets,
    required this.selectedWalletIds,
    required this.onWalletTap,
    required this.getWalletBalance,
    this.isEditMode = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencySymbol = ref.watch(currencySymbolProvider);
    final decimalDigits = ref.watch(decimalDigitsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Responsive padding and shadow for a premium feel
    final paddingValue = context.responsiveValue(compact: 20.0, medium: 24.0, expanded: 28.0);
    final shadowOpacity = context.responsiveValue(compact: 0.03, medium: 0.02, expanded: 0.015);

    return Container(
      padding: EdgeInsets.all(paddingValue),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppStyles.kDefaultRadius),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: context.isCompactScreen ? 0.05 : 0.03)
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: shadowOpacity),
            blurRadius: context.responsiveValue(compact: 20.0, medium: 30.0, expanded: 40.0),
            offset: Offset(0, context.responsiveValue(compact: 10.0, medium: 15.0, expanded: 20.0)),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                totalBalance < 0 ? 'DÉCOUVERT' : 'PATRIMOINE GLOBAL',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: totalBalance < 0 
                      ? Colors.red 
                      : theme.colorScheme.onSurface.withValues(alpha: 0.45),
                  letterSpacing: 1.4,
                ),
              ),
              Icon(Icons.lock_outline, size: 14, color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
            ],
          ),
          const SizedBox(height: 10),

          // Total Balance
          Text(
            formatAmount(totalBalance, symbol: currencySymbol, decimalDigits: decimalDigits),
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.5,
              color: totalBalance < 0 ? Colors.red : null,
            ),
          ),

          const SizedBox(height: 20),

          // Wallet cards
          SizedBox(
            height: 110,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: wallets.length,
              itemBuilder: (context, index) {
                final wallet = wallets[index];
                return _buildWalletItem(context, wallet, theme, isDark, currencySymbol, decimalDigits);
              },
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildWalletItem(BuildContext context, Wallet wallet, ThemeData theme, bool isDark, String symbol, int decimals) {
    final isSelected = selectedWalletIds.contains(wallet.id);
    final activeText = isDark ? Colors.black : Colors.white;
    final activeBg = isDark ? Colors.white : Colors.black;

    IconData typeIcon;
    Color? accentColor;
    switch (wallet.type) {
      case WalletType.savings: typeIcon = Icons.savings; accentColor = Colors.teal; break;
      case WalletType.debt: 
        typeIcon = wallet.isCredit ? Icons.arrow_downward : Icons.arrow_upward;
        accentColor = wallet.isCredit ? Colors.green : Colors.red;
        break;
      case WalletType.project: typeIcon = Icons.rocket_launch; break;
      case WalletType.cash: typeIcon = Icons.payments; break;
      case WalletType.bank: typeIcon = Icons.account_balance; break;
      case WalletType.mobileMoney: typeIcon = Icons.phone_android; break;
      default: typeIcon = Icons.layers;
    }

    return GestureDetector(
      onTap: () => onWalletTap(wallet.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 130,
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? activeBg : theme.colorScheme.onSurface.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(AppStyles.kDefaultRadius),
          border: Border.all(
            color: isSelected
                ? (accentColor?.withValues(alpha: 0.8) ?? activeBg)
                : (accentColor?.withValues(alpha: 0.2) ?? theme.colorScheme.onSurface.withValues(alpha: 0.08)),
            width: isSelected ? 2 : 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    wallet.name,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? activeText.withValues(alpha: 0.6)
                          : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  typeIcon,
                  size: 12,
                  color: isSelected
                      ? activeText.withValues(alpha: 0.4)
                      : theme.colorScheme.onSurface.withValues(alpha: 0.3),
                ),
              ],
            ),
            Text(
              formatAmount(getWalletBalance(wallet.id), symbol: symbol, decimalDigits: decimals),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
                color: isSelected ? activeText : theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
/// Compact wallet filter bar — used in the Transactions page
// ---------------------------------------------------------------------------
class WalletFilterBar extends ConsumerWidget {
  final double totalBalance;
  final List<Wallet> wallets;
  final Set<String> selectedWalletIds;
  final Function(String?) onWalletTap;
  final double Function(String) getWalletBalance;
  final VoidCallback? onAddWallet;
  final Function(Wallet)? onEditWallet;

  const WalletFilterBar({
    super.key,
    required this.totalBalance,
    required this.wallets,
    required this.selectedWalletIds,
    required this.onWalletTap,
    required this.getWalletBalance,
    this.onAddWallet,
    this.onEditWallet,
  });

  static IconData _typeIcon(WalletType t) {
    switch (t) {
      case WalletType.savings: return Icons.savings;
      case WalletType.debt: return Icons.receipt_long;
      case WalletType.project: return Icons.rocket_launch;
      default: return Icons.layers;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencySymbol = ref.watch(currencySymbolProvider);
    final decimalDigits = ref.watch(decimalDigitsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final allSelected = selectedWalletIds.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    totalBalance < 0 ? 'DÉCOUVERT TOTAL' : 'SOLDE TOTAL',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.3,
                      color: totalBalance < 0 
                          ? Colors.red 
                          : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    formatAmount(totalBalance, symbol: currencySymbol, decimalDigits: decimalDigits),
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                      color: totalBalance < 0 ? Colors.red : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _WalletChip(
                  label: 'Tous',
                  icon: Icons.apps,
                  isSelected: allSelected,
                  isDark: isDark,
                  onTap: () => onWalletTap(null),
                  theme: theme,
                ),
              ),
              ...wallets.map((w) {
                final isSelected = selectedWalletIds.contains(w.id);
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _WalletChip(
                    label: w.name,
                    icon: _typeIcon(w.type),
                    sublabel: formatAmount(getWalletBalance(w.id), symbol: currencySymbol, decimalDigits: decimalDigits),
                    isSelected: isSelected,
                    isDark: isDark,
                    onTap: () => onWalletTap(w.id),
                    onLongPress: onEditWallet != null ? () => onEditWallet!(w) : null,
                    theme: theme,
                  ),
                );
              }),
              if (onAddWallet != null)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _WalletChip(
                    label: 'Ajouter',
                    icon: Icons.add_rounded,
                    isSelected: false,
                    isDark: isDark,
                    onTap: onAddWallet!,
                    theme: theme,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Divider(height: 1, color: theme.colorScheme.onSurface.withValues(alpha: 0.07)),
      ],
    );
  }
}

class _WalletChip extends StatelessWidget {
  final String label;
  final String? sublabel;
  final IconData icon;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final ThemeData theme;

  const _WalletChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
    required this.theme,
    this.sublabel,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final activeBg = isDark ? Colors.white : Colors.black;
    final activeText = isDark ? Colors.black : Colors.white;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeBg : theme.colorScheme.onSurface.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(AppStyles.kDefaultRadius),
          border: Border.all(
            color: isSelected ? activeBg : theme.colorScheme.onSurface.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isSelected ? activeText.withValues(alpha: 0.7) : theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? activeText : theme.colorScheme.onSurface,
              ),
            ),
            if (sublabel != null) ...[
              const SizedBox(width: 6),
              Text(
                sublabel!,
                style: TextStyle(
                  fontSize: 11,
                  color: isSelected
                      ? activeText.withValues(alpha: 0.6)
                      : theme.colorScheme.onSurface.withValues(alpha: 0.45),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}


/// 2. Flux Mensuel (Income vs Expense)
class FlowCard extends DashboardCard {
  final double income;
  final double expenses;

  const FlowCard({super.key, required this.income, required this.expenses});

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final symbol = ref.watch(currencySymbolProvider);
        final decimals = ref.watch(decimalDigitsProvider);
        final total = income + expenses;
        final inPercent = total == 0 ? 0.0 : (income / total);
        
        return buildContainer(
          context,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildHeader(context, 'Flux Mensuel'),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildFlowStat('Revenus', income, Colors.green, symbol, decimals),
                  _buildFlowStat('Dépenses', expenses, Colors.red, symbol, decimals),
                ],
              ),
              const SizedBox(height: 20),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: inPercent,
                  minHeight: 8,
                  backgroundColor: Colors.red.withValues(alpha: 0.2),
                  valueColor: const AlwaysStoppedAnimation(Colors.green),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFlowStat(String label, double amount, Color color, String symbol, int decimals) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(formatAmount(amount, symbol: symbol, decimalDigits: decimals), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
      ],
    );
  }
}

/// 2.5 Evolution du Patrimoine (7 Days Trend)
class WealthTrendCard extends DashboardCard {
  final List<double> history;

  const WealthTrendCard({super.key, required this.history});

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final symbol = ref.watch(currencySymbolProvider);
        final decimals = ref.watch(decimalDigitsProvider);
        final theme = Theme.of(context);
        
        // Find min and max for scaling
        double minVal = history.isEmpty ? 0 : history.reduce(math.min);
        double maxVal = history.isEmpty ? 100 : history.reduce(math.max);
        
        // Add some padding to the range
        final range = maxVal - minVal;
        minVal = (minVal - range * 0.1).floorToDouble();
        maxVal = (maxVal + range * 0.1).ceilToDouble();
        if (minVal == maxVal) maxVal += 10;

        return buildContainer(
          context,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildHeader(context, 'Évolution (7 jours)'),
              const SizedBox(height: 20),
              SizedBox(
                height: 140,
                child: LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: false),
                    titlesData: const FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    minX: 0,
                    maxX: (history.length - 1).toDouble(),
                    minY: minVal,
                    maxY: maxVal,
                    lineBarsData: [
                      LineChartBarData(
                        spots: history.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
                        isCurved: true,
                        color: theme.colorScheme.primary,
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [
                              theme.colorScheme.primary.withValues(alpha: 0.3),
                              theme.colorScheme.primary.withValues(alpha: 0.0),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Derniers 7 jours', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
                  Text(
                    formatAmount(history.last, symbol: symbol, decimalDigits: decimals),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 3. Top Catégories Chart
class CategoryChartCard extends DashboardCard {
  final Map<String, double> categorySpending;
  final CategoryChartStyle style;
  final Function(CategoryChartStyle)? onStyleChange;

  const CategoryChartCard({
    super.key, 
    required this.categorySpending, 
    this.style = CategoryChartStyle.donut,
    this.onStyleChange,
    super.isEditMode,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final symbol = ref.watch(currencySymbolProvider);
        final decimals = ref.watch(decimalDigitsProvider);
        final sortedEntries = categorySpending.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
        final topEntries = sortedEntries.take(4).toList();

        return buildContainer(
          context,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildHeader(
                context, 
                'Top Dépenses',
                trailing: isEditMode ? _buildStyleToggle() : null,
              ),
              SizedBox(
                height: 180,
                child: _buildChart(topEntries),
              ),
              const SizedBox(height: 16),
              ...topEntries.map((e) {
                final color = Colors.primaries[sortedEntries.indexOf(e) % Colors.primaries.length].withValues(alpha: 0.7);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6.0),
                  child: Row(
                    children: [
                      Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
                      const SizedBox(width: 8),
                      Expanded(child: Text(e.key, style: const TextStyle(fontSize: 12))),
                      Text(formatAmount(e.value, symbol: symbol, decimalDigits: decimals), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStyleToggle() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _styleIcon(CategoryChartStyle.donut, Icons.pie_chart_outline),
        _styleIcon(CategoryChartStyle.halfDonut, Icons.timelapse),
        _styleIcon(CategoryChartStyle.bar, Icons.bar_chart),
      ],
    );
  }

  Widget _styleIcon(CategoryChartStyle s, IconData icon) {
    final active = style == s;
    return GestureDetector(
      onTap: () => onStyleChange?.call(s),
      child: Container(
        padding: const EdgeInsets.all(4),
        margin: const EdgeInsets.only(left: 4),
        decoration: BoxDecoration(
          color: active ? Colors.blue.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(icon, size: 14, color: active ? Colors.blue : Colors.grey),
      ),
    );
  }

  Widget _buildChart(List<MapEntry<String, double>> entries) {
    if (entries.isEmpty) return const Center(child: Text('No data'));

    switch (style) {
      case CategoryChartStyle.bar:
        return BarChart(
          BarChartData(
            barGroups: entries.asMap().entries.map((entry) {
              return BarChartGroupData(
                x: entry.key,
                barRods: [
                  BarChartRodData(
                    toY: entry.value.value.abs(),
                    color: Colors.primaries[entry.key % Colors.primaries.length].withValues(alpha: 0.7),
                    width: 16,
                    borderRadius: BorderRadius.circular(4),
                  )
                ],
              );
            }).toList(),
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            titlesData: const FlTitlesData(show: false),
          ),
        );
      case CategoryChartStyle.halfDonut:
        return PieChart(
          PieChartData(
            startDegreeOffset: 180,
            sectionsSpace: 4,
            centerSpaceRadius: 40,
            sections: entries.asMap().entries.map((entry) {
              return PieChartSectionData(
                color: Colors.primaries[entry.key % Colors.primaries.length].withValues(alpha: 0.7),
                value: entry.value.value.abs(),
                title: '',
                radius: 12,
              );
            }).toList(),
          ),
        );
      case CategoryChartStyle.donut:
        return PieChart(
          PieChartData(
            sectionsSpace: 4,
            centerSpaceRadius: 40,
            sections: entries.asMap().entries.map((entry) {
              return PieChartSectionData(
                color: Colors.primaries[entry.key % Colors.primaries.length].withValues(alpha: 0.7),
                value: entry.value.value.abs(),
                title: '',
                radius: 12,
              );
            }).toList(),
          ),
        );
    }
  }
}

/// 4. Dernières Transactions
class RecentTransactionsCard extends DashboardCard {
  final List<Transaction> transactions;
  final String Function(String?) getCategoryName;
  final String Function(Transaction) getWalletCaption;
  final VoidCallback onTap;

  const RecentTransactionsCard({
    super.key,
    required this.transactions,
    required this.getCategoryName,
    required this.getWalletCaption,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final symbol = ref.watch(currencySymbolProvider);
        final decimals = ref.watch(decimalDigitsProvider);
        final theme = Theme.of(context);
        final lastFive = transactions.take(5).toList();

        return buildContainer(
          context,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildHeader(
                context, 
                'Opérations Récentes', 
                trailing: InkWell(
                  onTap: onTap, 
                  child: Row(
                    children: [
                      Text('VOIR TOUT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward, size: 12),
                    ],
                  ),
                ),
              ),
              if (lastFive.isEmpty)
                const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Center(child: Text('Aucune opération.')))
              else
                ...lastFive.map((tx) {
                  final fullCatName = getCategoryName(tx.categoryId);
                  final parts = fullCatName.split(' > ');
                  final mainCat = parts.first;
                  final subCat = parts.length > 1 ? parts.last : null;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: theme.colorScheme.onSurface.withValues(alpha: 0.05), shape: BoxShape.circle),
                          child: Icon(_getIconForType(tx.type), size: 16),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                subCat ?? mainCat, 
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13), 
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (subCat != null)
                                Text(
                                  mainCat, 
                                  style: TextStyle(
                                    fontSize: 10, 
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              if (tx.description.isNotEmpty)
                                Text(
                                  tx.description, 
                                  style: TextStyle(
                                    fontSize: 10, 
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                                    fontStyle: FontStyle.italic,
                                  ), 
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                        Text(
                          formatAmount(tx.amount, symbol: symbol, decimalDigits: decimals),
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: tx.type == TransactionType.income ? Colors.green : (tx.type == TransactionType.expense ? Colors.red : null)),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }

  IconData _getIconForType(TransactionType type) {
    switch (type) {
      case TransactionType.income: return Icons.arrow_downward;
      case TransactionType.expense: return Icons.arrow_upward;
      case TransactionType.transfer: return Icons.swap_horiz;
    }
  }
}

/// 5. Résumé des PROJETS (basés sur les tags de type project)
class ProjectsSummaryCard extends DashboardCard {
  final List<TagDefinition> tags;
  final List<Transaction> transactions;
  final Function(TagDefinition) onTagTap;

  const ProjectsSummaryCard({
    super.key,
    required this.tags,
    required this.transactions,
    required this.onTagTap,
    super.isEditMode,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final symbol = ref.watch(currencySymbolProvider);
        final decimals = ref.watch(decimalDigitsProvider);
        final theme = Theme.of(context);
        
        final projectTags = tags
            .where((tag) => tag.type == TagType.project)
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name));

        return buildContainer(
          context,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildHeader(
                context, 
                'PROJETS',
                trailing: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ProjectsPage()),
                    );
                  },
                  child: Row(
                    children: [
                      Text('TOUT VOIR', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward, size: 12),
                    ],
                  ),
                ),
              ),
              if (projectTags.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: Text('Aucun projet défini.')),
                )
              else
                ...projectTags.take(3).map((tag) {
                  final tagTransactions = transactions.where((tx) => tx.tags.contains(tag.name)).toList();
                  double spent = 0;
                  for (var tx in tagTransactions) {
                    if (tx.type == TransactionType.expense) spent += tx.amount;
                    if (tx.type == TransactionType.income) spent -= tx.amount;
                  }

                  final limit = tag.goalAmount ?? 0;
                  final progress = limit > 0 ? (spent / limit).clamp(0.0, 1.0) : 0.0;
                  final isOverBudget = limit > 0 && spent > limit;

                  return InkWell(
                    onTap: () => onTagTap(tag),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    tag.icon != null 
                                      ? AppIcons.getIconFromStr(tag.icon!) 
                                      : Icons.rocket_launch,
                                    size: 14,
                                    color: tag.color != null ? Color(int.parse(tag.color!.replaceAll('#', '0xFF'))) : theme.colorScheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(tag.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                ],
                              ),
                              Text(
                                formatAmount(spent, symbol: symbol, decimalDigits: decimals),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  color: isOverBudget ? Colors.red : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (limit > 0) ...[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 6,
                                backgroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.05),
                                valueColor: AlwaysStoppedAnimation(isOverBudget ? Colors.red : theme.colorScheme.primary),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Budget: ${formatAmount(limit, symbol: symbol, decimalDigits: decimals)}',
                                  style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                                ),
                                Text(
                                  '${(progress * 100).toStringAsFixed(0)}%',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isOverBudget ? Colors.red : theme.colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ] else ...[
                             Text(
                              'Sans limite de budget',
                              style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }),
              if (isEditMode)
                Center(
                  child: TextButton.icon(
                    onPressed: () {
                      TagEditDialog.show(context, initialType: TagType.project);
                    },
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('AJOUTER UN PROJET', style: TextStyle(fontSize: 11)),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
