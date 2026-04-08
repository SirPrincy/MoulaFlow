import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'responsive_layout.dart';
import 'providers.dart';
import 'models.dart';
import 'widgets/transaction_form.dart';
import 'widgets/app_drawer.dart';
import 'widgets/app_menu_bar.dart';
import 'transactions_page.dart';
import 'settings_page.dart';
import 'pages/category_overview_page.dart';
import 'pages/bills_to_pay_page.dart';
import 'pages/recurring_payments_page.dart';
import 'pages/budget_planner_page.dart';
import 'pages/tag_project_page.dart';
import 'pages/project_management_page.dart';
import 'pages/projects_page.dart';
import 'utils/styles.dart';
import 'data/dashboard_repository.dart';
import 'domain/balance_service.dart';
import 'domain/home_metrics_service.dart';
import 'domain/home_interaction_service.dart';
import 'widgets/dashboard_cards.dart';
import 'widgets/dashboard/balance_card.dart';
import 'widgets/dashboard/flow_card.dart';
import 'widgets/dashboard/category_card.dart';
import 'widgets/dashboard/recent_activity_card.dart';
import 'widgets/dashboard/module_states.dart';
import 'widgets/dashboard/modules_layout.dart';

class HomePage extends ConsumerStatefulWidget {
  final bool showRecoveryHint;
  const HomePage({super.key, this.showRecoveryHint = false});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  List<Transaction> _transactions = [];
  List<Wallet> _wallets = [];
  List<TransactionCategory> _categories = [];
  final Set<String> _selectedWalletIds = {};
  bool _isSidebarCollapsed = false;
  bool _isMobileMenuOpen = false;

  final _balanceService = BalanceService();
  final _dashboardRepo = DashboardRepository();
  final _homeMetricsService = HomeMetricsService();
  final _homeInteractionService = HomeInteractionService();

