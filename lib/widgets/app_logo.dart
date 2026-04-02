import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../utils/styles.dart';

/// Widget logo partagé — utilisé sur l'onboarding, le drawer, etc.
class AppLogo extends StatelessWidget {
  final double size;
  final double borderRadius;
  final bool withShadow;

  const AppLogo({
    super.key,
    this.size = 48,
    this.borderRadius = AppStyles.kDefaultRadius,
    this.withShadow = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget logo = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SvgPicture.asset(
        'assets/logo_moula.svg',
        width: size,
        height: size,
        fit: BoxFit.cover,
      ),
    );

    if (withShadow) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 40,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: logo,
      );
    }

    return SizedBox(width: size, height: size, child: logo);
  }
}
