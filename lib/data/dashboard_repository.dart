import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'storage_keys.dart';

enum DashboardWidgetType {
  balance,    // Fixed: Total + Wallets
  flow,       // Income vs Expenses
  categories, // Top Categories Chart
  trends,     // Flow Trend Line
  recent,     // Recent 5 Transactions
  projects    // Project Tracking
}

enum CategoryChartStyle {
  donut,
  bar,
  halfDonut
}

class DashboardConfig {
  final List<DashboardWidgetType> order;
  final Set<DashboardWidgetType> visible;
  final CategoryChartStyle categoryChartStyle;

  DashboardConfig({
    required this.order, 
    required this.visible,
    this.categoryChartStyle = CategoryChartStyle.donut,
  });

  Map<String, dynamic> toJson() => {
    'order': order.map((e) => e.name).toList(),
    'visible': visible.map((e) => e.name).toList(),
    'categoryChartStyle': categoryChartStyle.name,
  };

  factory DashboardConfig.fromJson(Map<String, dynamic> json) {
    final orderList = (json['order'] as List<dynamic>?)
            ?.map((e) => DashboardWidgetType.values.firstWhere((w) => w.name == e))
            .toList() ?? DashboardWidgetType.values.toList();
    
    final visibleSet = (json['visible'] as List<dynamic>?)
            ?.map((e) => DashboardWidgetType.values.firstWhere((w) => w.name == e))
            .toSet() ?? DashboardWidgetType.values.toSet();

    final chartStyle = CategoryChartStyle.values.firstWhere(
      (e) => e.name == json['categoryChartStyle'],
      orElse: () => CategoryChartStyle.donut,
    );

    // Ensure 'balance' is always first and visible as per the rules
    if (!orderList.contains(DashboardWidgetType.balance)) {
      orderList.insert(0, DashboardWidgetType.balance);
    } else if (orderList.indexOf(DashboardWidgetType.balance) != 0) {
      orderList.remove(DashboardWidgetType.balance);
      orderList.insert(0, DashboardWidgetType.balance);
    }
    visibleSet.add(DashboardWidgetType.balance);

    return DashboardConfig(order: orderList, visible: visibleSet, categoryChartStyle: chartStyle);
  }

  static DashboardConfig defaultConfig() => DashboardConfig(
    order: DashboardWidgetType.values.toList(),
    visible: DashboardWidgetType.values.toSet(),
    categoryChartStyle: CategoryChartStyle.donut,
  );
}

class DashboardRepository {
  Future<DashboardConfig> loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(StorageKeys.dashboardConfig);
    if (jsonStr == null) return DashboardConfig.defaultConfig();
    try {
      return DashboardConfig.fromJson(json.decode(jsonStr));
    } catch (_) {
      return DashboardConfig.defaultConfig();
    }
  }

  Future<void> saveConfig(DashboardConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(StorageKeys.dashboardConfig, json.encode(config.toJson()));
  }
}
