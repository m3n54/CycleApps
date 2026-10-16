import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../domain/cycle_phase.dart';
import '../../../domain/cycle_predictor.dart';
import '../../../theme/cycle_theme.dart';

class CycleDial extends StatelessWidget {
  const CycleDial({
    super.key,
    required this.prediction,
    required this.today,
    this.size = 240.0,
  });

  final CyclePrediction prediction;
  final DateTime today;
  final double size;

  static Color colorForPhase(CyclePhase phase) {
    switch (phase) {
      case CyclePhase.menstrual:
        return CycleColors.phaseMenstrual;
      case CyclePhase.follicular:
        return CycleColors.phaseFollicular;
      case CyclePhase.ovulation:
        return CycleColors.phaseOvulation;
      case CyclePhase.luteal:
        return CycleColors.phaseLuteal;
    }
  }

  static IconData iconForPhase(CyclePhase phase) {
    switch (phase) {
      case CyclePhase.menstrual:
        return Icons.water_drop;
      case CyclePhase.follicular:
        return Icons.spa;
      case CyclePhase.ovulation:
        return Icons.wb_sunny;
      case CyclePhase.luteal:
        return Icons.nightlight_round;
    }
  }

  static String labelForPhase(CyclePhase phase) {
    switch (phase) {
      case CyclePhase.menstrual:
        return 'Menstruasi';
      case CyclePhase.follicular:
        return 'Folikular';
      case CyclePhase.ovulation:
        return 'Ovulasi';
      case CyclePhase.luteal:
        return 'Luteal';
    }
  }

  String _subtext(int? days) {
    if (days == null) return 'Belum ada catatan haid';
    if (days > 0) return 'Haid berikutnya ~$days hari';
    if (days == 0) return 'Haid diperkirakan hari ini';
    return 'Haid terlambat ${-days} hari';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cycleDay = prediction.cycleDayNumber(today);
    final phase = prediction.currentPhase(today);
    final phaseColor = colorForPhase(phase);
    final phaseIcon = iconForPhase(phase);
    final phaseLabel = labelForPhase(phase);
    final daysUntil = prediction.daysUntilNext(today);

    final progress = (cycleDay == null || prediction.avgCycleLength <= 0)
        ? 0.0
        : (cycleDay / prediction.avgCycleLength).clamp(0.0, 1.0);

    final trackColor = isDark
        ? CycleColors.borderDark.withValues(alpha: 0.65)
        : CycleColors.borderLight;
    final borderColor = isDark
        ? CycleColors.borderDark
        : CycleColors.primary.withValues(alpha: 0.14);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _CycleDialPainter(
              progress: progress,
              phaseColor: phaseColor,
              trackColor: trackColor,
              borderColor: borderColor,
              surfaceColor: isDark ? CycleColors.surfaceDark : CycleColors.surfaceLight,
            ),
          ),
          Padding(
            padding: EdgeInsets.all(size * 0.14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: phaseColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: phaseColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(phaseIcon, size: 14, color: phaseColor),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          phaseLabel,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: phaseColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  cycleDay != null ? 'Hari ke-$cycleDay' : 'Mulai Siklus',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: cycleDay != null ? 28 : 24,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _subtext(daysUntil),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CycleDialPainter extends CustomPainter {
  const _CycleDialPainter({
    required this.progress,
    required this.phaseColor,
    required this.trackColor,
    required this.borderColor,
    required this.surfaceColor,
  });

  final double progress;
  final Color phaseColor;
  final Color trackColor;
  final Color borderColor;
  final Color surfaceColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final strokeWidth = size.width * 0.068;
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2 - 4;

    // Inner soft surface disc
    final innerFillPaint = Paint()
      ..color = surfaceColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius - strokeWidth / 2, innerFillPaint);

    // Outer & inner soft border rings
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, radius + strokeWidth / 2 + 2, borderPaint);
    canvas.drawCircle(center, radius - strokeWidth / 2 - 2, borderPaint);

    // Subtle background track circle
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    // Progress arc
    if (progress > 0) {
      final rect = Rect.fromCircle(center: center, radius: radius);
      const startAngle = -math.pi / 2;
      final sweepAngle = 2 * math.pi * progress;

      final glowPaint = Paint()
        ..color = phaseColor.withValues(alpha: 0.22)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth + 6
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawArc(rect, startAngle, sweepAngle, false, glowPaint);

      final arcPaint = Paint()
        ..color = phaseColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, startAngle, sweepAngle, false, arcPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CycleDialPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.phaseColor != phaseColor ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.surfaceColor != surfaceColor;
  }
}
