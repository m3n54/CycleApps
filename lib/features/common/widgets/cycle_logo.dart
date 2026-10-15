import 'package:flutter/material.dart';

import '../../../theme/cycle_theme.dart';

/// Vector-based logo for CycleApp featuring a circular gradient badge,
/// soft halo ring, and an elegant wellness icon.
class CycleLogo extends StatelessWidget {
  const CycleLogo({
    super.key,
    this.size = 64.0,
  });

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            CycleColors.primary,
            CycleColors.secondary,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: CycleColors.primary.withValues(alpha: 0.28),
            blurRadius: size * 0.25,
            offset: Offset(0, size * 0.08),
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: size * 0.78,
          height: size * 0.78,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.35),
              width: size * 0.03,
            ),
          ),
          child: Center(
            child: Icon(
              Icons.spa_rounded,
              size: size * 0.46,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
