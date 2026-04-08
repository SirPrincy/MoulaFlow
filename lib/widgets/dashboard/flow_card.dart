import 'package:flutter/material.dart';
import '../dashboard_cards.dart';

class FlowDashboardCard extends StatelessWidget {
  final double income;
  final double expenses;

  const FlowDashboardCard({
    super.key,
    required this.income,
    required this.expenses,
  });

  @override
  Widget build(BuildContext context) {
    return FlowCard(income: income, expenses: expenses);
  }
}
