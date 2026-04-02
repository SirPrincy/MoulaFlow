import 'package:flutter/material.dart';
import '../models.dart';
import '../widgets.dart';
import '../responsive_layout.dart';
import '../data/transaction_repository.dart';
import '../data/wallet_repository.dart';
import '../data/category_repository.dart';

class RecurringPaymentsPage extends StatefulWidget {
  const RecurringPaymentsPage({super.key});

  @override
  State<RecurringPaymentsPage> createState() => _RecurringPaymentsPageState();
}

class _RecurringPaymentsPageState extends State<RecurringPaymentsPage> {
  List<Transaction> _transactions = [];
  List<Wallet> _wallets = [];
  List<TransactionCategory> _categories = [];
  
  final _transactionRepo = TransactionRepository();
  final _walletRepo = WalletRepository();
  final _categoryRepo = CategoryRepository();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    _categories = await _categoryRepo.loadCategories();
    _wallets = await _walletRepo.loadWallets();
    _transactions = await _transactionRepo.loadTransactions();
    setState(() {});
  }

  List<Transaction> get _recurringTransactionsHistory {
    final recurring = _transactions.where((tx) => tx.isRecurring).toList();
    recurring.sort((a, b) => b.date.compareTo(a.date));
    return recurring;
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayedTxs = _recurringTransactionsHistory;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paiements Récurrents', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: ResponsiveCenter(
        maxWidth: 800,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(Icons.history, size: 48, color: theme.colorScheme.primary),
                  const SizedBox(height: 16),
                  const Text(
                    'Historique des opérations récurrentes.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: displayedTxs.isEmpty
                ? Center(
                    child: Text(
                      'Aucun historique récurrent.',
                      style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: displayedTxs.length,
                    itemBuilder: (context, index) {
                      final tx = displayedTxs[index];
                      final walletCaption = tx.type == TransactionType.transfer
                          ? '${_getWalletName(tx.fromWalletId)} → ${_getWalletName(tx.toWalletId)}'
                          : _getWalletName(tx.walletId);

                      return TransactionTile(
                        tx: tx,
                        categoryName: _getCategoryName(tx.categoryId),
                        walletCaption: walletCaption,
                        isDetailed: true,
                        onTap: () {}, // History is read-only here
                        onDismissed: () {},
                      );
                    },
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
