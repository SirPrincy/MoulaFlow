import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../responsive_layout.dart';
import '../models.dart';
import '../utils/styles.dart';
import '../providers.dart';
import 'category_picker.dart';
import 'dialogs.dart';
import 'numeric_pad.dart';
import 'package:intl/intl.dart';
import 'package:math_expressions/math_expressions.dart';

class TransactionForm extends ConsumerStatefulWidget {
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
  ConsumerState<TransactionForm> createState() => _TransactionFormState();
}

class _TransactionFormState extends ConsumerState<TransactionForm> {
  late TextEditingController _amountController;
  late TextEditingController _descController;
  late TextEditingController _tagsController;
  final List<String> _selectedTags = [];
  
  late TransactionType _type;
  String? _selectedWalletId;
  String? _fromWalletId;
  String? _toWalletId;
  String? _selectedCategoryId;
  late DateTime _date;
  bool _isNumericPadVisible = false; // Hidden by default for a cleaner look

  @override
  void initState() {
    super.initState();
    
    if (widget.editingTx != null) {
      final tx = widget.editingTx!;
      _amountController = TextEditingController(text: tx.amount.toStringAsFixed(2));
      _descController = TextEditingController(text: tx.description);
      _tagsController = TextEditingController();
      _type = tx.type;
      _selectedWalletId = tx.walletId;
      _fromWalletId = tx.fromWalletId;
      _toWalletId = tx.toWalletId;
      _selectedCategoryId = tx.categoryId;
      _date = tx.date;
      _selectedTags.addAll(tx.tags);
      
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
            _selectedCategoryId = wallet.isCredit ? 'cat_dettes_repay_in' : 'cat_dettes_repay_out';
          } else if (wallet.type == WalletType.savings) {
            _type = TransactionType.income;
            _descController = TextEditingController(text: 'Épargne pour ${wallet.name}');
            _selectedCategoryId = 'cat_epargne_livret';
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

    if (widget.editingTx != null) {
      _isNumericPadVisible = false;
    }
  }

  void _onNumberInput(String value) {
    setState(() {
      final currentText = _amountController.text;
      
      // Allow only one decimal point per number segment
      if (value == '.') {
        final lastSegment = currentText.split(RegExp(r'[+\-*/]')).last;
        if (lastSegment.contains('.')) return;
      }
      
      // Handle operators: replace last operator if another is pressed
      final operators = ['+', '-', '*', '/'];
      if (operators.contains(value)) {
        if (currentText.isEmpty) return; // Can't start with an operator (except maybe - but keeping it simple)
        final lastChar = currentText.substring(currentText.length - 1);
        if (operators.contains(lastChar)) {
          _amountController.text = currentText.substring(0, currentText.length - 1) + value;
          return;
        }
      }

      if (currentText == '0' && !operators.contains(value) && value != '.') {
        _amountController.text = value;
      } else {
        _amountController.text = currentText + value;
      }
    });
  }

  double? _evaluateExpression(String text) {
    if (text.isEmpty) return null;
    try {
      // Clean the expression for math_expressions (it uses * and / as standard)
      final expression = text.replaceAll(',', '.');
      final p = ShuntingYardParser();
      final exp = p.parse(expression);
      final cm = ContextModel();
      return const RealEvaluator().evaluate(exp, cm);
    } catch (e) {
      return null;
    }
  }

  void _onBackspace() {
    setState(() {
      final currentText = _amountController.text;
      if (currentText.isNotEmpty) {
        _amountController.text = currentText.substring(0, currentText.length - 1);
      }
    });
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

    final amount = _evaluateExpression(amountText.replaceAll(',', '.'));
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
      tags: _selectedTags,
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
    final DateTime? pickedDate = await showDatePicker(
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
    
    if (pickedDate != null && mounted) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_date),
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

      if (pickedTime != null) {
        setState(() {
          _date = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
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
            AppStyles.glassContainer(
              borderRadius: BorderRadius.circular(AppStyles.kDefaultRadius),
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Row(
                  children: [
                    _buildTypeButton('Dépense', TransactionType.expense, Colors.redAccent),
                    const SizedBox(width: 4),
                    _buildTypeButton('Revenu', TransactionType.income, Colors.greenAccent.shade700),
                    const SizedBox(width: 4),
                    _buildTypeButton('Transfert', TransactionType.transfer, isDark ? Colors.white24 : Colors.black87),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            if (_type == TransactionType.transfer) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('DE', style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          isExpanded: true,
                          initialValue: _fromWalletId,
                          items: widget.wallets.map<DropdownMenuItem<String>>((w) => DropdownMenuItem<String>(value: w.id, child: Text(w.name, overflow: TextOverflow.ellipsis))).toList(),
                          onChanged: (val) => setState(() => _fromWalletId = val),
                          decoration: _inputDeco('', ''),
                          dropdownColor: theme.colorScheme.surface,
                          icon: Icon(Icons.keyboard_arrow_down, color: dropdownIconColor),
                          style: textStyle.copyWith(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 24, 12, 0),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.swap_horiz_rounded, color: theme.colorScheme.primary, size: 24),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('VERS', style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          isExpanded: true,
                          initialValue: _toWalletId,
                          items: widget.wallets.map<DropdownMenuItem<String>>((w) => DropdownMenuItem<String>(value: w.id, child: Text(w.name, overflow: TextOverflow.ellipsis))).toList(),
                          onChanged: (val) => setState(() => _toWalletId = val),
                          decoration: _inputDeco('', ''),
                          dropdownColor: theme.colorScheme.surface,
                          icon: Icon(Icons.keyboard_arrow_down, color: dropdownIconColor),
                          style: textStyle.copyWith(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('COMPTE', style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedWalletId,
                          items: widget.wallets.map<DropdownMenuItem<String>>((w) => DropdownMenuItem<String>(value: w.id, child: Text(w.name))).toList(),
                          onChanged: (val) => setState(() => _selectedWalletId = val),
                          decoration: _inputDeco('', ''),
                          dropdownColor: theme.colorScheme.surface,
                          icon: Icon(Icons.keyboard_arrow_down, color: dropdownIconColor),
                          style: textStyle.copyWith(fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('CATÉGORIE', style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: _pickCategory,
                          borderRadius: BorderRadius.circular(AppStyles.kDefaultRadius),
                          child: InputDecorator(
                            decoration: _inputDeco('', ''),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    _selectedCategoryId == null ? 'Choisir...' : _getCategoryName(_selectedCategoryId!),
                                    style: textStyle.copyWith(fontSize: 15, color: _selectedCategoryId == null ? (isDark ? Colors.white54 : Colors.black54) : null),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Icon(Icons.keyboard_arrow_right, color: dropdownIconColor, size: 20),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            
            GestureDetector(
              onTap: () => setState(() => _isNumericPadVisible = !_isNumericPadVisible),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(AppStyles.kDefaultRadius),
                  border: Border.all(
                    color: _isNumericPadVisible 
                      ? theme.colorScheme.primary.withValues(alpha: 0.5) 
                      : theme.colorScheme.onSurface.withValues(alpha: 0.1),
                    width: _isNumericPadVisible ? 2 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _amountController.text.isEmpty ? '0.00' : _amountController.text,
                          style: textStyle.copyWith(
                            fontSize: 42, 
                            fontWeight: FontWeight.w900, 
                            letterSpacing: -1,
                            color: _amountController.text.isEmpty ? theme.colorScheme.onSurface.withValues(alpha: 0.2) : theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '€', 
                          style: textStyle.copyWith(fontSize: 24, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                        ),
                      ],
                    ),
                    const Divider(height: 32),
                    InkWell(
                      onTap: _pickDate,
                      borderRadius: BorderRadius.circular(AppStyles.kDefaultRadius),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.calendar_today_rounded, size: 18, color: theme.colorScheme.primary),
                            const SizedBox(width: 12),
                            Text(
                              DateFormat('dd MMMM yyyy, HH:mm', 'fr_FR').format(_date),
                              style: textStyle.copyWith(fontSize: 16, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.edit_calendar_rounded, size: 16, color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              child: _isNumericPadVisible 
                ? Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: NumericPad(
                      onInput: _onNumberInput,
                      onBackspace: _onBackspace,
                      onDone: () {
                        final result = _evaluateExpression(_amountController.text);
                        if (result != null) {
                          setState(() {
                            _amountController.text = result % 1 == 0 
                                ? result.toInt().toString() 
                                : result.toStringAsFixed(2);
                            _isNumericPadVisible = false;
                          });
                        } else {
                          setState(() => _isNumericPadVisible = false);
                        }
                      },
                    ),
                  )
                : const SizedBox.shrink(),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _descController,
              decoration: _inputDeco('Note', 'Ajouter une description...'),
              cursorColor: isDark ? Colors.white : Colors.black,
              style: textStyle.copyWith(fontSize: 16, fontWeight: FontWeight.w400),
            ),
            const SizedBox(height: 24),
            
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.local_offer_rounded, size: 16, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text('TAGS', style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppStyles.kDefaultRadius),
                    border: Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.05)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ..._selectedTags.map((tag) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.1)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(tag, style: TextStyle(fontSize: 13, color: theme.colorScheme.onPrimaryContainer, fontWeight: FontWeight.w600)),
                                const SizedBox(width: 4),
                                GestureDetector(
                                  onTap: () => setState(() => _selectedTags.remove(tag)),
                                  child: Icon(Icons.close, size: 14, color: theme.colorScheme.onPrimaryContainer),
                                ),
                              ],
                            ),
                          )),
                          IntrinsicWidth(
                            child: TextField(
                              controller: _tagsController,
                              style: const TextStyle(fontSize: 14),
                              decoration: const InputDecoration(
                                hintText: 'Ajouter...',
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                              ),
                              onSubmitted: (val) {
                                final tag = val.trim();
                                if (tag.isNotEmpty && !_selectedTags.contains(tag)) {
                                  setState(() {
                                    _selectedTags.add(tag);
                                    _tagsController.clear();
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      if (ref.watch(tagsProvider).hasValue) ...[
                        const Divider(height: 24),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              ...ref.watch(tagsProvider).value!
                                .where((t) => !_selectedTags.contains(t.name))
                                .take(5)
                                .map((t) => Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: ActionChip(
                                    visualDensity: VisualDensity.compact,
                                    avatar: Icon(Icons.add, size: 12, color: t.color != null ? Color(int.parse(t.color!.replaceAll('#', '0xFF'))) : null),
                                    label: Text(t.name, style: const TextStyle(fontSize: 12)),
                                    onPressed: () => setState(() => _selectedTags.add(t.name)),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                    backgroundColor: Colors.transparent,
                                    side: BorderSide(color: theme.colorScheme.onSurface.withValues(alpha: 0.1)),
                                  ),
                                )),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Recurring option removed for rework
            const SizedBox(height: 32),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                elevation: 8,
                shadowColor: theme.colorScheme.primary.withValues(alpha: 0.3),
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppStyles.kButtonRadius)),
              ),
              child: Text(
                isEditing ? 'SAUVEGARDER' : 'VALIDER LA TRANSACTION',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1),
              ),
            ),
            if (isEditing) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: _delete,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  foregroundColor: theme.colorScheme.error,
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
