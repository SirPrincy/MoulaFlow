import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models.dart';
import '../widgets.dart';
import '../domain/balance_service.dart';
import '../providers.dart';
import '../utils/styles.dart';

class CategoryOverviewPage extends ConsumerStatefulWidget {
  final WalletType type;
  final String title;

  const CategoryOverviewPage({
    super.key,
    required this.type,
    required this.title,
  });

  @override
  ConsumerState<CategoryOverviewPage> createState() => _CategoryOverviewPageState();
}

class _CategoryOverviewPageState extends ConsumerState<CategoryOverviewPage>
    with SingleTickerProviderStateMixin {
  List<Transaction> _transactions = [];
  List<Wallet> _allWallets = [];
  List<Wallet> _wallets = [];
  List<TransactionCategory> _categories = [];
  late TabController _tabController;

  BalanceService get _balanceService => ref.read(balanceServiceProvider);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  double _getWalletBalance(String walletId) =>
      _balanceService.computeWalletBalance(walletId, _wallets, _transactions);

  List<Transaction> _getFilteredTransactions(List<Wallet> currentWallets) {
    if (currentWallets.isEmpty) return [];
    final walletIds = currentWallets.map((w) => w.id).toSet();
    final relevantTxs = _transactions.where((tx) {
      if (tx.relatedDebtId != null && walletIds.contains(tx.relatedDebtId)) {
        return true;
      }
      if (tx.type == TransactionType.transfer) {
        return walletIds.contains(tx.fromWalletId) ||
            walletIds.contains(tx.toWalletId);
      }
      return walletIds.contains(tx.walletId);
    }).toList();

    final sorted = List<Transaction>.from(relevantTxs);
    sorted.sort((a, b) => b.date.compareTo(a.date));
    return sorted;
  }

  String _getWalletName(String? id) {
    if (id == null) return 'Inconnu';
    try {
      return _allWallets.firstWhere((w) => w.id == id).name;
    } catch (_) {
      return 'Inconnu';
    }
  }

  (String, String?) _getCategoryNames(String? id) {
    return TransactionCategory.getNamesFromId(id, _categories);
  }

  double _getDebtTargetAmount(Wallet debtWallet) {
    var target = debtWallet.targetAmount ?? 0;
    if (debtWallet.interestRate != null && debtWallet.interestRate! > 0) {
      target = target * (1 + debtWallet.interestRate! / 100);
    }
    return target;
  }

  double _getDebtRemainingAmount(Wallet debtWallet) {
    final target = _getDebtTargetAmount(debtWallet);
    if (target <= 0) return 0;
    return (target - debtWallet.initialBalance).clamp(0.0, double.infinity);
  }

  void _showTransactionModal({
    Transaction? editingTx,
    String? prefilledWalletId,
  }) {
    if (widget.type == WalletType.debt &&
        prefilledWalletId != null &&
        editingTx == null) {
      final debtWallet = _wallets
          .where((w) => w.id == prefilledWalletId)
          .toList();
      if (debtWallet.isNotEmpty) {
        _showDebtRepaymentFlow(debtWallet.first);
      }
      return;
    }

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
          wallets: _allWallets,
          categories: _categories,
          editingTx: editingTx,
          prefilledWalletId: prefilledWalletId,
        );
      },
    ).then((result) async {
      if (result != null && result is Map) {
        if (result['action'] == 'create_wallet') {
          if (!mounted) return;
          _showSpecializedWalletDialog();
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
      }
    });
  }

  Future<bool> _askTransactionConfirmation(String message, {BuildContext? contextOverride}) async {
    final answer = await showDialog<bool>(
      context: contextOverride ?? context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmation'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('non'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('oui'),
          ),
        ],
      ),
    );
    return answer ?? false;
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  void _showOperationSummary({
    required String operation,
    required String walletName,
    required double amount,
    required DateTime date,
    required String txType,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$operation • wallet: $walletName • montant: ${formatAmount(amount)} • '
          'date: ${_formatDate(date)} • type: $txType',
        ),
      ),
    );
  }

  Widget _buildStatChip(
    BuildContext context, {
    required String label,
    required String value,
    required Color color,
    required ThemeData theme,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
              color: color.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  void _showDebtCreationFlow() {
    final theme = Theme.of(context);
    final nameController = TextEditingController();
    final initialBalanceController = TextEditingController(text: '0.00');
    final targetAmountController = TextEditingController();
    final interestRateController = TextEditingController();
    final newWalletNameController = TextEditingController();
    DateTime issueDate = DateTime.now();
    DateTime? dueDate;
    bool isCredit = false;
    bool hasInterest = false;
    bool useExistingWallet = true;
    String? selectedWalletId;

    final transactionWallets = _allWallets
        .where((w) => w.type != WalletType.debt)
        .toList();
    if (transactionWallets.isNotEmpty) {
      selectedWalletId = transactionWallets.first.id;
    }

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            title: const Text('Créer une dette'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Nom de la dette'),
                    autofocus: true,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('Je dois'),
                          selected: !isCredit,
                          onSelected: (_) => setDialogState(() => isCredit = false),
                          showCheckmark: false,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('On me doit'),
                          selected: isCredit,
                          onSelected: (_) => setDialogState(() => isCredit = true),
                          showCheckmark: false,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: initialBalanceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: isCredit ? 'Déjà remboursé' : 'Déjà payé',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: targetAmountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: isCredit ? 'Montant prêté' : 'Montant total emprunté',
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Date d\'émission: ${_formatDate(issueDate)}'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: issueDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2101),
                      );
                      if (picked != null) {
                        setDialogState(() => issueDate = picked);
                      }
                    },
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      dueDate == null
                          ? 'Date d\'échéance (optionnel)'
                          : 'Échéance: ${_formatDate(dueDate!)}',
                    ),
                    trailing: const Icon(Icons.event),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: dueDate ?? issueDate,
                        firstDate: issueDate,
                        lastDate: DateTime(2101),
                      );
                      if (picked != null) {
                        setDialogState(() => dueDate = picked);
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    title: const Text(
                      'Inclure des intérêts',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    value: hasInterest,
                    onChanged: (val) => setDialogState(() => hasInterest = val),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                  if (hasInterest)
                    TextField(
                      controller: interestRateController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Taux d\'intérêt annuel (%)',
                        prefixIcon: Icon(Icons.percent),
                      ),
                    ),
                  const Divider(height: 24),
                  Text(
                    'Wallet de transaction (choix explicite)',
                    style: theme.textTheme.bodyMedium,
                  ),
                  Column(
                    children: [
                      RadioListTile<bool>(
                        title: const Text('Sélectionner un wallet existant'),
                        value: true,
                        groupValue: useExistingWallet,
                        onChanged: (val) => setDialogState(() => useExistingWallet = val ?? true),
                      ),
                      if (useExistingWallet)
                        DropdownButtonFormField<String>(
                          initialValue: selectedWalletId,
                          items: transactionWallets
                              .map(
                                (w) => DropdownMenuItem(
                                  value: w.id,
                                  child: Text(w.name),
                                ),
                              )
                              .toList(),
                          onChanged: (val) => setDialogState(() => selectedWalletId = val),
                        ),
                      RadioListTile<bool>(
                        title: const Text('Créer un nouveau wallet'),
                        value: false,
                        groupValue: useExistingWallet,
                        onChanged: (val) => setDialogState(() => useExistingWallet = val ?? true),
                      ),
                      if (!useExistingWallet)
                        TextField(
                          controller: newWalletNameController,
                          decoration: const InputDecoration(
                            labelText: 'Nom du nouveau wallet',
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Annuler'),
              ),
              FilledButton(
                onPressed: () async {
                  try {
                    final targetAmount = double.tryParse(
                      targetAmountController.text.replaceAll(',', '.').replaceAll(' ', ''),
                    );
                    final initialBalance = double.tryParse(
                          initialBalanceController.text.replaceAll(',', '.').replaceAll(' ', ''),
                        ) ??
                        0.0;
                    final interestRate = double.tryParse(
                      interestRateController.text.replaceAll(',', '.').replaceAll(' ', ''),
                    );

                    if (nameController.text.trim().isEmpty) {
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Veuillez entrer un nom')));
                      }
                      return;
                    }
                    if (targetAmount == null || targetAmount <= 0) {
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Veuillez entrer un montant valide')));
                      }
                      return;
                    }
                    if (initialBalance < 0 || initialBalance > targetAmount) {
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Le montant déjà traité est invalide')));
                      }
                      return;
                    }
                    if (hasInterest && (interestRate == null || interestRate <= 0)) {
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Veuillez entrer un taux valide')));
                      }
                      return;
                    }

                    late final Wallet transactionWallet;
                    if (useExistingWallet) {
                      if (selectedWalletId == null) return;
                      transactionWallet = transactionWallets.firstWhere(
                        (w) => w.id == selectedWalletId,
                      );
                    } else {
                      if (newWalletNameController.text.trim().isEmpty) return;
                      transactionWallet = Wallet(
                        id: DateTime.now().microsecondsSinceEpoch.toString(),
                        name: newWalletNameController.text.trim(),
                        type: WalletType.current,
                      );
                      await ref.read(walletRepositoryProvider).insertWallet(transactionWallet);
                    }

                    final debtWallet = Wallet(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      name: nameController.text.trim(),
                      type: WalletType.debt,
                      initialBalance: initialBalance,
                      targetAmount: targetAmount,
                      dueDate: dueDate,
                      isCredit: isCredit,
                      createdAt: issueDate,
                      interestRate: hasInterest ? interestRate : null,
                    );

                    await ref.read(walletRepositoryProvider).insertWallet(debtWallet);

                    final shouldCreateTx = await _askTransactionConfirmation(
                      'Voulez-vous enregistrer la transaction associée à cette dette ? (oui/non)',
                      // ignore: use_build_context_synchronously
                      contextOverride: ctx,
                    );
                    if (shouldCreateTx) {
                      final txType = isCredit
                          ? TransactionType.expense
                          : TransactionType.income;
                      final tx = Transaction(
                        id: DateTime.now().microsecondsSinceEpoch.toString(),
                        amount: targetAmount,
                        description: isCredit
                            ? 'Création dette (prêt) : ${debtWallet.name}'
                            : 'Création dette (emprunt) : ${debtWallet.name}',
                        type: txType,
                        date: issueDate,
                        walletId: transactionWallet.id,
                        relatedDebtId: debtWallet.id,
                        categoryId: isCredit ? 'cat_dettes_loan_out' : 'cat_dettes_loan_in',
                      );
                      await ref.read(transactionRepositoryProvider).insertTransaction(tx);
                      if (mounted && ctx.mounted) {
                        _showOperationSummary(
                          operation: 'Création de dette',
                          walletName: transactionWallet.name,
                          amount: txType == TransactionType.expense ? -targetAmount : targetAmount,
                          date: issueDate,
                          txType: txType.name,
                        );
                      }
                    } else {
                      if (mounted && ctx.mounted) {
                        _showOperationSummary(
                          operation: 'Création de dette (sans transaction)',
                          walletName: transactionWallet.name,
                          amount: isCredit ? -targetAmount : targetAmount,
                          date: issueDate,
                          txType: 'aucune',
                        );
                      }
                    }

                    if (mounted && ctx.mounted) Navigator.pop(ctx);
                  } catch (e) {
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(content: Text('Erreur lors de la création: $e')),
                      );
                    }
                  }
                },
                child: const Text('Créer'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDebtRepaymentFlow(Wallet debtWallet) {
    final amountController = TextEditingController();
    final interestAmountController = TextEditingController();
    bool includeInterest = false;
    bool useExistingWallet = true;
    String? selectedWalletId;
    final newWalletNameController = TextEditingController();
    final transactionWallets = _allWallets
        .where((w) => w.type != WalletType.debt)
        .toList();
    if (transactionWallets.isNotEmpty) {
      selectedWalletId = transactionWallets.first.id;
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final remainingAmount = _getDebtRemainingAmount(debtWallet);
          final hasTarget = _getDebtTargetAmount(debtWallet) > 0;

          return AlertDialog(
            title: Text('Remboursement - ${debtWallet.name}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(ctx).colorScheme.primary.withValues(
                      alpha: 0.08,
                    ),
                    borderRadius: BorderRadius.circular(
                      AppStyles.kDefaultRadius,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dette sélectionnée: ${debtWallet.name}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        hasTarget
                            ? 'Montant restant: ${formatAmount(remainingAmount)}'
                            : 'Montant restant: non défini',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Montant remboursé',
                  ),
                ),
                if (debtWallet.interestRate != null && debtWallet.interestRate! > 0) ...[
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    value: includeInterest,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Inclure une part d\'intérêt'),
                    subtitle: Text('Taux configuré: ${debtWallet.interestRate}%'),
                    onChanged: (val) => setDialogState(() => includeInterest = val ?? false),
                  ),
                  if (includeInterest)
                    TextField(
                      controller: interestAmountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Part des intérêts incluse',
                      ),
                    ),
                ],
                const SizedBox(height: 8),
                Column(
                  children: [
                    RadioListTile<bool>(
                      title: const Text('Sélectionner un wallet existant'),
                      value: true,
                      groupValue: useExistingWallet,
                      onChanged: (val) =>
                          setDialogState(() => useExistingWallet = val ?? true),
                    ),
                    if (useExistingWallet)
                      DropdownButtonFormField<String>(
                        initialValue: selectedWalletId,
                        items: transactionWallets
                            .map(
                              (w) => DropdownMenuItem(
                                value: w.id,
                                child: Text(w.name),
                              ),
                            )
                            .toList(),
                        onChanged: (val) =>
                            setDialogState(() => selectedWalletId = val),
                      ),
                    RadioListTile<bool>(
                      title: const Text('Créer un nouveau wallet'),
                      value: false,
                      groupValue: useExistingWallet,
                      onChanged: (val) =>
                          setDialogState(() => useExistingWallet = val ?? true),
                    ),
                    if (!useExistingWallet)
                      TextField(
                        controller: newWalletNameController,
                        decoration: const InputDecoration(
                          labelText: 'Nom du nouveau wallet',
                        ),
                      ),
                  ],
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
                  try {
                    final amount = double.tryParse(
                      amountController.text.replaceAll(',', '.').replaceAll(' ', ''),
                    );
                    if (amount == null || amount <= 0) {
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Veuillez entrer un montant valide')));
                      }
                      return;
                    }

                    final interestAmount = includeInterest
                        ? (double.tryParse(interestAmountController.text.replaceAll(',', '.').replaceAll(' ', '')) ?? -1)
                        : 0.0;
                    if (includeInterest &&
                        (interestAmount < 0 || interestAmount >= amount)) {
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('La part des intérêts est invalide')));
                      }
                      return;
                    }
                    final principalAmount = amount - interestAmount;
                    if (hasTarget && amount > remainingAmount) {
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Le remboursement dépasse le restant (${formatAmount(remainingAmount)}).',
                            ),
                          ),
                        );
                      }
                      return;
                    }

                    late final Wallet transactionWallet;
                    if (useExistingWallet) {
                      if (selectedWalletId == null) return;
                      transactionWallet = transactionWallets.firstWhere(
                        (w) => w.id == selectedWalletId,
                      );
                    } else {
                      if (newWalletNameController.text.trim().isEmpty) return;
                      transactionWallet = Wallet(
                        id: DateTime.now().microsecondsSinceEpoch.toString(),
                        name: newWalletNameController.text.trim(),
                        type: WalletType.current,
                      );
                      await ref
                          .read(walletRepositoryProvider)
                          .insertWallet(transactionWallet);
                    }

                    final newBalance = debtWallet.initialBalance + principalAmount;
                    bool newIsSettled = debtWallet.isSettled;
                    
                    final tempWallet = debtWallet.copyWith(initialBalance: newBalance);
                    if (hasTarget && _getDebtRemainingAmount(tempWallet) <= 0.0001) {
                      newIsSettled = true;
                    }
                    
                    final updatedWallet = tempWallet.copyWith(isSettled: newIsSettled);
                    await ref.read(walletRepositoryProvider).updateWallet(updatedWallet);

                    final shouldCreateTx = await _askTransactionConfirmation(
                      'Voulez-vous enregistrer la transaction de remboursement ? (oui/non)',
                      // ignore: use_build_context_synchronously
                      contextOverride: ctx,
                    );
                    if (shouldCreateTx) {
                      final txType = debtWallet.isCredit
                          ? TransactionType.income
                          : TransactionType.expense;
                      final tx = Transaction(
                        id: DateTime.now().microsecondsSinceEpoch.toString(),
                        amount: principalAmount,
                        description: includeInterest
                            ? 'Remboursement (capital) de ${debtWallet.name}'
                            : 'Remboursement de ${debtWallet.name}',
                        type: txType,
                        date: DateTime.now(),
                        walletId: transactionWallet.id,
                        relatedDebtId: debtWallet.id,
                        categoryId: debtWallet.isCredit ? 'cat_dettes_repay_in' : 'cat_dettes_repay_out',
                      );
                      await ref.read(transactionRepositoryProvider).insertTransaction(tx);
                      if (includeInterest && interestAmount > 0) {
                        final interestTx = Transaction(
                          id: '${DateTime.now().microsecondsSinceEpoch}_interest',
                          amount: interestAmount,
                          description: 'Intérêts sur ${debtWallet.name}',
                          type: txType,
                          date: DateTime.now(),
                          walletId: transactionWallet.id,
                          relatedDebtId: debtWallet.id,
                          categoryId: 'cat_impots_interests',
                        );
                        await ref.read(transactionRepositoryProvider).insertTransaction(interestTx);
                      }
                      if (mounted && ctx.mounted) {
                        _showOperationSummary(
                          operation: 'Remboursement',
                          walletName: transactionWallet.name,
                          amount: txType == TransactionType.expense
                              ? -amount
                              : amount,
                          date: DateTime.now(),
                          txType: txType.name,
                        );
                      }
                    } else {
                      if (mounted && ctx.mounted) {
                        _showOperationSummary(
                          operation: 'Remboursement (sans transaction)',
                          walletName: transactionWallet.name,
                          amount: debtWallet.isCredit ? amount : -amount,
                          date: DateTime.now(),
                          txType: 'aucune',
                        );
                      }
                    }
                    
                    if (mounted && ctx.mounted) {
                      final updatedRemaining = _getDebtRemainingAmount(updatedWallet);
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Remboursement de ${formatAmount(amount)} enregistré. '
                            'Reste: ${formatAmount(updatedRemaining)}',
                          ),
                        ),
                      );
                    }
                    if (ctx.mounted) Navigator.pop(ctx);
                  } catch (e) {
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(content: Text('Erreur lors du remboursement: $e')),
                      );
                    }
                  }
                },
                child: const Text('Valider'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showSpecializedWalletDialog({Wallet? wallet}) {
    final theme = Theme.of(context);
    final nameController = TextEditingController(text: wallet?.name ?? '');
    final initialBalanceController = TextEditingController(
      text: wallet != null ? wallet.initialBalance.toStringAsFixed(2) : '0.00',
    );
    final targetAmountController = TextEditingController(
      text: wallet?.targetAmount?.toStringAsFixed(2) ?? '',
    );
    final interestRateController = TextEditingController(
      text: wallet?.interestRate?.toString() ?? '',
    );
    WalletType selectedType = wallet?.type ?? widget.type;
    DateTime? selectedDueDate = wallet?.dueDate;
    bool isCredit = wallet?.isCredit ?? false;
    bool hasInterest =
        wallet?.interestRate != null && wallet!.interestRate! > 0;

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
                wallet == null ? 'Nouveau Goal' : 'Modifier Goal',
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
                        labelText: 'Nom',
                        prefixIcon: const Icon(Icons.edit_note),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppStyles.kDefaultRadius,
                          ),
                        ),
                      ),
                      autofocus: wallet == null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<WalletType>(
                      initialValue: selectedType,
                      items: [selectedType].map((type) {
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
                          case WalletType.debt:
                            icon = Icons.money_off;
                            label = 'Dette';
                            break;
                          case WalletType.project:
                            icon = Icons.flag;
                            label = 'Projet';
                            break;
                          case WalletType.bank:
                            icon = Icons.account_balance;
                            label = 'Banque';
                            break;
                          case WalletType.cash:
                            icon = Icons.payments;
                            label = 'Cash';
                            break;
                          case WalletType.mobileMoney:
                            icon = Icons.phone_android;
                            label = 'Mobile Money';
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
                      }).toList(),
                      onChanged:
                          null, // Locked to the category type on this page
                      decoration: InputDecoration(
                        labelText: 'Type',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppStyles.kDefaultRadius,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      dropdownColor: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: initialBalanceController,
                      style: TextStyle(color: theme.colorScheme.onSurface),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: selectedType == WalletType.debt
                            ? (isCredit ? 'Déjà remboursé' : 'Déjà payé')
                            : 'Solde initial',
                        prefixIcon: const Icon(Icons.account_balance),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppStyles.kDefaultRadius,
                          ),
                        ),
                      ),
                    ),

                    if (selectedType == WalletType.debt) ...[
                      const SizedBox(height: 24),
                      const Text(
                        'Type de Dette',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ChoiceChip(
                              label: const Text('Je dois'),
                              selected: !isCredit,
                              onSelected: (val) =>
                                  setDialogState(() => isCredit = false),
                              selectedColor: Colors.red.withValues(alpha: 0.2),
                              labelStyle: TextStyle(
                                color: !isCredit
                                    ? Colors.red
                                    : theme.colorScheme.onSurface,
                                fontWeight: FontWeight.bold,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppStyles.kDefaultRadius,
                                ),
                              ),
                              showCheckmark: false,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ChoiceChip(
                              label: const Text('On me doit'),
                              selected: isCredit,
                              onSelected: (val) =>
                                  setDialogState(() => isCredit = true),
                              selectedColor: Colors.green.withValues(
                                alpha: 0.2,
                              ),
                              labelStyle: TextStyle(
                                color: isCredit
                                    ? Colors.green
                                    : theme.colorScheme.onSurface,
                                fontWeight: FontWeight.bold,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppStyles.kDefaultRadius,
                                ),
                              ),
                              showCheckmark: false,
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 24),
                    Text(
                      selectedType == WalletType.debt
                          ? 'Détails de la Dette'
                          : 'Détails de l\'Objectif',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: targetAmountController,
                      style: TextStyle(color: theme.colorScheme.onSurface),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: selectedType == WalletType.debt
                            ? (isCredit
                                  ? 'Montant prêté'
                                  : 'Montant total emprunté')
                            : 'Objectif d\'épargne',
                        prefixIcon: const Icon(Icons.ads_click),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppStyles.kDefaultRadius,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDueDate ?? DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setDialogState(() => selectedDueDate = picked);
                        }
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Date d\'échéance',
                          prefixIcon: const Icon(Icons.event),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              AppStyles.kDefaultRadius,
                            ),
                          ),
                        ),
                        child: Text(
                          selectedDueDate == null
                              ? 'Sélectionner...'
                              : '${selectedDueDate!.day.toString().padLeft(2, '0')}/${selectedDueDate!.month.toString().padLeft(2, '0')}/${selectedDueDate!.year}',
                          style: TextStyle(color: theme.colorScheme.onSurface),
                        ),
                      ),
                    ),

                    if (selectedType == WalletType.debt) ...[
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: const Text(
                          'Inclure des intérêts',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        value: hasInterest,
                        onChanged: (val) =>
                            setDialogState(() => hasInterest = val),
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                      if (hasInterest)
                        TextField(
                          controller: interestRateController,
                          style: TextStyle(color: theme.colorScheme.onSurface),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Taux d\'intérêt annuel (%)',
                            prefixIcon: const Icon(Icons.percent),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                    ],
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
                                  (tx) => tx.walletId == wallet.id || tx.fromWalletId == wallet.id || tx.toWalletId == wallet.id
                                ).toList();
                                for (var tx in txsToRemove) {
                                  await txRepo.deleteTransaction(tx.id);
                                }
                                await ref.read(walletRepositoryProvider).deleteWallet(wallet.id);
                                
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
                    if (nameController.text.trim().isEmpty) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez entrer un nom')));
                      }
                      return;
                    }
                    final initialBalance =
                        double.tryParse(
                          initialBalanceController.text.replaceAll(',', '.').replaceAll(' ', ''),
                        ) ??
                        0.0;
                    if (wallet == null) {
                      final newWallet = Wallet(
                        id: DateTime.now().millisecondsSinceEpoch
                            .toString(),
                        name: nameController.text.trim(),
                        initialBalance: initialBalance,
                        type: selectedType,
                        targetAmount: double.tryParse(
                          targetAmountController.text.replaceAll(',', '.').replaceAll(' ', ''),
                        ),
                        dueDate: selectedDueDate,
                        isCredit: isCredit,
                        interestRate: hasInterest
                            ? double.tryParse(
                                interestRateController.text.replaceAll(
                                  ',',
                                  '.',
                                ).replaceAll(' ', ''),
                              )
                            : null,
                      );
                      await ref.read(walletRepositoryProvider).insertWallet(newWallet);
                    } else {
                      final updatedWallet = wallet.copyWith(
                        name: nameController.text.trim(),
                        initialBalance: initialBalance,
                        type: selectedType,
                        targetAmount: double.tryParse(targetAmountController.text.replaceAll(',', '.').replaceAll(' ', '')),
                        dueDate: selectedDueDate,
                        isCredit: isCredit,
                        interestRate: hasInterest
                            ? double.tryParse(interestRateController.text.replaceAll(',', '.').replaceAll(' ', ''))
                            : null,
                      );
                      await ref.read(walletRepositoryProvider).updateWallet(updatedWallet);
                    }
                    if (context.mounted) {
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
    final walletsAsync = ref.watch(walletsProvider);
    final txsAsync = ref.watch(transactionsProvider);
    final catsAsync = ref.watch(categoriesProvider);

    if (walletsAsync.isLoading || txsAsync.isLoading || catsAsync.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    _allWallets = walletsAsync.value ?? [];
    _wallets = _allWallets.where((w) => w.type == widget.type).toList();
    _transactions = txsAsync.value ?? [];
    _categories = catsAsync.value ?? [];

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final activeWallets = _wallets.where((w) => !w.isSettled).toList();
    final settledWallets = _wallets.where((w) => w.isSettled).toList();

    final currentWallets = _tabController.index == 0
        ? activeWallets
        : settledWallets;
    final displayedTxs = _getFilteredTransactions(currentWallets);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: theme.colorScheme.primary,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.colorScheme.onSurface.withValues(
            alpha: isDark ? 0.75 : 0.5,
          ),
          tabs: [
            Tab(
              text: widget.type == WalletType.savings
                  ? 'Objectifs'
                  : 'En cours',
            ),
            Tab(
              text: widget.type == WalletType.savings ? 'Atteints' : 'Soldées',
            ),
          ],
        ),
      ),
      body: ResponsiveCenter(
        maxWidth: 800,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  ...currentWallets.map((wallet) {
                    final balance = _getWalletBalance(wallet.id);
                    final isDebt = wallet.type == WalletType.debt;
                    final hasTarget = wallet.targetAmount != null;
                    final hasInterest = isDebt &&
                        wallet.interestRate != null &&
                        wallet.interestRate! > 0;

                    double effectiveTarget = wallet.targetAmount ?? 0;
                    if (hasInterest) {
                      effectiveTarget =
                          effectiveTarget * (1 + wallet.interestRate! / 100);
                    }

                    double? progress;
                    if (hasTarget && effectiveTarget > 0) {
                      progress = (balance / effectiveTarget).clamp(0.0, 1.0);
                    }

                    String mainLabel = 'Solde';
                    String targetLabel = 'Objectif';
                    Color targetColor = Colors.green;

                    if (isDebt) {
                      mainLabel = wallet.isCredit ? 'Reçu' : 'Payé';
                      targetLabel = wallet.isCredit ? 'À percevoir' : 'À payer';
                      targetColor = wallet.isCredit ? Colors.green : Colors.red;
                    } else if (wallet.type == WalletType.savings) {
                      mainLabel = 'Déjà épargné';
                      targetLabel = 'Reste à épargner';
                      targetColor = Colors.teal;
                    }

                    final isOverdue = !wallet.isSettled &&
                        wallet.dueDate != null &&
                        wallet.dueDate!.isBefore(DateTime.now());
                    final accentColor = wallet.isSettled
                        ? Colors.green
                        : isDebt
                            ? (wallet.isCredit ? Colors.teal : Colors.redAccent)
                            : Colors.teal;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: theme.colorScheme.surface,
                        border: Border.all(
                          color: wallet.isSettled
                              ? Colors.green.withValues(alpha: 0.3)
                              : isOverdue
                                  ? Colors.redAccent.withValues(alpha: 0.3)
                                  : theme.colorScheme.onSurface.withValues(alpha: 0.08),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: accentColor.withValues(alpha: 0.08),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Column(
                          children: [
                            // Top accent bar
                            Container(
                              height: 4,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    accentColor.withValues(alpha: 0.8),
                                    accentColor.withValues(alpha: 0.3),
                                  ],
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Header row: name + actions
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Flexible(
                                                  child: Text(
                                                    wallet.name,
                                                    style: theme.textTheme.titleMedium?.copyWith(
                                                      fontWeight: FontWeight.w800,
                                                      letterSpacing: -0.5,
                                                    ),
                                                  ),
                                                ),
                                                if (hasInterest) ...[
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: theme.colorScheme.primary.withValues(alpha: 0.12),
                                                      borderRadius: BorderRadius.circular(20),
                                                    ),
                                                    child: Text(
                                                      '+${wallet.interestRate}%',
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.bold,
                                                        color: theme.colorScheme.primary,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                                if (wallet.isSettled) ...[
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: Colors.green.withValues(alpha: 0.12),
                                                      borderRadius: BorderRadius.circular(20),
                                                    ),
                                                    child: const Text(
                                                      'Soldée ✓',
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.green,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                                if (isOverdue) ...[
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: Colors.redAccent.withValues(alpha: 0.12),
                                                      borderRadius: BorderRadius.circular(20),
                                                    ),
                                                    child: const Text(
                                                      'En retard',
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.redAccent,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                            if (wallet.dueDate != null) ...[
                                              const SizedBox(height: 6),
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.event_outlined,
                                                    size: 13,
                                                    color: isOverdue ? Colors.redAccent : theme.colorScheme.onSurfaceVariant,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    'Échéance ${wallet.dueDate!.day.toString().padLeft(2, "0")}/${wallet.dueDate!.month.toString().padLeft(2, "0")}/${wallet.dueDate!.year}',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w600,
                                                      color: isOverdue ? Colors.redAccent : theme.colorScheme.onSurfaceVariant,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      // Action buttons
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if ((isDebt || wallet.type == WalletType.savings) && !wallet.isSettled)
                                            IconButton(
                                              onPressed: () => _showTransactionModal(prefilledWalletId: wallet.id),
                                              icon: Icon(
                                                isDebt
                                                    ? (wallet.isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded)
                                                    : Icons.add_circle_outline,
                                                size: 22,
                                              ),
                                              color: accentColor,
                                              tooltip: isDebt ? (wallet.isCredit ? 'Encaisser' : 'Payer') : 'Épargner',
                                            ),
                                          IconButton(
                                            icon: Icon(
                                              wallet.isSettled ? Icons.check_circle_rounded : Icons.circle_outlined,
                                              size: 22,
                                            ),
                                            color: wallet.isSettled ? Colors.green : theme.colorScheme.onSurface.withValues(alpha: 0.25),
                                            onPressed: () async {
                                              final updatedWallet = wallet.copyWith(isSettled: !wallet.isSettled);
                                              await ref.read(walletRepositoryProvider).updateWallet(updatedWallet);
                                            },
                                            tooltip: wallet.isSettled ? 'Marquer active' : 'Marquer soldée',
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.more_horiz_rounded, size: 22),
                                            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                                            onPressed: () => _showSpecializedWalletDialog(wallet: wallet),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  // Stats row
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildStatChip(
                                          context,
                                          label: mainLabel,
                                          value: formatAmount(balance),
                                          color: theme.colorScheme.onSurface,
                                          theme: theme,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      if (hasTarget)
                                        Expanded(
                                          child: _buildStatChip(
                                            context,
                                            label: targetLabel,
                                            value: formatAmount((effectiveTarget - balance).abs()),
                                            color: targetColor,
                                            theme: theme,
                                          ),
                                        ),
                                      if (!hasTarget && !isDebt)
                                        Expanded(
                                          child: _buildStatChip(
                                            context,
                                            label: 'No objectif',
                                            value: '—',
                                            color: theme.colorScheme.onSurfaceVariant,
                                            theme: theme,
                                          ),
                                        ),
                                    ],
                                  ),
                                  if (progress != null) ...[
                                    const SizedBox(height: 20),
                                    // Progress bar
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: LinearProgressIndicator(
                                        value: progress,
                                        minHeight: 10,
                                        backgroundColor: accentColor.withValues(alpha: 0.1),
                                        valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '${(progress * 100).toStringAsFixed(0)}% ${isDebt ? "remboursé" : "atteint"}',
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: accentColor,
                                          ),
                                        ),
                                        Text(
                                          'sur ${formatAmount(effectiveTarget)}',
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: theme.colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),

                  if (displayedTxs.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0, left: 4),
                      child: Text(
                        'TRANSACTIONS LIÉES',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: isDark ? 0.72 : 0.4,
                          ),
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    ...displayedTxs.map((tx) {
                      final walletCaption = tx.type == TransactionType.transfer
                          ? '${_getWalletName(tx.fromWalletId)} → ${_getWalletName(tx.toWalletId)}'
                          : _getWalletName(tx.walletId);

                      final catNames = _getCategoryNames(tx.categoryId);
                      return TransactionTile(
                        tx: tx,
                        mainCategoryName: catNames.$1,
                        subCategoryName: catNames.$2,
                        walletCaption: walletCaption,
                        onTap: () => _showTransactionModal(editingTx: tx),
                        onDismissed: () {},
                      );
                    }),
                  ] else if (currentWallets.isEmpty) ...[
                    const SizedBox(height: 100),
                    Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            size: 48,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.1,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Aucun élément ici.',
                            style: TextStyle(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.4,
                              ),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => widget.type == WalletType.debt
            ? _showDebtCreationFlow()
            : _showSpecializedWalletDialog(),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        child: const Icon(Icons.add),
      ),
    );
  }
}
