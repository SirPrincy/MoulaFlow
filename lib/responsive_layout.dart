import 'package:flutter/material.dart';

/// Constants for breakpoints used throughout the application.
class Breakpoints {
  static const double compact = 600;   // Mobile
  static const double medium = 1200;    // Tablet / Small Desktop
}

/// Helper methods to determine current device size category.
bool isCompact(BuildContext context) => MediaQuery.of(context).size.width < Breakpoints.compact;
bool isMedium(BuildContext context) => 
    MediaQuery.of(context).size.width >= Breakpoints.compact && 
    MediaQuery.of(context).size.width < Breakpoints.medium;
bool isExpanded(BuildContext context) => MediaQuery.of(context).size.width >= Breakpoints.medium;

/// A layout wrapper that centers its content and applies dynamic padding.
class ResponsiveCenter extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;

  const ResponsiveCenter({
    super.key, 
    required this.child, 
    this.maxWidth = 1100,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    // Dynamic horizontal padding that scretches on larger screens for a "premium" feel.
    final horizontalPadding = context.responsiveValue<double>(
      compact: 16.0,
      medium: 32.0,
      expanded: 60.0,
    );
    
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: padding ?? EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: child,
        ),
      ),
    );
  }
}

/// Extension to easily access constraints and responsive helpers from context.
extension ResponsiveHelper on BuildContext {
  double get screenWidth => MediaQuery.of(this).size.width;
  
  bool get isCompactScreen => screenWidth < Breakpoints.compact;
  bool get isMediumScreen => screenWidth >= Breakpoints.compact && screenWidth < Breakpoints.medium;
  bool get isExpandedScreen => screenWidth >= Breakpoints.medium;
  
  // Legacy support for older boolean getters if they were used.
  bool get isMobileScreen => isCompactScreen;
  bool get isTabletScreen => isMediumScreen;
  bool get isDesktopScreen => isExpandedScreen;
  
  /// Returns a value based on the current screen size.
  T responsiveValue<T>({
    required T compact,
    T? medium,
    T? expanded,
  }) {
    if (isExpandedScreen && expanded != null) return expanded;
    if (isMediumScreen && medium != null) return medium;
    return compact;
  }

  /// Adaptive padding based on screen size for list/grid items.
  EdgeInsets get responsivePadding => EdgeInsets.symmetric(
    horizontal: responsiveValue(compact: 16.0, medium: 24.0, expanded: 32.0),
    vertical: responsiveValue(compact: 12.0, medium: 16.0, expanded: 20.0),
  );

  /// Number of columns for grids based on screen space.
  int get gridColumns => responsiveValue(compact: 1, medium: 2, expanded: 3);
  
  /// Recommended max width for certain containers on large screens.
  double get contentMaxWidth => responsiveValue(compact: double.infinity, medium: 800.0, expanded: 1100.0);
}

