import 'package:flutter/material.dart';
import '../../data/dashboard_repository.dart';
import '../dashboard_cards.dart';

class CategoryDashboardCard extends StatelessWidget {
  final Map<String, double> categorySpending;
  final CategoryChartStyle style;
  final bool isEditMode;
  final ValueChanged<CategoryChartStyle> onStyleChange;

  const CategoryDashboardCard({
    super.key,
    required this.categorySpending,
    required this.style,
    required this.isEditMode,
    required this.onStyleChange,
  });

  @override
  Widget build(BuildContext context) {
    return CategoryChartCard(
      categorySpending: categorySpending,
      style: style,
      isEditMode: isEditMode,
      onStyleChange: onStyleChange,
    );
  }
}
