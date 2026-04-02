import 'package:flutter/material.dart';

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

  // Border
  static BorderSide kLightBorder(BuildContext context) => BorderSide(
    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
    width: 1.0,
  );
}
