import 'package:flutter/material.dart';

import '../../../domain/cycle_phase_info.dart';
import '../../../theme/cycle_theme.dart';
import 'cycle_dial.dart';

class PhaseCard extends StatelessWidget {
  const PhaseCard({
    super.key,
    required this.phaseInfo,
  });

  final CyclePhaseInfo phaseInfo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final phaseColor = CycleDial.colorForPhase(phaseInfo.phase);
    final borderColor = isDark
        ? phaseColor.withValues(alpha: 0.35)
        : phaseColor.withValues(alpha: 0.22);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  CycleColors.surfaceDark,
                  phaseColor.withValues(alpha: 0.12),
                ]
              : [
                  CycleColors.surfaceLight,
                  phaseColor.withValues(alpha: 0.07),
                ],
        ),
        boxShadow: [
          BoxShadow(
            color: phaseColor.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      phaseInfo.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: phaseColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      phaseInfo.subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: phaseColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bolt_rounded, size: 15, color: phaseColor),
                    const SizedBox(width: 4),
                    Text(
                      phaseInfo.energyLevel,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: phaseColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            phaseInfo.hormoneDescription,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.78),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          _RecommendationRow(
            label: '🏋️ Aktivitas',
            recommendation: phaseInfo.workoutRecommendation,
            accentColor: phaseColor,
          ),
          const SizedBox(height: 8),
          _RecommendationRow(
            label: '🥗 Nutrisi',
            recommendation: phaseInfo.nutritionRecommendation,
            accentColor: phaseColor,
          ),
        ],
      ),
    );
  }
}

class _RecommendationRow extends StatelessWidget {
  const _RecommendationRow({
    required this.label,
    required this.recommendation,
    required this.accentColor,
  });

  final String label;
  final String recommendation;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark
            ? CycleColors.backgroundDark.withValues(alpha: 0.6)
            : Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.16),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: accentColor,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              recommendation,
              style: theme.textTheme.bodySmall?.copyWith(
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
