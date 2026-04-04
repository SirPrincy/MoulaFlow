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
import 'utils/styles.dart';
import 'data/dashboard_repository.dart';
import 'domain/balance_service.dart';
import 'widgets/dashboard_cards.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

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

  DashboardConfig _dashboardConfig = DashboardConfig.defaultConfig();
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
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

  List<Transaction> get _filteredTransactions => _balanceService
      .filterTransactionsByWalletSelection(_transactions, _selectedWalletIds);

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
        if (result['action'] == 'create_wallet') {
          _showWalletDialog();
          return;
        }
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

        // Auto-settle/complete logic for debts and savings
        for (var w in _wallets) {
          if (!w.isSettled && w.targetAmount != null) {
            final balance = _getWalletBalance(w.id);
            double effectiveTarget = w.targetAmount!;

            if (w.type == WalletType.debt &&
                w.interestRate != null &&
                w.interestRate! > 0) {
              effectiveTarget = effectiveTarget * (1 + w.interestRate! / 100);
            }

            // If balance reached or exceeded target, mark as settled/completed
            if (balance >= effectiveTarget) {
              w.isSettled = true;
              await ref.read(walletRepositoryProvider).updateWallet(w);
            }
          }
        }
      }
    });
  }

  Future<void> _saveDashboardConfig() async {
    await _dashboardRepo.saveConfig(_dashboardConfig);
  }

  double _getMonthlyTotal(TransactionType type) {
    final now = DateTime.now();
    return _filteredTransactions
        .where(
          (tx) =>
              tx.type == type &&
              tx.date.month == now.month &&
              tx.date.year == now.year,
        )
        .fold(0.0, (sum, tx) => sum + tx.amount.abs());
  }

  Map<String, double> _getCategorySpending() {
    final Map<String, double> res = {};
    for (var tx in _filteredTransactions.where(
      (tx) => tx.type == TransactionType.expense,
    )) {
      final name = _getCategoryName(tx.categoryId).split('>').last.trim();
      res[name] = (res[name] ?? 0) + tx.amount.abs();
    }
    return res;
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
        label: 'Projets',
        onTap: () => _openMobilePage(
          const CategoryOverviewPage(type: WalletType.project, title: 'Projets'),
        ),
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

  void _showWalletDialog({Wallet? wallet}) {
    final theme = Theme.of(context);
    final nameController = TextEditingController(text: wallet?.name ?? '');
    final initialBalanceController = TextEditingController(
      text: wallet != null ? wallet.initialBalance.toStringAsFixed(2) : '0.00',
    );
    WalletType selectedType = wallet?.type ?? WalletType.current;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: theme.colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppStyles.kDefaultRadius),
              ),
              title: Text(
                wallet == null ? 'Nouveau Wallet' : 'Modifier Wallet',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameController,
                      style: TextStyle(color: theme.colorScheme.onSurface),
                      decoration: InputDecoration(
                        labelText: 'Nom du Wallet',
                        prefixIcon: const Icon(Icons.edit_note),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      autofocus: wallet == null,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: initialBalanceController,
                      style: TextStyle(color: theme.colorScheme.onSurface),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Solde initial',
                        prefixIcon: const Icon(Icons.account_balance),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<WalletType>(
                      initialValue: selectedType,
                      items: WalletType.values
                          .where(
                            (t) =>
                                t != WalletType.debt && t != WalletType.project,
                          )
                          .map((type) {
                            IconData icon;
                            String label;
                            switch (type) {
                              case WalletType.current:
                                icon = Icons.account_balance_wallet;
                                label = 'Courant';
                                break;
                              case WalletType.savings:
                                icon = Icons.savings;
                                label = 'Épargne';
                                break;
                              case WalletType.cash:
                                icon = Icons.payments;
                                label = 'Cash';
                                break;
                              case WalletType.bank:
                                icon = Icons.account_balance;
                                label = 'Banque';
                                break;
                              case WalletType.mobileMoney:
                                icon = Icons.phone_android;
                                label = 'Mobile Money';
                                break;
                              case WalletType.debt:
                                icon = Icons.money_off;
                                label = 'Dette';
                                break;
                              case WalletType.project:
                                icon = Icons.flag;
                                label = 'Projet';
                                break;
                            }
                            return DropdownMenuItem(
                              value: type,
                              child: Row(
                                children: [
                                  Icon(
                                    icon,
                                    size: 20,
                                    color: theme.colorScheme.primary,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    label,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          })
                          .toList(),
                      onChanged: (val) =>
                          setDialogState(() => selectedType = val!),
                      decoration: InputDecoration(
                        labelText: 'Type de Wallet',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      dropdownColor: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ],
                ),
              ),
              actions: [
                if (wallet != null)
                  TextButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Supprimer ?'),
                          content: const Text(
                            'Toutes les transactions liées seront perdues.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Annuler'),
                            ),
                            TextButton(
                              onPressed: () async {
                                final txRepo = ref.read(transactionRepositoryProvider);
                                final txsToRemove = _transactions.where(
                                  (tx) =>
                                      tx.walletId == wallet.id ||
                                      tx.fromWalletId == wallet.id ||
                                      tx.toWalletId == wallet.id,
                                ).toList();
                                for (var tx in txsToRemove) {
                                  await txRepo.deleteTransaction(tx.id);
                                }
                                await ref.read(walletRepositoryProvider).deleteWallet(wallet.id);
                                setState(() {
                                  _selectedWalletIds.remove(wallet.id);
                                });
                                if (!mounted || !ctx.mounted) return;
                                Navigator.pop(ctx);
                                Navigator.pop(context);
                              },
                              child: const Text(
                                'Supprimer',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    child: const Text(
                      'Supprimer',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Annuler'),
                ),
                FilledButton(
                  onPressed: () async {
                    if (nameController.text.trim().isNotEmpty) {
                      final initialBalance =
                          double.tryParse(
                            initialBalanceController.text.replaceAll(',', '.'),
                          ) ??
                          0.0;
                      if (wallet == null) {
                        final newWallet = Wallet(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          name: nameController.text.trim(),
                          initialBalance: initialBalance,
                          type: selectedType,
                        );
                        await ref.read(walletRepositoryProvider).insertWallet(newWallet);
                      } else {
                        wallet.name = nameController.text.trim();
                        wallet.initialBalance = initialBalance;
                        wallet.type = selectedType;
                        await ref.read(walletRepositoryProvider).updateWallet(wallet);
                      }
                      if (context.mounted) Navigator.pop(context);
                    }
                  },
                  child: const Text('Enregistrer'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final walletsAsync = ref.watch(walletsProvider);
    final txsAsync = ref.watch(transactionsProvider);
    final catsAsync = ref.watch(categoriesProvider);

    if (walletsAsync.isLoading || txsAsync.isLoading || catsAsync.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    _wallets = walletsAsync.value ?? [];
    _transactions = txsAsync.value ?? [];
    _categories = catsAsync.value ?? [];

    final theme = Theme.of(context);
    final income = _getMonthlyTotal(TransactionType.income);
    final expenses = _getMonthlyTotal(TransactionType.expense);
    final categorySpending = _getCategorySpending();
    final historicalBalances = _balanceService.computeHistoricalBalances(
      _wallets,
      _transactions,
      _selectedWalletIds,
      7,
    );

    final rawFiltered = _filteredTransactions;
    rawFiltered.sort((a, b) => b.date.compareTo(a.date));
    final filteredTxs = rawFiltered;

    final dashboardItems = _dashboardConfig.order
        .where((type) => _dashboardConfig.visible.contains(type))
        .toList();

    Widget mainContent = SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 16),
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: dashboardItems.length,
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (newIndex > oldIndex) newIndex -= 1;
                final item = dashboardItems.removeAt(oldIndex);
                dashboardItems.insert(newIndex, item);

                // Update persistent order
                final currentOrder = List<DashboardWidgetType>.from(
                  _dashboardConfig.order,
                );
                final globalOldIdx = currentOrder.indexOf(item);
                currentOrder.removeAt(globalOldIdx);
                // Position relative to other visible items
                int globalNewIdx = 0;
                if (newIndex > 0) {
                  final prevWidget = dashboardItems[newIndex - 1];
                  globalNewIdx = currentOrder.indexOf(prevWidget) + 1;
                }
                currentOrder.insert(globalNewIdx, item);

                // Ensure balance (Overview) is ALWAYS index 0
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
            buildDefaultDragHandles: _isEditMode,
            proxyDecorator: (child, index, animation) =>
                Material(color: Colors.transparent, child: child),
            itemBuilder: (context, index) {
              final type = dashboardItems[index];
              Widget mod;
              switch (type) {
                case DashboardWidgetType.balance:
                  mod = BalanceSummaryCard(
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
                    onEditWallet: (w) => _showWalletDialog(wallet: w),
                    getWalletBalance: _getWalletBalance,
                  );
                  break;
                case DashboardWidgetType.flow:
                  mod = FlowCard(income: income, expenses: expenses);
                  break;
                case DashboardWidgetType.categories:
                  mod = CategoryChartCard(
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
                    },
                  );
                  break;
                case DashboardWidgetType.recent:
                  mod = RecentTransactionsCard(
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
                  );
                  break;
                case DashboardWidgetType.trends:
                  mod = WealthTrendCard(history: historicalBalances);
                  break;
              }

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
                          onPressed: () {
                            setState(() {
                              _dashboardConfig.visible.remove(type);
                              _saveDashboardConfig();
                            });
                          },
                        ),
                      ),
                  ],
                ),
              );
            },
          ),

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
      onProjetTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CategoryOverviewPage(type: WalletType.project, title: 'Projets'))),
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
        floatingActionButton: FloatingActionButton.extended(
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
