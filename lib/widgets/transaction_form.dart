import 'package:flutter/material.dart';
import '../responsive_layout.dart';
import '../models.dart';
import '../utils/styles.dart';
import 'category_picker.dart';
import 'dialogs.dart';

class TransactionForm extends StatefulWidget {
  final List<Wallet> wallets;
  final List<TransactionCategory> categories;
  final Transaction? editingTx;
  final String? prefilledWalletId;

  const TransactionForm({
    super.key,
    required this.wallets,
    required this.categories,
    this.editingTx,
    this.prefilledWalletId,
  });

  @override
  State<TransactionForm> createState() => _TransactionFormState();
}

class _TransactionFormState extends State<TransactionForm> {
  late TextEditingController _amountController;
  late TextEditingController _descController;
  late TextEditingController _tagsController;
  
  late TransactionType _type;
  String? _selectedWalletId;
  String? _fromWalletId;
  String? _toWalletId;
  String? _selectedCategoryId;
  late DateTime _date;
  bool _isRecurring = false;

  @override
  void initState() {
    super.initState();
    
    if (widget.editingTx != null) {
      final tx = widget.editingTx!;
      _amountController = TextEditingController(text: tx.amount.toStringAsFixed(2));
      _descController = TextEditingController(text: tx.description);
      _tagsController = TextEditingController(text: tx.tags.join('; '));
      _type = tx.type;
      _selectedWalletId = tx.walletId;
      _fromWalletId = tx.fromWalletId;
      _toWalletId = tx.toWalletId;
      _selectedCategoryId = tx.categoryId;
      _date = tx.date;
      _isRecurring = tx.isRecurring;
      
      if (_selectedWalletId != null && !widget.wallets.any((w) => w.id == _selectedWalletId)) _selectedWalletId = null;
      if (_fromWalletId != null && !widget.wallets.any((w) => w.id == _fromWalletId)) _fromWalletId = null;
      if (_toWalletId != null && !widget.wallets.any((w) => w.id == _toWalletId)) _toWalletId = null;
    } else {
      _amountController = TextEditingController();
      _descController = TextEditingController();
      _tagsController = TextEditingController();
      _type = TransactionType.expense;
      _date = DateTime.now();
      
      if (widget.prefilledWalletId != null) {
        _selectedWalletId = widget.prefilledWalletId;
        _fromWalletId = widget.prefilledWalletId;
        
        final walletList = widget.wallets.where((w) => w.id == widget.prefilledWalletId).toList();
        if (walletList.isNotEmpty) {
          final wallet = walletList.first;
          if (wallet.type == WalletType.debt) {
            _type = wallet.isCredit ? TransactionType.income : TransactionType.expense;
            _descController = TextEditingController(text: wallet.isCredit ? 'Remboursement de ${wallet.name}' : 'Paiement de ${wallet.name}');
          } else if (wallet.type == WalletType.savings) {
            _type = TransactionType.income;
            _descController = TextEditingController(text: 'Épargne pour ${wallet.name}');
          }
        }
      } else if (widget.wallets.isNotEmpty) {
        _selectedWalletId = widget.wallets.first.id;
        _fromWalletId = widget.wallets.first.id;
        if (widget.wallets.length > 1) {
          _toWalletId = widget.wallets[1].id;
        } else {
          _toWalletId = widget.wallets.first.id;
        }
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  void _submit() {
    final amountText = _amountController.text.trim();
    final descText = _descController.text.trim();
    final tagsText = _tagsController.text.trim();

    if (amountText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Veuillez entrer un montant', style: TextStyle(color: Colors.white)),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
      return;
    }
    
    if (_type != TransactionType.transfer && _selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Veuillez sélectionner une catégorie', style: TextStyle(color: Colors.white)),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
      return;
    }

    if (_type == TransactionType.transfer && _fromWalletId == _toWalletId) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Veuillez sélectionner deux wallets différents', style: TextStyle(color: Colors.white)),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
      return;
    }

    final amount = double.tryParse(amountText.replaceAll(',', '.'));
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Veuillez entrer un montant valide', style: TextStyle(color: Colors.white)),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
      return;
    }

    final wId = _type != TransactionType.transfer ? _selectedWalletId : null;
    final fId = _type == TransactionType.transfer ? _fromWalletId : null;
    final tId = _type == TransactionType.transfer ? _toWalletId : null;
    
    if (_type != TransactionType.transfer && wId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez sélectionner un wallet')));
      return;
    }

    List<String> tagsList = tagsText.isNotEmpty 
        ? tagsText.split(';').map((e) => e.trim()).where((e) => e.isNotEmpty).toList() 
        : [];

    final savedTx = Transaction(
      id: widget.editingTx?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      amount: amount,
      description: descText,
      type: _type,
      date: _date,
      walletId: wId,
      fromWalletId: fId,
      toWalletId: tId,
      categoryId: _type == TransactionType.transfer ? null : _selectedCategoryId,
      tags: tagsList,
      isRecurring: _isRecurring,
    );

    Navigator.of(context).pop({'action': 'save', 'tx': savedTx});
  }
  
  void _delete() async {
    final bool? confirm = await showDeleteConfirmDialog(context, 'Êtes-vous sûr de vouloir supprimer cette transaction ?');
    if (confirm == true && mounted) {
      Navigator.of(context).pop({'action': 'delete', 'tx': widget.editingTx});
    }
  }

  void _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
         return Theme(
           data: Theme.of(context).copyWith(
             colorScheme: Theme.of(context).colorScheme.copyWith(
               primary: Theme.of(context).colorScheme.onSurface,
             ),
           ),
           child: child!,
         );
      },
    );
    if (picked != null && picked != _date) {
      setState(() {
        _date = picked;
      });
    }
  }

  String _getCategoryName(String id) {
    for (var mainCat in widget.categories) {
      if (mainCat.id == id) return mainCat.name;
      for (var subCat in mainCat.subcategories) {
        if (subCat.id == id) return '${mainCat.name} > ${subCat.name}';
      }
    }
    return 'Catégorie inconnue';
  }

  void _pickCategory() async {
    final String? pickedId = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppStyles.kDefaultRadius)),
      ),
    builder: (context) {
        return CategoryPickerModal(
          categories: widget.categories,
          transactionType: _type,
        );
      },
    );

    if (pickedId != null) {
      setState(() {
        _selectedCategoryId = pickedId;
      });
    }
  }

  Widget _buildTypeButton(String label, TransactionType type, Color activeColor) {
    final isActive = _type == type;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final unselectedBg = theme.colorScheme.surface;
    final unselectedBorder = isDark ? Colors.white30 : Colors.black;
    final unselectedText = isDark ? Colors.white : Colors.black;

    return Expanded(
      child: GestureDetector(
        onTap: () {
           setState(() {
              _type = type;
              if (type == TransactionType.transfer) {
                _selectedCategoryId = null;
              }
           });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isActive ? activeColor : unselectedBg,
            border: Border.all(color: isActive ? activeColor : unselectedBorder, width: 1.5),
            borderRadius: BorderRadius.circular(AppStyles.kDefaultRadius),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: isActive ? Colors.white : unselectedText,
            ),
          ),
        ),
      ),
    );
  }
  
  InputDecoration _inputDeco(String label, String hint) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = isDark ? Colors.white30 : Colors.black26;
    final focusColor = isDark ? Colors.white : Colors.black;
    final labelColor = isDark ? Colors.white70 : Colors.black54;

    return InputDecoration(
      labelText: label,
      hintText: hint,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppStyles.kDefaultRadius)),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: borderColor),
        borderRadius: BorderRadius.circular(AppStyles.kDefaultRadius),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: focusColor, width: 2),
        borderRadius: BorderRadius.circular(AppStyles.kDefaultRadius),
      ),
      labelStyle: TextStyle(color: labelColor),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.editingTx != null;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textStyle = TextStyle(fontWeight: FontWeight.w600, fontSize: 18, color: isDark ? Colors.white : Colors.black);
    final dropdownIconColor = isDark ? Colors.white : Colors.black;

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        top: 32.0,
        bottom: MediaQuery.of(context).viewInsets.bottom + 48.0,
      ),
      child: ResponsiveCenter(
        maxWidth: 600,
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isEditing ? 'Éditer Transaction' : 'Nouvelle Transaction',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                _buildTypeButton('Dépense', TransactionType.expense, Colors.red),
                const SizedBox(width: 8),
                _buildTypeButton('Revenu', TransactionType.income, Colors.green),
                const SizedBox(width: 8),
                _buildTypeButton('Transfert', TransactionType.transfer, isDark ? Colors.grey.shade700 : Colors.black),
              ],
            ),
            const SizedBox(height: 24),
            
            if (_type == TransactionType.transfer) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _fromWalletId,
                      items: widget.wallets.map<DropdownMenuItem<String>>((w) => DropdownMenuItem<String>(value: w.id, child: Text(w.name))).toList(),
                      onChanged: (val) => setState(() => _fromWalletId = val),
                      decoration: _inputDeco('De', ''),
                      dropdownColor: theme.colorScheme.surface,
                      icon: Icon(Icons.keyboard_arrow_down, color: dropdownIconColor),
                      style: textStyle.copyWith(fontSize: 16),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(Icons.arrow_forward, color: isDark ? Colors.white54 : Colors.black54),
                  ),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _toWalletId,
                      items: widget.wallets.map<DropdownMenuItem<String>>((w) => DropdownMenuItem<String>(value: w.id, child: Text(w.name))).toList(),
                      onChanged: (val) => setState(() => _toWalletId = val),
                      decoration: _inputDeco('Vers', ''),
                      dropdownColor: theme.colorScheme.surface,
                      icon: Icon(Icons.keyboard_arrow_down, color: dropdownIconColor),
                      style: textStyle.copyWith(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedWalletId,
                      items: widget.wallets.map<DropdownMenuItem<String>>((w) => DropdownMenuItem<String>(value: w.id, child: Text(w.name))).toList(),
                      onChanged: (val) => setState(() => _selectedWalletId = val),
                      decoration: _inputDeco('Wallet', ''),
                      dropdownColor: theme.colorScheme.surface,
                      icon: Icon(Icons.keyboard_arrow_down, color: dropdownIconColor),
                      style: textStyle.copyWith(fontSize: 16),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    onPressed: () {
                      Navigator.of(context).pop({'action': 'create_wallet'});
                    },
                    icon: const Icon(Icons.add_home_work_outlined, size: 20),
                    tooltip: 'Nouveau Wallet',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _pickCategory,
                borderRadius: BorderRadius.circular(AppStyles.kDefaultRadius),
                child: InputDecorator(
                  decoration: _inputDeco('Catégorie *', ''),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedCategoryId == null ? 'Sélectionner...' : _getCategoryName(_selectedCategoryId!),
                        style: textStyle.copyWith(fontSize: 16, color: _selectedCategoryId == null ? (isDark ? Colors.white54 : Colors.black54) : null),
                      ),
                      Icon(Icons.keyboard_arrow_right, color: dropdownIconColor),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: _inputDeco('Montant *', '0.00'),
                    cursorColor: isDark ? Colors.white : Colors.black,
                    style: textStyle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(AppStyles.kDefaultRadius),
                    child: InputDecorator(
                      decoration: _inputDeco('Date *', ''),
                      child: Text(
                        '${_date.day.toString().padLeft(2, '0')}/${_date.month.toString().padLeft(2, '0')}/${_date.year}',
                        style: textStyle.copyWith(fontSize: 16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descController,
              decoration: _inputDeco('Description (Optionnel)', 'Ex: Courses, Salaire...'),
              cursorColor: isDark ? Colors.white : Colors.black,
              style: textStyle.copyWith(fontSize: 16),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _tagsController,
              decoration: _inputDeco('Tags (Optionnel)', 'Ex: vacances; espagne'),
              cursorColor: isDark ? Colors.white : Colors.black,
              style: textStyle.copyWith(fontSize: 16),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Transaction Récurrente', style: TextStyle(fontWeight: FontWeight.w600)),
              value: _isRecurring,
              onChanged: (val) => setState(() => _isRecurring = val),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppStyles.kDefaultRadius)),
              activeThumbColor: theme.colorScheme.primary,
            ),
            const SizedBox(height: 32),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppStyles.kDefaultRadius)),
                  ),
                  child: Text(
                    isEditing ? 'Sauvegarder' : 'Valider',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                if (isEditing) ...[
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _delete,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      foregroundColor: Colors.red,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppStyles.kDefaultRadius)),
                    ),
                    child: const Text(
                      'Supprimer cette transaction',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

