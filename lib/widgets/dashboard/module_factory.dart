import 'package:flutter/material.dart';
import '../../data/dashboard_repository.dart';
import '../../models.dart';
import '../../pages/tag_project_page.dart';
import '../../transactions_page.dart';
import '../dashboard_cards.dart';
import 'balance_card.dart';
import 'category_card.dart';
import 'flow_card.dart';
import 'recent_activity_card.dart';

class DashboardModuleFactory {
  static Widget build({
    required BuildContext context,
    required DashboardWidgetType type,
    required bool isEditMode,
    required double totalBalance,
    required List<Wallet> wallets,
    required Set<String> selectedWalletIds,
    required void Function(String? id) onWalletTap,
    required double Function(String walletId) getWalletBalance,
    required double income,
    required double expenses,
    required Map<String, double> categorySpending,
    required CategoryChartStyle categoryChartStyle,
    required ValueChanged<CategoryChartStyle> onStyleChange,
    required List<Transaction> filteredTxs,
    required String Function(String?) getCategoryName,
    required String Function(Transaction) getWalletCaption,
    required List<double> historicalBalances,
    required List<TagDefinition> tags,
    required List<Transaction> allTransactions,
    required ValueChanged<TagDefinition> onTagTap,
    required VoidCallback onRemove,
  }) {
    final moduleBuilders = <DashboardWidgetType, Widget Function()> {
      DashboardWidgetType.balance: () => BalanceCard(
        totalBalance: totalBalance,
        wallets: wallets,
        selectedWalletIds: selectedWalletIds,
        onWalletTap: onWalletTap,
        getWalletBalance: getWalletBalance,
      ),
      DashboardWidgetType.flow: () => FlowDashboardCard(income: income, expenses: expenses),
      DashboardWidgetType.categories: () => CategoryDashboardCard(
        categorySpending: categorySpending,
        style: categoryChartStyle,
        isEditMode: isEditMode,
        onStyleChange: onStyleChange,
      ),
      DashboardWidgetType.recent: () => RecentActivityCard(
        transactions: filteredTxs,
        getCategoryName: getCategoryName,
        getWalletCaption: getWalletCaption,
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const TransactionsPage()),
          );
        },
      ),
      DashboardWidgetType.trends: () => WealthTrendCard(history: historicalBalances),
      DashboardWidgetType.projects: () => ProjectsSummaryCard(
        tags: tags,
        transactions: allTransactions,
        onTagTap: onTagTap,
      ),
    };

    final module = moduleBuilders[type]?.call() ?? const SizedBox.shrink();

    return Padding(
      key: ValueKey(type),
      padding: const EdgeInsets.only(bottom: 20),
      child: Stack(
        children: [
          module,
          if (isEditMode && type != DashboardWidgetType.balance)
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: const Icon(Icons.remove_circle, color: Colors.red),
                onPressed: onRemove,
              ),
            ),
        ],
      ),
    );
  }
}
