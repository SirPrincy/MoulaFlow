import 'package:flutter/material.dart';
import '../../models.dart';
import '../dashboard_cards.dart';

class RecentActivityCard extends StatelessWidget {
  final List<Transaction> transactions;
  final String Function(String?) getCategoryName;
  final String Function(Transaction) getWalletCaption;
  final VoidCallback onTap;

  const RecentActivityCard({
    super.key,
    required this.transactions,
    required this.getCategoryName,
    required this.getWalletCaption,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return RecentTransactionsCard(
      transactions: transactions,
      getCategoryName: getCategoryName,
      getWalletCaption: getWalletCaption,
      onTap: onTap,
    );
  }
}
