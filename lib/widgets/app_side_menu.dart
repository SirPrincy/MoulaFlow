import 'package:flutter/material.dart';
import '../home_page.dart';
import '../transactions_page.dart';
import '../settings_page.dart';
import '../pages/category_overview_page.dart';
import '../pages/recurring_payments_page.dart';
import '../pages/bills_to_pay_page.dart';
import '../pages/budget_planner_page.dart';
import '../models.dart';
import '../responsive_layout.dart';
import 'app_drawer.dart';

class AppSideMenu extends StatelessWidget {
  final String currentRoute;
  final bool isCollapsed;
  final ValueNotifier<ThemeMode> themeNotifier;
  final VoidCallback? onDataChange;

  const AppSideMenu({
    super.key,
    required this.currentRoute,
    this.isCollapsed = false,
    required this.themeNotifier,
    this.onDataChange,
  });

  Future<void> _navigateTo(BuildContext context, Widget page) async {
    if (context.isMobileScreen) Navigator.pop(context);
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
    onDataChange?.call();
  }

  @override
  Widget build(BuildContext context) {
    return AppDrawerContent(
      currentRoute: currentRoute,
      isCollapsed: isCollapsed,
      onHomeTap: () {
        if (currentRoute == '/') {
          if (context.isMobileScreen) Navigator.pop(context);
        } else {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => HomePage(themeNotifier: themeNotifier)),
            (route) => false,
          );
        }
      },
      onTransactionsTap: () => _navigateTo(context, const TransactionsPage()),
      onSettingsTap: () => _navigateTo(context, SettingsPage(themeNotifier: themeNotifier)),
      onAPayerTap: () => _navigateTo(context, const BillsToPayPage()),
      onDettesTap: () => _navigateTo(context, const CategoryOverviewPage(type: WalletType.debt, title: 'Dettes')),
      onEpargneTap: () => _navigateTo(context, const CategoryOverviewPage(type: WalletType.savings, title: 'Épargne')),
      onProjetTap: () => _navigateTo(context, const CategoryOverviewPage(type: WalletType.project, title: 'Projets')),
      onRecurringTap: () => _navigateTo(context, const RecurringPaymentsPage()),
      onBudgetsTap: () => _navigateTo(context, BudgetPlannerPage(themeNotifier: themeNotifier)),
    );
  }
}
