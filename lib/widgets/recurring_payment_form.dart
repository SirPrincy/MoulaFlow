import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models.dart';
import '../responsive_layout.dart';
import '../widgets.dart';
import '../utils/styles.dart';
import '../providers.dart';

class RecurringPaymentForm extends ConsumerStatefulWidget {
  final List<Wallet> wallets;
  final List<TransactionCategory> categories;
  final RecurringPayment? editingPayment;

  const RecurringPaymentForm({
    super.key,
    required this.wallets,
    required this.categories,
    this.editingPayment,
  });

  @override
  ConsumerState<RecurringPaymentForm> createState() => _RecurringPaymentFormState();
}

class _RecurringPaymentFormState extends ConsumerState<RecurringPaymentForm> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _amountController;
  late TextEditingController _tagsController;
  final List<String> _selectedTags = [];
  
  late TransactionType _type;
  late RecurrenceFrequency _frequency;
  late RecurringExecutionMode _executionMode;
  String? _selectedWalletId;
  String? _selectedCategoryId;
  late DateTime _startDate;

  @override
  void initState() {
    super.initState();
    if (widget.editingPayment != null) {
      final p = widget.editingPayment!;
      _nameController = TextEditingController(text: p.name);
      _descriptionController = TextEditingController(text: p.description);
      _amountController = TextEditingController(text: p.amount.toStringAsFixed(2));
      _tagsController = TextEditingController();
      _type = p.type;
      _frequency = p.frequency;
      _executionMode = p.executionMode;
      _selectedWalletId = p.walletId;
      _selectedCategoryId = p.categoryId;
      _startDate = p.startDate;
      _selectedTags.addAll(p.tags);
    } else {
      _nameController = TextEditingController();
      _descriptionController = TextEditingController();
      _amountController = TextEditingController();
      _tagsController = TextEditingController();
      _type = TransactionType.expense;
      _frequency = RecurrenceFrequency.monthly;
      _executionMode = RecurringExecutionMode.auto;
      _startDate = DateTime.now();
      if (widget.wallets.isNotEmpty) {
        _selectedWalletId = widget.wallets.first.id;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    final amountText = _amountController.text.trim();
    final amount = double.tryParse(amountText.replaceAll(',', '.'));

    if (name.isEmpty || amount == null || amount <= 0 || _selectedWalletId == null || _selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs obligatoires')),
      );
      return;
    }

    final payment = RecurringPayment(
      id: widget.editingPayment?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      description: _descriptionController.text.trim(),
      amount: amount,
      type: _type,
      walletId: _selectedWalletId,
      categoryId: _selectedCategoryId,
      tags: _selectedTags,
      frequency: _frequency,
      executionMode: _executionMode,
      startDate: _startDate,
      nextDueDate: widget.editingPayment?.nextDueDate ?? _startDate,
      isActive: widget.editingPayment?.isActive ?? true,
    );

    Navigator.of(context).pop(payment);
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

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.editingPayment != null;
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        top: 32.0,
        bottom: MediaQuery.of(context).viewInsets.bottom + 48.0,
      ),
      child: ResponsiveCenter(
        maxWidth: 600,
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isEditing ? 'Éditer l\'abonnement' : 'Nouvel abonnement',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            
            // Type toggle
            Row(
              children: [
                _buildTypeButton('Dépense', TransactionType.expense, Colors.red),
                const SizedBox(width: 8),
                _buildTypeButton('Revenu', TransactionType.income, Colors.green),
              ],
            ),
            const SizedBox(height: 24),

            TextField(
              controller: _nameController,
              decoration: _inputDeco('Nom de l\'abonnement *', 'Ex: Netflix, Loyer...'),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: _inputDeco('Description', 'Détails optionnels...'),
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: _inputDeco('Montant', '0.00'),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<RecurrenceFrequency>(
                    initialValue: _frequency,
                    items: RecurrenceFrequency.values.map((f) {
                      String label = '';
                      switch (f) {
                        case RecurrenceFrequency.once: label = 'Une seule fois'; break;
                        case RecurrenceFrequency.daily: label = 'Quotidien'; break;
                        case RecurrenceFrequency.weekly: label = 'Hebdo'; break;
                        case RecurrenceFrequency.monthly: label = 'Mensuel'; break;
                        case RecurrenceFrequency.yearly: label = 'Annuel'; break;
                      }
                      return DropdownMenuItem(value: f, child: Text(label));
                    }).toList(),
                    onChanged: (val) => setState(() => _frequency = val!),
                    decoration: _inputDeco('Fréquence', ''),
                    dropdownColor: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(AppStyles.kDefaultRadius),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              initialValue: _selectedWalletId,
              items: widget.wallets.map((w) => DropdownMenuItem(value: w.id, child: Text(w.name))).toList(),
              onChanged: (val) => setState(() => _selectedWalletId = val),
              decoration: _inputDeco('Wallet', ''),
              dropdownColor: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(AppStyles.kDefaultRadius),
            ),
            const SizedBox(height: 16),

            InkWell(
              onTap: () async {
                final String? pickedId = await showModalBottomSheet<String>(
                  context: context,
                  isScrollControlled: true,
                  builder: (context) => CategoryPickerModal(
                    categories: widget.categories,
                    transactionType: _type,
                  ),
                );
                if (pickedId != null) setState(() => _selectedCategoryId = pickedId);
              },
              borderRadius: BorderRadius.circular(AppStyles.kDefaultRadius),
              child: InputDecorator(
                decoration: _inputDeco('Catégorie', ''),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_selectedCategoryId == null ? 'Sélectionner...' : _getCategoryName(_selectedCategoryId!)),
                    const Icon(Icons.keyboard_arrow_right),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Tags', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ..._selectedTags.map((tag) => InputChip(
                  label: Text(tag),
                  onDeleted: () => setState(() => _selectedTags.remove(tag)),
                )),
                IntrinsicWidth(
                  child: TextField(
                    controller: _tagsController,
                    decoration: const InputDecoration(
                      hintText: 'Ajouter tag...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 4),
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
              const SizedBox(height: 12),
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
                          avatar: Icon(Icons.add, size: 14, color: t.color != null ? Color(int.parse(t.color!.replaceAll('#', '0xFF'))) : null),
                          label: Text(t.name),
                          onPressed: () => setState(() => _selectedTags.add(t.name)),
                        ),
                      )),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            
            // Execution Mode
            SwitchListTile(
              title: const Text('Validation automatique', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Ajouter au ledger sans confirmation le jour J.'),
              value: _executionMode == RecurringExecutionMode.auto,
              onChanged: (val) {
                setState(() {
                  _executionMode = val ? RecurringExecutionMode.auto : RecurringExecutionMode.manual;
                });
              },
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppStyles.kDefaultRadius)),
              activeThumbColor: theme.colorScheme.primary,
            ),
            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppStyles.kDefaultRadius)),
              ),
              child: const Text('Enregistrer', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeButton(String label, TransactionType type, Color activeColor) {
    final isActive = _type == type;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _type = type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isActive ? activeColor : theme.colorScheme.surface,
            border: Border.all(color: isActive ? activeColor : (isDark ? Colors.white30 : Colors.black12)),
            borderRadius: BorderRadius.circular(AppStyles.kDefaultRadius),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isActive ? Colors.white : (isDark ? Colors.white : Colors.black),
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
}
