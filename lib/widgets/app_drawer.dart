import 'package:flutter/material.dart';
import '../utils/styles.dart';
import 'app_logo.dart';

class AppDrawerContent extends StatelessWidget {
  final String currentRoute;
  final VoidCallback? onHomeTap;
  final VoidCallback? onTransactionsTap;
  final VoidCallback? onSettingsTap;
  final VoidCallback? onAPayerTap;
  final VoidCallback? onDettesTap;
  final VoidCallback? onEpargneTap;
  final VoidCallback? onProjetTap;
  final VoidCallback? onRecurringTap;
  final VoidCallback? onBudgetsTap;
  final bool isCollapsed;

  const AppDrawerContent({
    super.key,
    this.currentRoute = '/',
    this.onHomeTap,
    this.onTransactionsTap,
    this.onSettingsTap,
    this.onAPayerTap,
    this.onDettesTap,
    this.onEpargneTap,
    this.onProjetTap,
    this.onRecurringTap,
    this.onBudgetsTap,
    this.isCollapsed = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: theme.colorScheme.surface,
      child: Column(
        children: [
          if (!isCollapsed) ...[
            Container(
              padding: const EdgeInsets.fromLTRB(24, 64, 24, 32),
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppLogo(size: 48),
                  const SizedBox(height: 16),
                  const Text(
                    'Moula Flow',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 24,
                      letterSpacing: -1,
                    ),
                  ),
                  Text(
                    'Minimalist Finance',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: 64),
            const Center(child: AppLogo(size: 40)),
            const SizedBox(height: 32),
          ],

          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: isCollapsed ? 8 : 16),
              children: [
                _buildNavItem(
                  context,
                  Icons.dashboard_outlined,
                  Icons.dashboard,
                  'Tableau de bord',
                  '/',
                  onHomeTap,
                ),
                _buildNavItem(
                  context,
                  Icons.receipt_long_outlined,
                  Icons.receipt_long,
                  'Transactions',
                  '/transactions',
                  onTransactionsTap,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: 8.0,
                    horizontal: 16.0,
                  ),
                  child: Divider(height: 1),
                ),
                _buildNavItem(
                  context,
                  Icons.receipt_outlined,
                  Icons.receipt,
                  'À payer',
                  '/bills',
                  onAPayerTap,
                ),
                _buildNavItem(
                  context,
                  Icons.receipt_long_outlined,
                  Icons.receipt_long,
                  'Dettes',
                  '/dettes',
                  onDettesTap,
                ),
                _buildNavItem(
                  context,
                  Icons.savings_outlined,
                  Icons.savings,
                  'Épargne',
                  '/epargne',
                  onEpargneTap,
                ),
                _buildNavItem(
                  context,
                  Icons.rocket_launch_outlined,
                  Icons.rocket_launch,
                  'Projets',
                  '/projets',
                  onProjetTap,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: 8.0,
                    horizontal: 16.0,
                  ),
                  child: Divider(height: 1),
                ),
                _buildNavItem(
                  context,
                  Icons.autorenew_outlined,
                  Icons.autorenew,
                  'Paiements Récurrents',
                  '/recurring',
                  onRecurringTap,
                ),
                _buildNavItem(
                  context,
                  Icons.pie_chart_outline,
                  Icons.pie_chart,
                  'Budgets',
                  '/budgets',
                  onBudgetsTap,
                ),
                _buildNavItem(
                  context,
                  Icons.settings_outlined,
                  Icons.settings,
                  'Paramètres',
                  '/settings',
                  onSettingsTap,
                ),
              ],
            ),
          ),

          if (!isCollapsed)
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                'v0.01 • Beta',
                style: TextStyle(
                  fontSize: 10,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    IconData icon,
    IconData activeIcon,
    String label,
    String route,
    VoidCallback? onTap,
  ) {
    final theme = Theme.of(context);
    final isActive = currentRoute == route;
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppStyles.kDefaultRadius),
        child: Container(
          padding: EdgeInsets.symmetric(
            vertical: 12,
            horizontal: isCollapsed ? 4 : 16,
          ),
          decoration: BoxDecoration(
            color: isActive
                ? (isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.05))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppStyles.kDefaultRadius),
          ),
          child: Row(
            mainAxisAlignment: isCollapsed
                ? MainAxisAlignment.center
                : MainAxisAlignment.start,
            children: [
              Icon(
                isActive ? activeIcon : icon,
                color: isActive
                    ? theme.colorScheme.onSurface
                    : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                size: 22,
              ),
              if (!isCollapsed) ...[
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
                      color: isActive
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      fontSize: 15,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
