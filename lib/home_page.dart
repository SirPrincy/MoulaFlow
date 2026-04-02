import 'package:flutter/material.dart';
import 'responsive_layout.dart';
import 'models.dart';
import 'widgets/transaction_form.dart';
import 'widgets/app_drawer.dart';
import 'transactions_page.dart';
import 'utils/styles.dart';
import 'settings_page.dart';
import 'data/category_repository.dart';
import 'data/transaction_repository.dart';
import 'data/wallet_repository.dart';
import 'data/dashboard_repository.dart';
import 'domain/balance_service.dart';
import 'widgets/dashboard_cards.dart';
import 'pages/category_overview_page.dart';
import 'pages/recurring_payments_page.dart';
import 'pages/bills_to_pay_page.dart';

class HomePage extends StatefulWidget {
  final ValueNotifier<ThemeMode> themeNotifier;
  const HomePage({super.key, required this.themeNotifier});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Transaction> _transactions = [];
  List<Wallet> _wallets = [];
  List<TransactionCategory> _categories = [];
  final Set<String> _selectedWalletIds = {};
  bool _isSidebarCollapsed = false;

  final _categoryRepo = CategoryRepository();
  final _transactionRepo = TransactionRepository();
  final _walletRepo = WalletRepository();
  final _balanceService = BalanceService();
  final _dashboardRepo = DashboardRepository();

  DashboardConfig _dashboardConfig = DashboardConfig.defaultConfig();
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    _categories = await _categoryRepo.loadCategories();
    _wallets = await _walletRepo.loadWallets();
    _transactions = await _transactionRepo.loadTransactions();
    _dashboardConfig = await _dashboardRepo.loadConfig();

