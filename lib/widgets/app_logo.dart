import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Widget logo partagé, rendu depuis l'asset SVG officiel.
class AppLogo extends StatelessWidget {
  final double size;
  final double borderRadius;
  final bool withShadow;

  const AppLogo({
    super.key,
    this.size = 48,
    this.borderRadius = 16,
    this.withShadow = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget core = ClipRRect(
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
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 40,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: core,
      );
    }

    return core;
  }
}
