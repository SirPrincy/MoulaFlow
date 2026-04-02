import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Widget logo partagé — carré sombre + 3 vagues bleues, rendu Flutter natif.
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
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0E0E0E), Color(0xFF242424)],
          ),
        ),
        child: CustomPaint(
          painter: _WavesPainter(size: size),
        ),
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

class _WavesPainter extends CustomPainter {
  final double size;
  const _WavesPainter({required this.size});

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final paint = Paint()
      ..color = const Color(0xFFBCC2FF)
      ..strokeWidth = canvasSize.width * 0.048
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    const waveCount = 3;
    final startY = canvasSize.height * 0.35;
    final spacing = canvasSize.height * 0.12;
    final left = canvasSize.width * 0.20;
    final right = canvasSize.width * 0.80;
    final amplitude = canvasSize.height * 0.038;
    final segW = (right - left) / 4;

    for (int i = 0; i < waveCount; i++) {
      final y = startY + i * spacing;
      final path = Path();
      path.moveTo(left, y);

      // First arc: up
      path.cubicTo(
        left + segW, y - amplitude,
        left + segW * 2 - segW * 0.1, y + amplitude,
        left + segW * 2, y,
      );
      // Second arc: down
      path.cubicTo(
        left + segW * 2 + segW * 0.1, y - amplitude,
        right - segW, y + amplitude,
        right, y,
      );

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WavesPainter old) => old.size != size;
}
