import 'package:flutter/material.dart';
import '../../models.dart';
import '../dashboard_cards.dart';

class BalanceCard extends StatelessWidget {
  final double totalBalance;
  final List<Wallet> wallets;
  final Set<String> selectedWalletIds;
  final Function(String?) onWalletTap;
  final double Function(String) getWalletBalance;

  const BalanceCard({
    super.key,
    required this.totalBalance,
    required this.wallets,
    required this.selectedWalletIds,
    required this.onWalletTap,
    required this.getWalletBalance,
  });

  @override
  Widget build(BuildContext context) {
    return BalanceSummaryCard(
      totalBalance: totalBalance,
      wallets: wallets,
      selectedWalletIds: selectedWalletIds,
      onWalletTap: onWalletTap,
      getWalletBalance: getWalletBalance,
    );
  }
}
