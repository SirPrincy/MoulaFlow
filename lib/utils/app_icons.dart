import 'package:flutter/material.dart';

/// Utility class to map integer code points to constant IconData.
/// This is necessary for Flutter's icon tree-shaking in release builds.
class AppIcons {
  /// Maps a code point (and optional font family) to a constant IconData.
  /// If the code point is not recognized, it returns a default icon.
  static IconData getIconData(int? codePoint, {String fontFamily = 'MaterialIcons'}) {
    if (codePoint == null) return Icons.help_outline;

    switch (codePoint) {
      // User Avatars (Setup Wizard)
      case 0xf0071: // Icons.person_rounded.codePoint
        return Icons.person_rounded;
      case 0xf004e: // Icons.face_rounded.codePoint
        return Icons.face_rounded;
      case 0xf55f: // Icons.auto_awesome_rounded.codePoint
        return Icons.auto_awesome_rounded;
      case 0xf015a: // Icons.rocket_launch_rounded.codePoint
        return Icons.rocket_launch_rounded;
      case 0xf0083: // Icons.pets_rounded.codePoint
        return Icons.pets_rounded;
      case 0xf001d: // Icons.favorite_rounded.codePoint
        return Icons.favorite_rounded;

      // Project & Tag Defaults
      case 0xe556: // Icons.rocket_launch.codePoint
        return Icons.rocket_launch;
      case 0xf01c3: // Icons.local_offer_outlined.codePoint
        return Icons.local_offer_outlined;
      case 0xe11d: // Icons.category.codePoint
        return Icons.category;
      case 0xe897: // Icons.label_outline.codePoint
        return Icons.label_outline;
      case 0xe55f: // Icons.place_outlined.codePoint
        return Icons.place_outlined;
      case 0xe8f9: // Icons.schedule_rounded.codePoint
        return Icons.schedule_rounded;
      case 0xe850: // Icons.account_balance_wallet.codePoint
        return Icons.account_balance_wallet;
      case 0xe227: // Icons.savings.codePoint
        return Icons.savings;
      case 0xe263: // Icons.trending_up.codePoint
        return Icons.trending_up;
      case 0xe549: // Icons.local_hospital.codePoint
        return Icons.local_hospital;
      case 0xe80c: // Icons.school.codePoint
        return Icons.school;
      case 0xe530: // Icons.directions_car.codePoint
        return Icons.directions_car;
      case 0xe56c: // Icons.restaurant.codePoint
        return Icons.restaurant;
      case 0xe59c: // Icons.sports_esports.codePoint
        return Icons.sports_esports;
      case 0xe8cc: // Icons.shopping_bag.codePoint
        return Icons.shopping_bag;
      case 0xe539: // Icons.flight_takeoff.codePoint
        return Icons.flight_takeoff;
      case 0xe0af: // Icons.work_outline.codePoint
        return Icons.work_outline;

      // Other UI Icons
      case 0xe23f: // Icons.edit_outlined.codePoint
        return Icons.edit_outlined;
      case 0xe09b: // Icons.arrow_back_ios_new_rounded.codePoint
        return Icons.arrow_back_ios_new_rounded;
      case 0xe09e: // Icons.arrow_forward.codePoint
        return Icons.arrow_forward;

      default:
        // If it's a known code point from MaterialIcons but not in the switch, 
        // we still have to return a constant for tree-shaking to be happy.
        // In a perfect world, we'd map every icon. 
        // For a beta app, we map the most common ones provided in the UI.
        return Icons.help_outline;
    }
  }

  /// Helper to get the code point from a string (if stored as string)
  static IconData getIconFromStr(String? iconStr, {IconData fallback = Icons.rocket_launch}) {
    if (iconStr == null || iconStr.isEmpty) return fallback;
    final code = int.tryParse(iconStr);
    if (code == null) return fallback;
    final icon = getIconData(code);
    return icon == Icons.help_outline ? fallback : icon;
  }
}
