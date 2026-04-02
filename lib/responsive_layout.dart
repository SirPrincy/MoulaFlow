import 'package:flutter/material.dart';

/// Constants for breakpoints used throughout the application.
class Breakpoints {
  static const double mobile = 600;
  static const double tablet = 1024;
}

/// Helper methods to determine current device size category.
bool isMobile(BuildContext context) => MediaQuery.of(context).size.width < Breakpoints.mobile;
bool isTablet(BuildContext context) => 
    MediaQuery.of(context).size.width >= Breakpoints.mobile && 
    MediaQuery.of(context).size.width < Breakpoints.tablet;
bool isDesktop(BuildContext context) => MediaQuery.of(context).size.width >= Breakpoints.tablet;

/// A simple layout wrapper that centers its content and applies a maximum width.
/// Perfect for maintaining a centered, clean minimalist UI on larger screens.
class ResponsiveCenter extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;

  const ResponsiveCenter({
    super.key, 
    required this.child, 
    this.maxWidth = 800,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: padding ?? EdgeInsets.zero,
          child: child,
        ),
      ),
    );
  }
}

/// Extension to easily access constraints and responsive helpers from context.
extension ResponsiveHelper on BuildContext {
  double get screenWidth => MediaQuery.of(this).size.width;
  bool get isMobileScreen => screenWidth < Breakpoints.mobile;
  bool get isTabletScreen => screenWidth >= Breakpoints.mobile && screenWidth < Breakpoints.tablet;
  bool get isDesktopScreen => screenWidth >= Breakpoints.tablet;
  
  T responsiveValue<T>({
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktopScreen && desktop != null) return desktop;
    if (isTabletScreen && tablet != null) return tablet;
    return mobile;
  }
}
