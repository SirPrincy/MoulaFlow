import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models.dart';
import 'widgets.dart'; // This is now an export file
import 'responsive_layout.dart';
import 'domain/balance_service.dart';
import 'providers.dart';
import 'domain/balance_service.dart';
import 'widgets/dashboard_cards.dart';
import 'utils/styles.dart';

class TransactionsPage extends ConsumerStatefulWidget {
  const TransactionsPage({super.key});

  @override
  ConsumerState<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends ConsumerState<TransactionsPage> {
  List<Transaction> _transactions = [];
  List<Wallet> _wallets = [];
  List<TransactionCategory> _categories = [];
  String _searchQuery = '';

  final _balanceService = BalanceService();
  final Set<String> _selectedWalletIds = {};

  double get _totalBalance => _balanceService.computeTotalBalance(
    _wallets,
    _transactions,
    _selectedWalletIds,
  );
  double _getWalletBalance(String walletId) =>
      _balanceService.computeWalletBalance(walletId, _wallets, _transactions);

  List<Transaction> get _filteredTransactions {
    final filtered = _balanceService.filterTransactionsByWalletSelection(
      _transactions,
      _selectedWalletIds,
    );
    final sorted = List<Transaction>.from(filtered);
    sorted.sort((a, b) => b.date.compareTo(a.date));

    if (_searchQuery.isEmpty) return sorted;

    final q = _searchQuery.toLowerCase();
    return sorted.where((tx) {
      return tx.description.toLowerCase().contains(q) ||
          tx.tags.any((t) => t.toLowerCase().contains(q));
    }).toList();
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
        final action = result['action'];
        final tx = result['tx'];

        if (action == 'save') {
          if (editingTx != null) {
            await ref.read(transactionRepositoryProvider).updateTransaction(tx);
          } else {
            await ref.read(transactionRepositoryProvider).insertTransaction(tx);
          }
        } else if (action == 'delete') {
          await ref.read(transactionRepositoryProvider).deleteTransaction(tx.id);
        }
      }
    });
  }

  void _showWalletDialog({Wallet? wallet}) {
    final theme = Theme.of(context);
    final nameController = TextEditingController(text: wallet?.name ?? '');
    final initialBalanceController = TextEditingController(
      text: wallet != null ? wallet.initialBalance.toStringAsFixed(2) : '0.00',
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: theme.colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppStyles.kDefaultRadius),
          ),
          title: Text(
            wallet == null ? 'Nouveau Wallet' : 'Modifier Wallet',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: TextStyle(color: theme.colorScheme.onSurface),
                decoration: InputDecoration(
                  labelText: 'Nom du Wallet',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      AppStyles.kDefaultRadius,
                    ),
                  ),
                ),
                autofocus: true,
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
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            if (wallet != null)
              TextButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: theme.colorScheme.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      title: Text(
                        'Supprimer ce Wallet ?',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      content: Text(
                        'Toutes les transactions et transferts liés seront définitivement supprimés.',
                        style: TextStyle(color: theme.colorScheme.onSurface),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: Text(
                            'Annuler',
                            style: TextStyle(
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            final txRepo = ref.read(transactionRepositoryProvider);
                            final txsToRemove = _transactions.where(
                              (tx) => tx.walletId == wallet.id || tx.fromWalletId == wallet.id || tx.toWalletId == wallet.id
                            ).toList();
                            for (var tx in txsToRemove) {
                              await txRepo.deleteTransaction(tx.id);
                            }
                            await ref.read(walletRepositoryProvider).deleteWallet(wallet.id);
                            
                            setState(() {
                              _selectedWalletIds.remove(wallet.id);
                            });
                            
                            if (mounted) {
                              Navigator.pop(ctx);
                              Navigator.pop(context);
                            }
                          },
                          child: const Text(
                            'Supprimer',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
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
                    );
                    await ref.read(walletRepositoryProvider).insertWallet(newWallet);
                  } else {
                    wallet.name = nameController.text.trim();
                    wallet.initialBalance = initialBalance;
                    await ref.read(walletRepositoryProvider).updateWallet(wallet);
                  }
                  if (mounted) Navigator.pop(context);
                }
              },
              child: Text(
                'Valider',
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
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
    final displayedTxs = _filteredTransactions;

    return Scaffold(
      appBar: AppMenuBar(
        title: 'Transactions',
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Rechercher une opération...',
                prefixIcon: const Icon(Icons.search, size: 20),
                filled: true,
                fillColor: theme.colorScheme.onSurface.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppStyles.kDefaultRadius),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
        ),
      ),
      body: ResponsiveCenter(
        maxWidth: 800,
        child: Column(
          children: [
            WalletFilterBar(
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
            Expanded(
              child: displayedTxs.isEmpty
                  ? Center(
                      child: Text(
                        _searchQuery.isEmpty
                            ? 'Aucune transaction.'
                            : 'Aucun résultat.',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.4,
                          ),
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: displayedTxs.length,
                      itemBuilder: (context, index) {
                        final tx = displayedTxs[index];
                        final walletCaption =
                            tx.type == TransactionType.transfer
                            ? '${_getWalletName(tx.fromWalletId)} → ${_getWalletName(tx.toWalletId)}'
                            : _getWalletName(tx.walletId);

                        return TransactionTile(
                          tx: tx,
                          categoryName: _getCategoryName(tx.categoryId),
                          walletCaption: walletCaption,
                          isDetailed: true,
                          onTap: () => _showTransactionModal(editingTx: tx),
                          onDismissed: () async {
                            await ref.read(transactionRepositoryProvider).deleteTransaction(tx.id);
                          },
                          confirmDismiss: (_) => showDeleteConfirmDialog(
                            context,
                            'Voulez-vous supprimer cette transaction ?',
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTransactionModal(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
