import 'package:flutter/material.dart';

/// Konsep B: "Twin Ribbon Heart & Moon"
/// Logo khas Siklus yang melambangkan keintiman dan harmoni pasangan:
/// dua pita melengkung yang saling memeluk membentuk siluet hati dan bulan sabit,
/// bergradien duotone kontras tinggi (Amethyst Violet & Strawberry Pink)
/// dengan pantulan mutiara bercahaya di bagian tengah.
class CycleLogo extends StatelessWidget {
  const CycleLogo({
    super.key,
    this.size = 64.0,
    this.isSquircle = false,
    this.showGlow = true,
  });

  final double size;
  final bool isSquircle;
  final bool showGlow;

  @override
  Widget build(BuildContext context) {
    final borderRadius = isSquircle
        ? BorderRadius.circular(size * 0.28)
        : BorderRadius.circular(size / 2);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF6D28D9), // Royal Amethyst
            Color(0xFF7C3AED), // Vivid Violet
            Color(0xFFBE185D), // Deep Rose-Berry
            Color(0xFFF43F5E), // Hot Strawberry
          ],
          stops: [0.0, 0.32, 0.72, 1.0],
        ),
        boxShadow: showGlow
            ? [
                BoxShadow(
                  color: const Color(0xFF7C3AED).withValues(alpha: 0.30),
                  blurRadius: size * 0.35,
                  offset: Offset(-size * 0.05, size * 0.12),
                ),
                BoxShadow(
                  color: const Color(0xFFF43F5E).withValues(alpha: 0.35),
                  blurRadius: size * 0.40,
                  offset: Offset(size * 0.06, size * 0.14),
                ),
              ]
            : null,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Inner translucent rim (Glassmorphic highlight)
          Container(
            margin: EdgeInsets.all(size * 0.04),
            decoration: BoxDecoration(
              borderRadius: isSquircle
                  ? BorderRadius.circular(size * 0.24)
                  : BorderRadius.circular(size / 2),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.28),
                width: size * 0.025,
              ),
            ),
          ),

          // Custom Vector Emblem (Twin Ribbon Heart & Moon)
          CustomPaint(
            size: Size(size * 0.72, size * 0.72),
            painter: _TwinRibbonPainter(),
          ),
        ],
      ),
    );
  }
}

class _TwinRibbonPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2.0;
    final cy = size.height / 2.0 + (size.height * 0.03);
    final s = size.width * 0.48;

    // 1. Bayangan halus pita (Soft ambient shadow)
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    // 2. Ribbon 2: Pita Pasangan Merangkul (Right Heart Lobe - Rose Peach Glow)
    final partnerPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [
          Color(0xFFFFF0F5), // Lavender blush
          Color(0xFFFFD1DC), // Soft rose
          Color(0xFFFDA4AF), // Warm peach pink
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = size.width * 0.125;

    final partnerPath = Path();
    partnerPath.moveTo(cx, cy + s * 0.85);
    partnerPath.cubicTo(
      cx + s * 1.15,
      cy + s * 0.35,
      cx + s * 1.05,
      cy - s * 0.95,
      cx,
      cy - s * 0.25,
    );

    // 3. Ribbon 1: Pita Bulan Sabit & Hati Kiri (Left Heart & Crescent Moon - Luminous Pearl White)
    final moonPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white,
          Color(0xFFFFF5F8),
          Color(0xFFFDE8EF),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = size.width * 0.145;

    final moonPath = Path();
    moonPath.moveTo(cx, cy + s * 0.85);
    moonPath.cubicTo(
      cx - s * 1.15,
      cy + s * 0.40,
      cx - s * 1.10,
      cy - s * 0.95,
      cx - s * 0.05,
      cy - s * 0.35,
    );

    // Inner crescent sweep
    final innerCrescentPath = Path();
    innerCrescentPath.moveTo(cx - s * 0.28, cy + s * 0.42);
    innerCrescentPath.cubicTo(
      cx - s * 0.72,
      cy + s * 0.05,
      cx - s * 0.55,
      cy - s * 0.55,
      cx - s * 0.05,
      cy - s * 0.18,
    );

    final innerCrescentPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white,
          Color(0xFFFFE4E6),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = size.width * 0.09;

    // Draw Shadows
    canvas.save();
    canvas.translate(0, size.height * 0.035);
    shadowPaint.strokeWidth = size.width * 0.13;
    canvas.drawPath(partnerPath, shadowPaint);
    canvas.drawPath(moonPath, shadowPaint);
    canvas.restore();

    // Draw Ribbons
    canvas.drawPath(partnerPath, partnerPaint);
    canvas.drawPath(moonPath, moonPaint);
    canvas.drawPath(innerCrescentPath, innerCrescentPaint);

    // 4. Central Glowing Vitality Pearl
    final pearlCenter = Offset(cx + s * 0.08, cy - s * 0.06);
    final pearlRadius = size.width * 0.07;

    final pearlGlowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFFBEB).withValues(alpha: 0.85),
          const Color(0xFFFDE68A).withValues(alpha: 0.35),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(center: pearlCenter, radius: pearlRadius * 2.2),
      );
    canvas.drawCircle(pearlCenter, pearlRadius * 2.2, pearlGlowPaint);

    final pearlPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(pearlCenter, pearlRadius, pearlPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
