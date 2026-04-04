import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models.dart';
import '../responsive_layout.dart';
import '../providers.dart';
import '../widgets/recurring_payment_form.dart';
import '../utils/styles.dart';

class BillsToPayPage extends ConsumerStatefulWidget {
  const BillsToPayPage({super.key});

  @override
  ConsumerState<BillsToPayPage> createState() => _BillsToPayPageState();
}

class _BillsToPayPageState extends ConsumerState<BillsToPayPage> {
  List<Transaction> _transactions = [];
  List<Wallet> _wallets = [];
  List<TransactionCategory> _categories = [];
  List<RecurringPayment> _plannedPayments = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final categoryRepo = ref.read(categoryRepositoryProvider);
    final walletRepo = ref.read(walletRepositoryProvider);
    final transactionRepo = ref.read(transactionRepositoryProvider);
    final recurringRepo = ref.read(recurringPaymentRepositoryProvider);

    _categories = await categoryRepo.loadCategories();
    _wallets = await walletRepo.loadWallets();
    _transactions = await transactionRepo.loadTransactions();
    _plannedPayments = await recurringRepo.loadRecurringPayments();
    if (mounted) setState(() {});
  }

  Future<void> _savePlanned() async {
    await ref.read(recurringPaymentRepositoryProvider).saveRecurringPayments(_plannedPayments);
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

  void _showAddPlannedModal({RecurringPayment? editing}) {
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
        return RecurringPaymentForm(
          wallets: _wallets,
          categories: _categories,
          editingPayment: editing,
        );
      },
    ).then((result) {
      if (result != null && result is RecurringPayment) {
        setState(() {
          if (editing != null) {
            final idx = _plannedPayments.indexWhere((p) => p.id == result.id);
            if (idx != -1) _plannedPayments[idx] = result;
          } else {
            _plannedPayments.add(result);
          }
        });
        _savePlanned();
      }
    });
  }

  void _validatePayment(RecurringPayment p) {
    // 1. Create the Transaction
    final newTx = Transaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      amount: p.amount,
      description: p.name,
      type: p.type,
      date: DateTime.now(),
      walletId: p.walletId,
      categoryId: p.categoryId,
      isRecurring: p.frequency != RecurrenceFrequency.once,
    );

    setState(() {
      _transactions.insert(0, newTx);

      // 2. Handle nextDueDate or deactivate
      if (p.frequency == RecurrenceFrequency.once) {
        p.isActive = false;
      } else {
        switch (p.frequency) {
          case RecurrenceFrequency.daily:
            p.nextDueDate = p.nextDueDate.add(const Duration(days: 1));
            break;
          case RecurrenceFrequency.weekly:
            p.nextDueDate = p.nextDueDate.add(const Duration(days: 7));
            break;
          case RecurrenceFrequency.monthly:
            p.nextDueDate = DateTime(
              p.nextDueDate.year,
              p.nextDueDate.month + 1,
              p.nextDueDate.day,
            );
            break;
          case RecurrenceFrequency.yearly:
            p.nextDueDate = DateTime(
              p.nextDueDate.year + 1,
              p.nextDueDate.month,
              p.nextDueDate.day,
            );
            break;
          default:
            break;
        }
      }
    });

    ref.read(transactionRepositoryProvider).saveTransactions(_transactions);
    _savePlanned();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Paiement "${p.name}" validé.'),
        action: SnackBarAction(label: 'OK', onPressed: () {}),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activePayments = _plannedPayments.where((p) => p.isActive).toList();
    activePayments.sort((a, b) => a.nextDueDate.compareTo(b.nextDueDate));

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'À payer',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: ResponsiveCenter(
        maxWidth: 800,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    Icons.receipt_outlined,
                    size: 48,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Gérez vos factures et dépenses planifiées.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: activePayments.isEmpty
                  ? Center(
                      child: Text(
                        'Rien à payer pour le moment.',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.4,
                          ),
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: activePayments.length,
                      itemBuilder: (context, index) {
                        final p = activePayments[index];
                        final nextDateStr =
                            '${p.nextDueDate.day}/${p.nextDueDate.month}/${p.nextDueDate.year}';

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppStyles.kDefaultRadius,
                            ),
                            side: BorderSide(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.08,
                              ),
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            title: Row(
                              children: [
                                Text(
                                  p.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (p.frequency != RecurrenceFrequency.once)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      p.frequency.name.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  'Échéance: $nextDateStr • ${_getWalletName(p.walletId)}',
                                ),
                                Text(
                                  _getCategoryName(p.categoryId),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: theme.colorScheme.primary.withValues(
                                      alpha: 0.7,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  formatAmount(
                                    p.type == TransactionType.expense
                                        ? -p.amount
                                        : p.amount,
                                  ),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                    color: p.type == TransactionType.income
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton.filledTonal(
                                  onPressed: () => _validatePayment(p),
                                  icon: const Icon(Icons.check),
                                  tooltip: 'Valider le paiement',
                                ),
                              ],
                            ),
                            onTap: () => _showAddPlannedModal(editing: p),
                            onLongPress: () {
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Supprimer ?'),
                                  content: const Text(
                                    'Voulez-vous supprimer cette facture ?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx),
                                      child: const Text('Annuler'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        setState(() {
                                          _plannedPayments.remove(p);
                                        });
                                        _savePlanned();
                                        Navigator.pop(ctx);
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
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddPlannedModal(),
        label: const Text(
          'Planifier',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
