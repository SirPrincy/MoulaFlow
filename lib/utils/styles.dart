import 'package:flutter/material.dart';
import 'dart:ui';

class AppStyles {
  // Border Radius
  static const double kDefaultRadius = 16.0;
  static const double kCardRadius = 16.0;
  static const double kButtonRadius = 100.0; // Keep buttons rounded as they usually look better
  static const double kInputRadius = 16.0;
  static const Radius kDefaultRadiusProp = Radius.circular(kDefaultRadius);
  static const BorderRadius kDefaultBorderRadius = BorderRadius.all(kDefaultRadiusProp);

  // Padding & Spacing
  static const double kDefaultPadding = 20.0;
  static const double kDefaultMargin = 16.0;

  // Spacing
  static const double kSpacing8 = 44.0; // 2.75rem based on design doc
  static const double kSpacing16 = 64.0;
  static const double kSpacing20 = 80.0;

  // Colors: Nocturnal Noir
  static const Color kSurface = Color(0xFF131313);
  static const Color kSurfaceLowest = Color(0xFF0E0E0E);
  static const Color kSurfaceHigh = Color(0xFF2A2A2A);
  static const Color kSurfaceBright = Color(0xFF393939);
  static const Color kPrimary = Color(0xFFBCC2FF);
  static const Color kOnSurface = Color(0xFFE5E2E1);
  static const Color kOnSurfaceVariant = Color(0xFFC6C5D4);
  static const Color kError = Color(0xFFFFB4AB);

  // Icons
  static const double kIconSize = 20.0;

  // Shadow
  static List<BoxShadow> get kSoftShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.03),
      blurRadius: 20,
      offset: const Offset(0, 10),
    ),
  ];

  static List<BoxShadow> get kAmbientShadow => [
    BoxShadow(
      color: kSurfaceLowest.withValues(alpha: 0.06),
      blurRadius: 60,
      offset: const Offset(0, 10),
    ),
  ];

  // Design Effects
  static Widget glassContainer({
    required Widget child,
    double blur = 20.0,
    double opacity = 0.7,
    BorderRadius? borderRadius,
  }) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            color: kSurfaceHigh.withValues(alpha: opacity),
            borderRadius: borderRadius,
          ),
          child: child,
        ),
      ),
    );
  }

  // Border
  static BorderSide kLightBorder(BuildContext context) => BorderSide(
    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
    width: 1.0,
  );

  static BorderSide kGhostBorder(BuildContext context) => BorderSide(
    color: kOnSurface.withValues(alpha: 0.15),
    width: 1.0,
  );

  static InputDecoration kInputDecoration(BuildContext context, String label, {String? hint}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1);
    final focusColor = theme.colorScheme.primary;

    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.03),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(kInputRadius),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(kInputRadius),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(kInputRadius),
        borderSide: BorderSide(color: focusColor, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}
