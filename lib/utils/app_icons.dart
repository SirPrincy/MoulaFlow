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
