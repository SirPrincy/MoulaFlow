import 'package:flutter/material.dart';
import '../models.dart';
import '../widgets.dart';
import '../responsive_layout.dart';
import '../data/transaction_repository.dart';
import '../data/wallet_repository.dart';
import '../data/category_repository.dart';
import '../domain/balance_service.dart';
import '../utils/styles.dart';

class CategoryOverviewPage extends StatefulWidget {
  final WalletType type;
  final String title;

  const CategoryOverviewPage({
    super.key,
    required this.type,
    required this.title,
  });

  @override
  State<CategoryOverviewPage> createState() => _CategoryOverviewPageState();
}

class _CategoryOverviewPageState extends State<CategoryOverviewPage>
    with SingleTickerProviderStateMixin {
  List<Transaction> _transactions = [];
  List<Wallet> _allWallets = [];
  List<Wallet> _wallets = [];
  List<TransactionCategory> _categories = [];
  late TabController _tabController;

  final _transactionRepo = TransactionRepository();
  final _walletRepo = WalletRepository();
  final _categoryRepo = CategoryRepository();
  final _balanceService = BalanceService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    _categories = await _categoryRepo.loadCategories();
    _allWallets = await _walletRepo.loadWallets();
    _wallets = _allWallets.where((w) => w.type == widget.type).toList();
    _transactions = await _transactionRepo.loadTransactions();
    setState(() {});
  }

  Future<void> _saveData() async {
    await _transactionRepo.saveTransactions(_transactions);
    final walletsById = {for (final wallet in _allWallets) wallet.id: wallet};
    await _walletRepo.saveWallets(walletsById.values.toList());
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
          wallets: _wallets,
          categories: _categories,
          editingTx: editingTx,
          prefilledWalletId: prefilledWalletId,
        );
      },
    ).then((result) {
      if (result != null && result is Map) {
        if (result['action'] == 'create_wallet') {
          _showSpecializedWalletDialog();
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
        });
        _saveData();
      }
    });
  }

  Future<bool> _askTransactionConfirmation(String message) async {
    final answer = await showDialog<bool>(
      context: context,
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

  void _showDebtCreationFlow() {
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    final newWalletNameController = TextEditingController();
    DateTime issueDate = DateTime.now();
    DateTime? dueDate;
    bool isCredit = false;
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
                    decoration: const InputDecoration(
                      labelText: 'Nom de la dette',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'Montant'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('Je dois'),
                          selected: !isCredit,
                          onSelected: (_) =>
                              setDialogState(() => isCredit = false),
                          showCheckmark: false,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('On me doit'),
                          selected: isCredit,
                          onSelected: (_) =>
                              setDialogState(() => isCredit = true),
                          showCheckmark: false,
                        ),
                      ),
                    ],
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
                      if (picked != null)
                        setDialogState(() => issueDate = picked);
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
                      if (picked != null)
                        setDialogState(() => dueDate = picked);
                    },
                  ),
                  const Divider(),
                  const Text('Wallet de transaction (choix explicite)'),
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
                        setDialogState(() => useExistingWallet = val ?? false),
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
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Annuler'),
              ),
              FilledButton(
                onPressed: () async {
                  final amount = double.tryParse(
                    amountController.text.replaceAll(',', '.'),
                  );
                  if (nameController.text.trim().isEmpty ||
                      amount == null ||
                      amount <= 0) {
                    return;
                  }

                  Wallet? transactionWallet;
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
                    _allWallets.add(transactionWallet);
                  }

                  final debtWallet = Wallet(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: nameController.text.trim(),
                    type: WalletType.debt,
                    targetAmount: amount,
                    dueDate: dueDate,
                    isCredit: isCredit,
                    createdAt: issueDate,
                  );

                  _allWallets.add(debtWallet);
                  _wallets.add(debtWallet);

                  final shouldCreateTx = await _askTransactionConfirmation(
                    'Voulez-vous enregistrer la transaction associée à cette dette ? (oui/non)',
                  );
                  if (shouldCreateTx) {
                    final txType = isCredit
                        ? TransactionType.expense
                        : TransactionType.income;
                    final tx = Transaction(
                      id: DateTime.now().microsecondsSinceEpoch.toString(),
                      amount: amount,
                      description: isCredit
                          ? 'Création dette (prêt) : ${debtWallet.name}'
                          : 'Création dette (emprunt) : ${debtWallet.name}',
                      type: txType,
                      date: issueDate,
                      walletId: transactionWallet.id,
                      relatedDebtId: debtWallet.id,
                    );
                    _transactions.insert(0, tx);
                    _showOperationSummary(
                      operation: 'Création de dette',
                      walletName: transactionWallet.name,
                      amount: txType == TransactionType.expense
                          ? -amount
                          : amount,
                      date: issueDate,
                      txType: txType.name,
                    );
                  } else {
                    _showOperationSummary(
                      operation: 'Création de dette (sans transaction)',
                      walletName: transactionWallet.name,
                      amount: isCredit ? -amount : amount,
                      date: issueDate,
                      txType: 'aucune',
                    );
                  }

                  setState(() {});
                  await _saveData();
                  if (ctx.mounted) Navigator.pop(ctx);
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
                const SizedBox(height: 8),
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
                          (w) =>
                              DropdownMenuItem(value: w.id, child: Text(w.name)),
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
                      setDialogState(() => useExistingWallet = val ?? false),
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
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Annuler'),
              ),
              FilledButton(
                onPressed: () async {
                  final amount = double.tryParse(
                    amountController.text.replaceAll(',', '.'),
                  );
                  if (amount == null || amount <= 0) return;
                  if (hasTarget && amount > remainingAmount) {
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Le remboursement dépasse le restant (${formatAmount(remainingAmount)}).',
                          ),
                        ),
                      );
                    }
                    return;
                  }

                  Wallet? transactionWallet;
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
                    _allWallets.add(transactionWallet);
                  }

                  debtWallet.initialBalance += amount;
                  if (hasTarget && _getDebtRemainingAmount(debtWallet) <= 0.0001) {
                    debtWallet.isSettled = true;
                  }

                  final shouldCreateTx = await _askTransactionConfirmation(
                    'Voulez-vous enregistrer la transaction de remboursement ? (oui/non)',
                  );
                  if (shouldCreateTx) {
                    final txType = debtWallet.isCredit
                        ? TransactionType.income
                        : TransactionType.expense;
                    final tx = Transaction(
                      id: DateTime.now().microsecondsSinceEpoch.toString(),
                      amount: amount,
                      description: 'Remboursement de ${debtWallet.name}',
                      type: txType,
                      date: DateTime.now(),
                      walletId: transactionWallet.id,
                      relatedDebtId: debtWallet.id,
                    );
                    _transactions.insert(0, tx);
                    _showOperationSummary(
                      operation: 'Remboursement',
                      walletName: transactionWallet.name,
                      amount: txType == TransactionType.expense
                          ? -amount
                          : amount,
                      date: DateTime.now(),
                      txType: txType.name,
                    );
                  } else {
                    _showOperationSummary(
                      operation: 'Remboursement (sans transaction)',
                      walletName: transactionWallet.name,
                      amount: debtWallet.isCredit ? amount : -amount,
                      date: DateTime.now(),
                      txType: 'aucune',
                    );
                  }
                  await _saveData();
                  if (context.mounted) {
                    final updatedRemaining = _getDebtRemainingAmount(debtWallet);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Remboursement de ${formatAmount(amount)} enregistré. '
                          'Reste: ${formatAmount(updatedRemaining)}',
                        ),
                      ),
                    );
                  }
                  setState(() {});
                  if (ctx.mounted) Navigator.pop(ctx);
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
                              onPressed: () {
                                setState(() {
                                  _transactions.removeWhere(
                                    (tx) =>
                                        tx.walletId == wallet.id ||
                                        tx.fromWalletId == wallet.id ||
                                        tx.toWalletId == wallet.id,
                                  );
                                  _wallets.remove(wallet);
                                  _allWallets.removeWhere(
                                    (w) => w.id == wallet.id,
                                  );
                                });
                                _saveData();
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
                  onPressed: () {
                    if (nameController.text.trim().isNotEmpty) {
                      final initialBalance =
                          double.tryParse(
                            initialBalanceController.text.replaceAll(',', '.'),
                          ) ??
                          0.0;
                      setState(() {
                        if (wallet == null) {
                          final newWallet = Wallet(
                            id: DateTime.now().millisecondsSinceEpoch
                                .toString(),
                            name: nameController.text.trim(),
                            initialBalance: initialBalance,
                            type: selectedType,
                            targetAmount: double.tryParse(
                              targetAmountController.text.replaceAll(',', '.'),
                            ),
                            dueDate: selectedDueDate,
                            isCredit: isCredit,
                            interestRate: hasInterest
                                ? double.tryParse(
                                    interestRateController.text.replaceAll(
                                      ',',
                                      '.',
                                    ),
                                  )
                                : null,
                          );
                          _wallets.add(newWallet);
                          _allWallets.add(newWallet);
                        } else {
                          wallet.name = nameController.text.trim();
                          wallet.initialBalance = initialBalance;
                          wallet.type = selectedType;
                          wallet.targetAmount = double.tryParse(
                            targetAmountController.text.replaceAll(',', '.'),
                          );
                          wallet.dueDate = selectedDueDate;
                          wallet.isCredit = isCredit;
                          wallet.interestRate = hasInterest
                              ? double.tryParse(
                                  interestRateController.text.replaceAll(
                                    ',',
                                    '.',
                                  ),
                                )
                              : null;
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
                    final hasInterest =
                        isDebt &&
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

                    // Label logic for Savings/Debt
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

                    return GestureDetector(
                      onTap: () => _showSpecializedWalletDialog(wallet: wallet),
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 16),
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
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              wallet.name,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w800,
                                                fontSize: 18,
                                                letterSpacing: -0.5,
                                              ),
                                            ),
                                            if (hasInterest) ...[
                                              const SizedBox(width: 8),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: theme
                                                      .colorScheme
                                                      .primary
                                                      .withValues(alpha: 0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  '+${wallet.interestRate}%',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: theme
                                                        .colorScheme
                                                        .primary,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        if (wallet.dueDate != null)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: 6.0,
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.event_note,
                                                  size: 14,
                                                  color: theme
                                                      .colorScheme
                                                      .primary
                                                      .withValues(alpha: 0.6),
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'Échéance: ${wallet.dueDate!.day}/${wallet.dueDate!.month}/${wallet.dueDate!.year}',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color: theme
                                                        .colorScheme
                                                        .onSurface
                                                        .withValues(
                                                          alpha: isDark
                                                              ? 0.8
                                                              : 0.5,
                                                        ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      if ((isDebt ||
                                              wallet.type ==
                                                  WalletType.savings) &&
                                          !wallet.isSettled)
                                        IconButton.filledTonal(
                                          onPressed: () =>
                                              _showTransactionModal(
                                                prefilledWalletId: wallet.id,
                                              ),
                                          icon: Icon(
                                            isDebt
                                                ? (wallet.isCredit
                                                      ? Icons.add
                                                      : Icons.remove)
                                                : Icons.add_circle_outline,
                                            size: 20,
                                          ),
                                          tooltip: isDebt
                                              ? (wallet.isCredit
                                                    ? 'Encaisser'
                                                    : 'Payer')
                                              : 'Épargner',
                                          color:
                                              wallet.type == WalletType.savings
                                              ? Colors.teal
                                              : null,
                                        ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: Icon(
                                          wallet.isSettled
                                              ? Icons.check_circle
                                              : Icons.circle_outlined,
                                        ),
                                        color: wallet.isSettled
                                            ? Colors.green
                                            : theme.colorScheme.onSurface
                                                  .withValues(
                                                    alpha: isDark ? 0.55 : 0.2,
                                                  ),
                                        onPressed: () {
                                          setState(() {
                                            wallet.isSettled =
                                                !wallet.isSettled;
                                          });
                                          _saveData();
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        mainLabel.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: theme.colorScheme.onSurface
                                              .withValues(
                                                alpha: isDark ? 0.72 : 0.4,
                                              ),
                                          letterSpacing: 1,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        formatAmount(balance),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 22,
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (hasTarget)
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          targetLabel.toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: theme.colorScheme.onSurface
                                                .withValues(
                                                  alpha: isDark ? 0.72 : 0.4,
                                                ),
                                            letterSpacing: 1,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          formatAmount(
                                            effectiveTarget - balance,
                                          ),
                                          style: TextStyle(
                                            fontWeight: FontWeight.w900,
                                            fontSize: 22,
                                            letterSpacing: -0.5,
                                            color: targetColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                              if (progress != null) ...[
                                const SizedBox(height: 20),
                                Stack(
                                  children: [
                                    Container(
                                      height: 8,
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.onSurface
                                            .withValues(alpha: 0.05),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                    FractionallySizedBox(
                                      widthFactor: progress,
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 500,
                                        ),
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: targetColor,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: targetColor.withValues(
                                                alpha: 0.3,
                                              ),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${(progress * 100).toStringAsFixed(0)}% rempli',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: theme.colorScheme.onSurface
                                            .withValues(
                                              alpha: isDark ? 0.82 : 0.6,
                                            ),
                                      ),
                                    ),
                                    if (hasTarget)
                                      Text(
                                        'sur ${formatAmount(effectiveTarget)}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                          color: theme.colorScheme.onSurface
                                              .withValues(
                                                alpha: isDark ? 0.72 : 0.4,
                                              ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ],
                          ),
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

                      return TransactionTile(
                        tx: tx,
                        categoryName: _getCategoryName(tx.categoryId),
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
