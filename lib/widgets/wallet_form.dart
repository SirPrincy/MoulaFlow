import 'package:flutter/material.dart';
import '../models.dart';

class WalletForm extends StatefulWidget {
  final Wallet? initialWallet;
  final ValueChanged<Wallet> onSave;

  const WalletForm({
    super.key,
    this.initialWallet,
    required this.onSave,
  });

  @override
  State<WalletForm> createState() => _WalletFormState();
}

class _WalletFormState extends State<WalletForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _balanceController;
  late WalletType _selectedType;

  final List<({String label, IconData icon, WalletType type})> _walletTypes = [
    (label: 'Courant', icon: Icons.account_balance_wallet_rounded, type: WalletType.current),
    (label: 'Banque', icon: Icons.account_balance_rounded, type: WalletType.bank),
    (label: 'Épargne', icon: Icons.savings_rounded, type: WalletType.savings),
    (label: 'Cash', icon: Icons.payments_rounded, type: WalletType.cash),
    (label: 'Mobile Money', icon: Icons.phone_android_rounded, type: WalletType.mobileMoney),
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialWallet?.name ?? '');
    _balanceController = TextEditingController(
      text: widget.initialWallet != null ? widget.initialWallet!.initialBalance.toStringAsFixed(2) : '',
    );
    _selectedType = widget.initialWallet?.type ?? WalletType.current;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final balanceText = _balanceController.text.replaceAll(',', '.');
      final initialBalance = double.tryParse(balanceText) ?? 0.0;
      
      final wallet = widget.initialWallet != null
          ? widget.initialWallet!.copyWith(
              name: _nameController.text.trim(),
              initialBalance: initialBalance,
              type: _selectedType,
            )
          : Wallet(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              name: _nameController.text.trim(),
              initialBalance: initialBalance,
              type: _selectedType,
            );

      widget.onSave(wallet);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _nameController,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              labelText: 'NOM DU COMPTE',
              labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
              hintText: 'ex: Compte Principal',
              floatingLabelBehavior: FloatingLabelBehavior.always,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Le nom du compte est requis.';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          const Text('TYPE DE COMPTE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _walletTypes.map((item) {
              final isSelected = _selectedType == item.type;
              return GestureDetector(
                onTap: () => setState(() => _selectedType = item.type),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? theme.colorScheme.primary.withValues(alpha: 0.1) : theme.colorScheme.onSurface.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: isSelected ? Border.all(color: theme.colorScheme.primary, width: 2) : Border.all(color: Colors.transparent),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(item.icon, size: 18, color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface),
                      const SizedBox(width: 8),
                      Text(item.label, style: TextStyle(fontSize: 13, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500, color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _balanceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              labelText: 'SOLDE INITIAL',
              labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
              suffixText: '€',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                 return 'Le solde est requis.';
              }
              if (double.tryParse(value.replaceAll(',', '.')) == null) {
                return 'Solde invalide.';
              }
              return null;
            },
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _submit,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(widget.initialWallet == null ? 'Créer le compte' : 'Mettre à jour'),
            ),
          )
        ],
      ),
    );
  }
}
