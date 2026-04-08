import 'package:flutter/material.dart';
import '../../data/dashboard_repository.dart';
import '../../responsive_layout.dart';

class DashboardModulesLayout extends StatelessWidget {
  final bool isEditMode;
  final List<DashboardWidgetType> dashboardItems;
  final Widget Function(DashboardWidgetType type) buildModule;
  final void Function(int oldIndex, int newIndex) onReorder;

  const DashboardModulesLayout({
    super.key,
    required this.isEditMode,
    required this.dashboardItems,
    required this.buildModule,
    required this.onReorder,
  });

  @override
  Widget build(BuildContext context) {
    if (isEditMode) {
      return ReorderableListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 0),
        itemCount: dashboardItems.length,
        onReorder: onReorder,
        buildDefaultDragHandles: true,
        proxyDecorator: (child, index, animation) =>
            Material(color: Colors.transparent, child: child),
        itemBuilder: (context, index) => buildModule(dashboardItems[index]),
      );
    }

    if (context.gridColumns > 1) {
      return Wrap(
        spacing: 20,
        runSpacing: 0,
        children: dashboardItems.map((type) {
          final isFullWidth = type == DashboardWidgetType.balance;
          final availableWidth =
              context.screenWidth - (context.isExpandedScreen ? 300 : 120);
          final cardWidth = isFullWidth ? double.infinity : (availableWidth - 60) / 2;

          return SizedBox(
            width: cardWidth,
            child: buildModule(type),
          );
        }).toList(),
      );
    }

    return Column(
      children: dashboardItems.map(buildModule).toList(),
    );
  }
}
