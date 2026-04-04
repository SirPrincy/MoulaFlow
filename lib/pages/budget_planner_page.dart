import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers.dart';
import '../responsive_layout.dart';
import '../widgets/app_menu_bar.dart';
import '../widgets/app_side_menu.dart';
import '../widgets/budget_card.dart';
import '../widgets/add_budget_sheet.dart';
import 'budget_detail_page.dart';

class BudgetPlannerPage extends ConsumerWidget {
  const BudgetPlannerPage({super.key});

  void _showAddBudget(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => const AddBudgetSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetsAsync = ref.watch(budgetsProvider);

    Widget content = budgetsAsync.when(
      data: (budgets) {
        if (budgets.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 80,
                  color: Colors.grey.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'Aucun budget défini',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.grey,
                      ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Créez votre premier budget pour suivre vos dépenses.',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => _showAddBudget(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Créer un budget'),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(budgetsProvider),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: budgets.length == 1
                ? Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: BudgetCard(
                        budgetId: budgets.first.id,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BudgetDetailPage(budgetId: budgets.first.id),
                            ),
                          );
                        },
                      ),
                    ),
                  )
                : GridView.builder(
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 450,
                      mainAxisExtent: 180,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: budgets.length,
                    itemBuilder: (context, index) {
                      final budget = budgets[index];
                      return BudgetCard(
                        budgetId: budget.id,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BudgetDetailPage(budgetId: budget.id),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Erreur: $e')),
    );

    final sideMenu = AppSideMenu(
      currentRoute: '/budgets',
      isCollapsed: false,
      onDataChange: () => ref.invalidate(budgetsProvider),
    );

    if (context.isMobileScreen) {
      return Scaffold(
        appBar: const AppMenuBar(title: 'Budgets'),
        drawer: Drawer(child: sideMenu),
        body: content,
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showAddBudget(context),
          child: const Icon(Icons.add),
        ),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          SizedBox(width: 280, child: sideMenu),
          Expanded(
            child: Scaffold(
              appBar: AppMenuBar(
                title: 'Budgets',
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: FilledButton.icon(
                      onPressed: () => _showAddBudget(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Nouveau Budget'),
                    ),
                  ),
                ],
              ),
              body: content,
            ),
          ),
        ],
      ),
    );
  }
}