  DashboardConfig _dashboardConfig = DashboardConfig.defaultConfig();
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
    if (widget.showRecoveryHint) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil détecté mais données locales vides. Tu peux tenter une restauration depuis Paramètres > Sauvegarde.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      });
    }
  }

  Future<void> _loadDashboard() async {
    _dashboardConfig = await _dashboardRepo.loadConfig();
    setState(() {});
  }


  double get _totalBalance => _balanceService.computeTotalBalance(
    _wallets,
    _transactions,
    _selectedWalletIds,
  );

  double _getWalletBalance(String walletId) =>
      _balanceService.computeWalletBalance(walletId, _wallets, _transactions);

  Future<void> _openMobilePage(Widget page) async {
    setState(() => _isMobileMenuOpen = false);
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }

  void _toggleMobileMenu() {
    setState(() => _isMobileMenuOpen = !_isMobileMenuOpen);
  }


  String _getWalletName(String? id) {
    if (id == null) return 'Inconnu';
    try {
      return _wallets.firstWhere((w) => w.id == id).name;
    } catch (_) {
      return 'Inconnu';
    }
  }

  String _getCategoryName(String? id) {
    if (id == null) return 'Divers';
    for (var mainCat in _categories) {
      if (mainCat.id == id) return mainCat.name;
      for (var subCat in mainCat.subcategories) {
        if (subCat.id == id) return '${mainCat.name} > ${subCat.name}';
      }
    }
    return 'Inconnu';
  }

  void _showTransactionModal({Transaction? editingTx}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppStyles.kDefaultRadius),
        ),
      ),
      builder: (context) {
        return TransactionForm(
          wallets: _wallets,
          categories: _categories,
          editingTx: editingTx,
        );
      },
    ).then((result) async {
      if (result != null && result is Map) {
        final tx = result['tx'] as Transaction;
        final action = result['action'] as String;

        if (action == 'save') {
          if (editingTx != null) {
            await ref.read(transactionRepositoryProvider).updateTransaction(tx);
          } else {
            await ref.read(transactionRepositoryProvider).insertTransaction(tx);
          }
        } else if (action == 'delete') {
          await ref.read(transactionRepositoryProvider).deleteTransaction(tx.id);
        }

        final walletsToSettle = _homeInteractionService.walletsToSettle(
          wallets: _wallets,
          getWalletBalance: _getWalletBalance,
        );
        for (final wallet in walletsToSettle) {
          await ref.read(walletRepositoryProvider).updateWallet(wallet);
        }
      }
    });
  }

  Future<void> _saveDashboardConfig() async {
    await _dashboardRepo.saveConfig(_dashboardConfig);
  }

  void _showFeedback(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<bool> _confirmRemoveModule(DashboardWidgetType type) async {
    final decision = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Retirer le module ?'),
        content: Text(
          'Le module ${type.name} sera retiré du dashboard. Tu pourras le réajouter ensuite.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Retirer'),
          ),
        ],
      ),
    );
    return decision ?? false;
  }


  Widget _buildMobileOverlayMenu(ThemeData theme) {
    final menuItems = <({
      IconData icon,
      String label,
      VoidCallback onTap,
    })>[
      (
        icon: Icons.dashboard_outlined,
        label: 'Tableau de bord',
        onTap: () => setState(() => _isMobileMenuOpen = false),
      ),
      (
        icon: Icons.receipt_long_outlined,
        label: 'Transactions',
        onTap: () => _openMobilePage(const TransactionsPage()),
      ),
      (
        icon: Icons.receipt_outlined,
        label: 'À payer',
        onTap: () => _openMobilePage(const BillsToPayPage()),
      ),
      (
        icon: Icons.receipt_long,
        label: 'Dettes',
        onTap: () => _openMobilePage(
          const CategoryOverviewPage(type: WalletType.debt, title: 'Dettes'),
        ),
      ),
      (
        icon: Icons.savings_outlined,
        label: 'Épargne',
        onTap: () => _openMobilePage(
          const CategoryOverviewPage(type: WalletType.savings, title: 'Épargne'),
        ),
      ),
      (
        icon: Icons.rocket_launch_outlined,
        label: 'Tags',
        onTap: () => _openMobilePage(const ProjectManagementPage()),
      ),
      (
        icon: Icons.task_alt_outlined,
        label: 'Projets séparés',
        onTap: () => _openMobilePage(const ProjectsPage()),
      ),
      (
        icon: Icons.autorenew_outlined,
        label: 'Paiements Récurrents',
        onTap: () => _openMobilePage(const RecurringPaymentsPage()),
      ),
      (
        icon: Icons.pie_chart_outline,
        label: 'Budgets',
        onTap: () => _openMobilePage(
          BudgetPlannerPage(),
        ),
      ),
      (
        icon: Icons.settings_outlined,
        label: 'Paramètres',
        onTap: () => _openMobilePage(
          const SettingsPage(),
        ),
      ),
    ];

    return IgnorePointer(
      ignoring: !_isMobileMenuOpen,
      child: AnimatedOpacity(
        opacity: _isMobileMenuOpen ? 1 : 0,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        child: AnimatedScale(
          scale: _isMobileMenuOpen ? 1 : 0.96,
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          child: Container(
            color: theme.colorScheme.surface.withValues(alpha: 0.98),
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 360),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final item in menuItems)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: FilledButton.tonal(
                              onPressed: item.onTap,
                              style: FilledButton.styleFrom(
                                minimumSize: const Size.fromHeight(52),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(item.icon, size: 20),
                                  const SizedBox(width: 10),
                                  Text(
                                    item.label,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }



  Widget _buildDashboardModule(
    DashboardWidgetType type, {
    required List<Transaction> filteredTxs,
    required List<TagDefinition> tags,
    required double income,
    required double expenses,
    required Map<String, double> categorySpending,
    required List<double> historicalBalances,
  }) {
    final moduleBuilders = <DashboardWidgetType, Widget Function()>{
      DashboardWidgetType.balance: () => BalanceCard(
          totalBalance: _totalBalance,
          wallets: _wallets,
          selectedWalletIds: _selectedWalletIds,
          onWalletTap: (id) => setState(() {
            if (id == null) {
              _selectedWalletIds.clear();
            } else if (_selectedWalletIds.contains(id)) {
              _selectedWalletIds.remove(id);
            } else {
              _selectedWalletIds.add(id);
            }
          }),
          getWalletBalance: _getWalletBalance,
        ),
      DashboardWidgetType.flow: () => FlowDashboardCard(income: income, expenses: expenses),
      DashboardWidgetType.categories: () => CategoryDashboardCard(
          categorySpending: categorySpending,
          style: _dashboardConfig.categoryChartStyle,
          isEditMode: _isEditMode,
          onStyleChange: (CategoryChartStyle style) {
            setState(() {
              _dashboardConfig = DashboardConfig(
                order: _dashboardConfig.order,
                visible: _dashboardConfig.visible,
                categoryChartStyle: style,
              );
              _saveDashboardConfig();
            });
            _showFeedback('Style du module catégories mis à jour.');
          },
        ),
      DashboardWidgetType.recent: () => RecentActivityCard(
          transactions: filteredTxs,
          getCategoryName: _getCategoryName,
          getWalletCaption: (tx) =>
              tx.type == TransactionType.transfer
              ? '${_getWalletName(tx.fromWalletId)} → ${_getWalletName(tx.toWalletId)}'
              : _getWalletName(tx.walletId),
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const TransactionsPage(),
              ),
            );
          },
        ),
      DashboardWidgetType.trends: () => WealthTrendCard(history: historicalBalances),
      DashboardWidgetType.projects: () => ProjectsSummaryCard(
          tags: tags,
          transactions: _transactions,
          onTagTap: (tag) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TagProjectPage(tag: tag),
              ),
            );
          },
        ),
    };
    final mod = moduleBuilders[type]?.call() ??
        const SizedBox.shrink();

    return Padding(
      key: ValueKey(type),
      padding: const EdgeInsets.only(bottom: 20),
      child: Stack(
        children: [
          mod,
          if (_isEditMode && type != DashboardWidgetType.balance)
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: const Icon(
                  Icons.remove_circle,
                  color: Colors.red,
                ),
                onPressed: () async {
                  final confirmed = await _confirmRemoveModule(type);
                  if (!confirmed) return;
                  setState(() {
                    _dashboardConfig.visible.remove(type);
                    _saveDashboardConfig();
                  });
                  _showFeedback('Module ${type.name} retiré.');
                },
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final walletsAsync = ref.watch(walletsProvider);
    final txsAsync = ref.watch(transactionsProvider);
    final catsAsync = ref.watch(categoriesProvider);
    final tagsAsync = ref.watch(tagsProvider);

    final isDashboardLoading = ref.watch(
      walletsProvider.select((state) => state.isLoading),
    ) ||
        ref.watch(
          transactionsProvider.select((state) => state.isLoading),
        ) ||
        ref.watch(
          categoriesProvider.select((state) => state.isLoading),
        );

    if (isDashboardLoading) {
      return const Scaffold(body: DashboardLoadingState());
    }

    if (walletsAsync.hasError || txsAsync.hasError || catsAsync.hasError) {
      return const Scaffold(
        body: DashboardErrorState(
          message: 'Erreur de chargement des données du dashboard.',
        ),
      );
    }

    _wallets = walletsAsync.value ?? [];
    _transactions = txsAsync.value ?? [];
    _categories = catsAsync.value ?? [];
    final tags = tagsAsync.value ?? [];
    if (_wallets.isEmpty && _transactions.isEmpty && _categories.isEmpty) {
      return const Scaffold(
        body: DashboardEmptyState(
          title: 'Tableau de bord vide',
          subtitle: 'Ajoute un portefeuille ou une transaction pour démarrer.',
        ),
      );
    }

    final theme = Theme.of(context);
    final metricsSelectionKey = (_selectedWalletIds.toList()..sort()).join(',');
    final metricsAsync = ref.watch(homeMetricsProvider(metricsSelectionKey));
    final flowAsync = ref.watch(homeFlowProvider(metricsSelectionKey));
    final categorySpendAsync = ref.watch(homeCategorySpendProvider(metricsSelectionKey));

    final metrics = metricsAsync.value ?? _homeMetricsService.compute(
      transactions: _transactions,
      wallets: _wallets,
      categories: _categories,
      selectedWalletIds: _selectedWalletIds,
    );
    final flow = flowAsync.value ?? HomeFlowMetrics(
      income: metrics.monthIncome,
      expenses: metrics.monthExpense,
    );
    final income = flow.income;
    final expenses = flow.expenses;
    final categorySpending = categorySpendAsync.value ?? metrics.spendByCategory;
    final historicalBalances = _balanceService.computeHistoricalBalances(
      _wallets,
      _transactions,
      _selectedWalletIds,
      7,
    );

    final filteredTxs = metrics.recents;

    final dashboardItems = _dashboardConfig.order
        .where((type) => _dashboardConfig.visible.contains(type))
        .toList();

    final dashboardContent = DashboardModulesLayout(
      isEditMode: _isEditMode,
      dashboardItems: dashboardItems,
      onReorder: (oldIndex, newIndex) {
        setState(() {
          if (newIndex > oldIndex) newIndex -= 1;
          final item = dashboardItems.removeAt(oldIndex);
          dashboardItems.insert(newIndex, item);

          final currentOrder = List<DashboardWidgetType>.from(_dashboardConfig.order);
          final globalOldIdx = currentOrder.indexOf(item);
          currentOrder.removeAt(globalOldIdx);
          int globalNewIdx = 0;
          if (newIndex > 0) {
            final prevWidget = dashboardItems[newIndex - 1];
            globalNewIdx = currentOrder.indexOf(prevWidget) + 1;
          }
          currentOrder.insert(globalNewIdx, item);

          if (currentOrder.contains(DashboardWidgetType.balance)) {
            currentOrder.remove(DashboardWidgetType.balance);
            currentOrder.insert(0, DashboardWidgetType.balance);
          }

          _dashboardConfig = DashboardConfig(
            order: currentOrder,
            visible: _dashboardConfig.visible,
            categoryChartStyle: _dashboardConfig.categoryChartStyle,
          );
          _saveDashboardConfig();
        });
      },
      buildModule: (type) => _buildDashboardModule(
        type,
        filteredTxs: filteredTxs,
        tags: tags,
        income: income,
        expenses: expenses,
        categorySpending: categorySpending,
        historicalBalances: historicalBalances,
      ),
    );

    Widget mainContent = SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 16),
          dashboardContent,

          if (_isEditMode)
            Padding(
              padding: const EdgeInsets.all(20),
              child: OutlinedButton.icon(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (context) => ListView(
                      children: DashboardWidgetType.values
                          .where((t) => !_dashboardConfig.visible.contains(t))
                          .map(
                            (t) => ListTile(
                              title: Text(t.name),
                              trailing: const Icon(
                                Icons.add_circle,
                                color: Colors.green,
                              ),
                                onTap: () {
                                  setState(() {
                                    _dashboardConfig.visible.add(t);
                                    _saveDashboardConfig();
                                  });
                                  _showFeedback('Module ${t.name} ajouté.');
                                  Navigator.pop(context);
                                },
                              ),
                          )
                          .toList(),
                    ),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Ajouter un module'),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      AppStyles.kDefaultRadius,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),

          const SizedBox(height: 100),
        ],
      ),
    );

    final sideMenu = AppDrawerContent(
      currentRoute: '/',
      isCollapsed: _isSidebarCollapsed,
      onHomeTap: () {}, // Already home
      onTransactionsTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TransactionsPage())),
      onSettingsTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsPage())),
      onAPayerTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const BillsToPayPage())),
      onDettesTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CategoryOverviewPage(type: WalletType.debt, title: 'Dettes'))),
      onEpargneTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CategoryOverviewPage(type: WalletType.savings, title: 'Épargne'))),
      onProjetTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProjectsPage())),
      onRecurringTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RecurringPaymentsPage())),
      onBudgetsTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const BudgetPlannerPage())),
    );

    if (context.isMobileScreen) {
      return Scaffold(
        appBar: AppMenuBar(
          leading: IconButton(
            onPressed: _toggleMobileMenu,
            icon: Icon(_isMobileMenuOpen ? Icons.close : Icons.menu),
            tooltip: _isMobileMenuOpen ? 'Fermer le menu' : 'Ouvrir le menu',
          ),
          actions: [
            if (!_isEditMode)
              TextButton.icon(
                onPressed: () => setState(() => _isEditMode = true),
                icon: const Icon(Icons.edit, size: 18),
                label: const Text('Modifier'),
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.onSurface,
                ),
              )
            else
              IconButton(
                icon: Icon(
                  Icons.check_circle,
                  color: theme.colorScheme.primary,
                  size: 28,
                ),
                onPressed: () => setState(() => _isEditMode = false),
              ),
          ],
        ),
        body: Stack(
          children: [
            mainContent,
            _buildMobileOverlayMenu(theme),
          ],
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: _isMobileMenuOpen 
            ? null 
            : FloatingActionButton.extended(
                onPressed: _wallets.isEmpty
                    ? () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Créez un wallet d\'abord.')),
                      )
              : () => _showTransactionModal(),
          elevation: 0,
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100),
          ),
          label: const Text(
            'Ajouter',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          icon: const Icon(Icons.add),
        ),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: _isSidebarCollapsed ? 80 : 280,
            child: sideMenu,
          ),
          Expanded(
            child: Scaffold(
              appBar: AppMenuBar(
                leading: IconButton(
                  icon: Icon(
                    _isSidebarCollapsed ? Icons.menu_open : Icons.menu,
                  ),
                  onPressed: () => setState(
                    () => _isSidebarCollapsed = !_isSidebarCollapsed,
                  ),
                ),
                actions: [
                  if (!_isEditMode)
                    TextButton.icon(
                      onPressed: () => setState(() => _isEditMode = true),
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Modifier'),
                      style: TextButton.styleFrom(
                        foregroundColor: theme.colorScheme.onSurface,
                      ),
                    )
                  else
                    IconButton(
                      icon: Icon(
                        Icons.check_circle,
                        color: theme.colorScheme.primary,
                        size: 28,
                      ),
                      onPressed: () => setState(() => _isEditMode = false),
                    ),
                ],
              ),
              body: ResponsiveCenter(maxWidth: 1000, child: mainContent),
              floatingActionButton: FloatingActionButton.extended(
                onPressed: _wallets.isEmpty
                    ? () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Créez un wallet d\'abord.'),
                        ),
                      )
                    : () => _showTransactionModal(),
                elevation: 0,
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100),
                ),
                label: const Text(
                  'Ajouter',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                icon: const Icon(Icons.add),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