    final result = _transactionRepo.migrateIfNeeded(_transactions, _wallets);
    if (result.changed) {
      _transactions = result.transactions;
      _wallets = result.wallets;
      await _saveData();
    }
    setState(() {});
  }

  Future<void> _saveData() async {
    await _walletRepo.saveWallets(_wallets);
    await _transactionRepo.saveTransactions(_transactions);
    await _categoryRepo.saveCategories(_categories);
  }

  double get _totalBalance => _balanceService.computeTotalBalance(_wallets, _transactions, _selectedWalletIds);

  double _getWalletBalance(String walletId) => _balanceService.computeWalletBalance(walletId, _wallets, _transactions);

  List<Transaction> get _filteredTransactions => _balanceService.filterTransactionsByWalletSelection(_transactions, _selectedWalletIds);


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
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppStyles.kDefaultRadius)),
      ),
      builder: (context) {
        return TransactionForm(wallets: _wallets, categories: _categories, editingTx: editingTx);
      },
    ).then((result) {
      if (result != null && result is Map) {
        if (result['action'] == 'create_wallet') {
          _showWalletDialog();
          return;
        }
        final tx = result['tx'] as Transaction;
        final action = result['action'] as String;
        
        setState(() {
          if (action == 'save') {
            if (editingTx != null) {
              final index = _transactions.indexWhere((t) => t.id == tx.id);
              if (index != -1) _transactions[index] = tx;
            } else {
              _transactions.insert(0, tx);
            }
          } else if (action == 'delete') {
            _transactions.removeWhere((t) => t.id == tx.id);
          }
          
          // Auto-settle/complete logic for debts and savings
          for (var w in _wallets) {
            if (!w.isSettled && w.targetAmount != null) {
              final balance = _getWalletBalance(w.id);
              double effectiveTarget = w.targetAmount!;
              
              if (w.type == WalletType.debt && w.interestRate != null && w.interestRate! > 0) {
                effectiveTarget = effectiveTarget * (1 + w.interestRate! / 100);
              }
              
              // If balance reached or exceeded target, mark as settled/completed
              if (balance >= effectiveTarget) {
                w.isSettled = true;
              }
            }
          }
        });
        _saveData();
      }
    });
  }

  Future<void> _saveDashboardConfig() async {
    await _dashboardRepo.saveConfig(_dashboardConfig);
  }

  double _getMonthlyTotal(TransactionType type) {
    final now = DateTime.now();
    return _filteredTransactions.where((tx) => 
      tx.type == type && 
      tx.date.month == now.month && 
      tx.date.year == now.year
    ).fold(0.0, (sum, tx) => sum + tx.amount.abs());
  }

  Map<String, double> _getCategorySpending() {
    final Map<String, double> res = {};
    for (var tx in _filteredTransactions.where((tx) => tx.type == TransactionType.expense)) {
      final name = _getCategoryName(tx.categoryId).split('>').last.trim();
      res[name] = (res[name] ?? 0) + tx.amount.abs();
    }
    return res;
  }

  void _showWalletDialog({Wallet? wallet}) {
    final theme = Theme.of(context);
    final nameController = TextEditingController(text: wallet?.name ?? '');
    final initialBalanceController = TextEditingController(text: wallet != null ? wallet.initialBalance.toStringAsFixed(2) : '0.00');
    WalletType selectedType = wallet?.type ?? WalletType.current;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: theme.colorScheme.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppStyles.kDefaultRadius)),
              title: Text(
                wallet == null ? 'Nouveau Wallet' : 'Modifier Wallet',
                style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.5),
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
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      autofocus: wallet == null,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: initialBalanceController,
                      style: TextStyle(color: theme.colorScheme.onSurface),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Solde initial',
                        prefixIcon: const Icon(Icons.account_balance),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<WalletType>(
                      initialValue: selectedType,
                      items: WalletType.values.where((t) => t != WalletType.debt && t != WalletType.project).map((type) {
                        IconData icon;
                        String label;
                        switch (type) {
                          case WalletType.current: icon = Icons.account_balance_wallet; label = 'Courant'; break;
                          case WalletType.savings: icon = Icons.savings; label = 'Épargne'; break;
                          case WalletType.cash: icon = Icons.payments; label = 'Cash'; break;
                          case WalletType.bank: icon = Icons.account_balance; label = 'Banque'; break;
                          case WalletType.mobileMoney: icon = Icons.phone_android; label = 'Mobile Money'; break;
                          case WalletType.debt: icon = Icons.money_off; label = 'Dette'; break;
                          case WalletType.project: icon = Icons.flag; label = 'Projet'; break;
                        }
                        return DropdownMenuItem(
                          value: type,
                          child: Row(
                            children: [
                              Icon(icon, size: 20, color: theme.colorScheme.primary),
                              const SizedBox(width: 12),
                              Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (val) => setDialogState(() => selectedType = val!),
                      decoration: InputDecoration(
                        labelText: 'Type de Wallet',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                          content: const Text('Toutes les transactions liées seront perdues.'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _transactions.removeWhere((tx) =>
                                      tx.walletId == wallet.id ||
                                      tx.fromWalletId == wallet.id ||
                                      tx.toWalletId == wallet.id);
                                  _wallets.remove(wallet);
                                  _selectedWalletIds.remove(wallet.id);
                                });
                                _saveData();
                                Navigator.pop(ctx);
                                Navigator.pop(context);
                              },
                              child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );
                    },
                    child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
                  ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Annuler'),
                ),
                FilledButton(
                  onPressed: () {
                    if (nameController.text.trim().isNotEmpty) {
                      final initialBalance = double.tryParse(initialBalanceController.text.replaceAll(',', '.')) ?? 0.0;
                      setState(() {
                        if (wallet == null) {
                          _wallets.add(Wallet(
                            id: DateTime.now().millisecondsSinceEpoch.toString(),
                            name: nameController.text.trim(),
                            initialBalance: initialBalance,
                            type: selectedType,
                          ));
                        } else {
                          wallet.name = nameController.text.trim();
                          wallet.initialBalance = initialBalance;
                          wallet.type = selectedType;
                        }
                      });
                      _saveData();
                      Navigator.pop(context);
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
    final theme = Theme.of(context);
    final income = _getMonthlyTotal(TransactionType.income);
    final expenses = _getMonthlyTotal(TransactionType.expense);
    final categorySpending = _getCategorySpending();
    final historicalBalances = _balanceService.computeHistoricalBalances(_wallets, _transactions, _selectedWalletIds, 7);

    final rawFiltered = _filteredTransactions;
    rawFiltered.sort((a, b) => b.date.compareTo(a.date));
    final filteredTxs = rawFiltered;

    final dashboardItems = _dashboardConfig.order.where((type) => _dashboardConfig.visible.contains(type)).toList();

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
                final currentOrder = List<DashboardWidgetType>.from(_dashboardConfig.order);
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
            proxyDecorator: (child, index, animation) => Material(
              color: Colors.transparent,
              child: child,
            ),
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
                      if (id == null) { _selectedWalletIds.clear(); }
                      else if (_selectedWalletIds.contains(id)) { _selectedWalletIds.remove(id); }
                      else { _selectedWalletIds.add(id); }
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
                    getWalletCaption: (tx) => tx.type == TransactionType.transfer
                        ? '${_getWalletName(tx.fromWalletId)} → ${_getWalletName(tx.toWalletId)}'
                        : _getWalletName(tx.walletId), 
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const TransactionsPage()),
                      );
                      _loadData();
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
                          icon: const Icon(Icons.remove_circle, color: Colors.red),
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
                      children: DashboardWidgetType.values.where((t) => !_dashboardConfig.visible.contains(t)).map((t) => ListTile(
                        title: Text(t.name),
                        trailing: const Icon(Icons.add_circle, color: Colors.green),
                        onTap: () {
                          setState(() {
                            _dashboardConfig.visible.add(t);
                            _saveDashboardConfig();
                          });
                          Navigator.pop(context);
                        },
                      )).toList(),
                    ),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Ajouter un module'),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppStyles.kDefaultRadius)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),

          const SizedBox(height: 100),
        ],
      )
    );

    final drawerContent = AppDrawerContent(
      currentRoute: '/',
      isCollapsed: _isSidebarCollapsed,
      onHomeTap: () {
        if (context.isMobileScreen) Navigator.pop(context);
      },
      onTransactionsTap: () async {
        if (context.isMobileScreen) Navigator.pop(context);
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const TransactionsPage()),
        );
        _loadData();
      },
      onSettingsTap: () async {
        if (context.isMobileScreen) Navigator.pop(context);
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => SettingsPage(themeNotifier: widget.themeNotifier)),
        );
        _loadData();
      },
      onAPayerTap: () async {
        if (context.isMobileScreen) Navigator.pop(context);
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const BillsToPayPage()),
        );
        _loadData();
      },
      onDettesTap: () async {
        if (context.isMobileScreen) Navigator.pop(context);
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CategoryOverviewPage(type: WalletType.debt, title: 'Dettes')),
        );
        _loadData();
      },
      onEpargneTap: () async {
        if (context.isMobileScreen) Navigator.pop(context);
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CategoryOverviewPage(type: WalletType.savings, title: 'Épargne')),
        );
        _loadData();
      },
      onProjetTap: () async {
        if (context.isMobileScreen) Navigator.pop(context);
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CategoryOverviewPage(type: WalletType.project, title: 'Projets')),
        );
        _loadData();
      },
      onRecurringTap: () async {
        if (context.isMobileScreen) Navigator.pop(context);
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const RecurringPaymentsPage()),
        );
        _loadData();
      },
    );

    if (context.isMobileScreen) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Moula Flow',
            style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.5),
          ),
          actions: [
            if (!_isEditMode)
              TextButton.icon(
                onPressed: () => setState(() => _isEditMode = true),
                icon: const Icon(Icons.edit, size: 18),
                label: const Text('Modifier'),
                style: TextButton.styleFrom(foregroundColor: theme.colorScheme.onSurface),
              )
            else
              IconButton(
                icon: Icon(Icons.check_circle, color: theme.colorScheme.primary, size: 28),
                onPressed: () => setState(() => _isEditMode = false),
              ),
          ],
        ),
        drawer: Drawer(child: drawerContent),
        body: mainContent,
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _wallets.isEmpty
              ? () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Créez un wallet d\'abord.')))
              : () => _showTransactionModal(),
          elevation: 0,
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
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
            child: drawerContent,
          ),
          Expanded(
            child: Scaffold(
              appBar: AppBar(
                leading: IconButton(
                  icon: Icon(_isSidebarCollapsed ? Icons.menu_open : Icons.menu),
                  onPressed: () => setState(() => _isSidebarCollapsed = !_isSidebarCollapsed),
                ),
                title: const Text(
                  'Moula Flow',
                  style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.5),
                ),
                actions: [
                  if (!_isEditMode)
                    TextButton.icon(
                      onPressed: () => setState(() => _isEditMode = true),
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Modifier'),
                      style: TextButton.styleFrom(foregroundColor: theme.colorScheme.onSurface),
                    )
                  else
                    IconButton(
                      icon: Icon(Icons.check_circle, color: theme.colorScheme.primary, size: 28),
                      onPressed: () => setState(() => _isEditMode = false),
                    ),
                ],
              ),
              body: ResponsiveCenter(
                maxWidth: 1000,
                child: mainContent,
              ),
              floatingActionButton: FloatingActionButton.extended(
                onPressed: _wallets.isEmpty
                    ? () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Créez un wallet d\'abord.')))
                    : () => _showTransactionModal(),
                elevation: 0,
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
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
