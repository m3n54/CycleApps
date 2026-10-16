import 'package:flutter/material.dart';

import '../../../domain/cycle_phase.dart';
import '../../../domain/cycle_phase_info.dart';
import '../../../theme/cycle_theme.dart';

class PhaseGuideSheet extends StatefulWidget {
  const PhaseGuideSheet({super.key});

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

  @override
  State<PhaseGuideSheet> createState() => _PhaseGuideSheetState();
}

class _PhaseGuideSheetState extends State<PhaseGuideSheet> {
  final Set<CyclePhase> _expandedPhases = CyclePhase.values.toSet();

  void _togglePhase(CyclePhase phase) {
    setState(() {
      if (_expandedPhases.contains(phase)) {
        _expandedPhases.remove(phase);
      } else {
        _expandedPhases.add(phase);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: CycleColors.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.menu_book_rounded,
                size: 18,
                color: CycleColors.accent,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Panduan 4 Fase Siklus',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        for (final phase in CyclePhase.values) ...[
          _PhaseGuideCard(
            info: CyclePhaseInfo.forPhase(phase),
            phaseColor: PhaseGuideSheet.colorForPhase(phase),
            isExpanded: _expandedPhases.contains(phase),
            onTap: () => _togglePhase(phase),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _PhaseGuideCard extends StatelessWidget {
  const _PhaseGuideCard({
    required this.info,
    required this.phaseColor,
    required this.isExpanded,
    required this.onTap,
  });

  final CyclePhaseInfo info;
  final Color phaseColor;
  final bool isExpanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? CycleColors.surfaceDark : CycleColors.surfaceLight,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: phaseColor.withValues(alpha: isDark ? 0.35 : 0.25),
            ),
            boxShadow: [
              BoxShadow(
                color: phaseColor.withValues(alpha: 0.05),
                blurRadius: 12,
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
                  Container(
                    width: 12,
                    height: 12,
                    margin: const EdgeInsets.only(top: 5),
                    decoration: BoxDecoration(
                      color: phaseColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          info.title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: phaseColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          info.subtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: phaseColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.bolt_rounded, size: 14, color: phaseColor),
                        const SizedBox(width: 4),
                        Text(
                          info.energyLevel,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: phaseColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    isExpanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: phaseColor,
                    size: 20,
                  ),
                ],
              ),
              if (isExpanded) ...[
                const SizedBox(height: 12),
                Text(
                  info.hormoneDescription,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                _GuideRecommendationTile(
                  label: 'Aktivitas & Olahraga',
                  value: info.workoutRecommendation,
                  icon: Icons.fitness_center_rounded,
                  accentColor: phaseColor,
                ),
                const SizedBox(height: 8),
                _GuideRecommendationTile(
                  label: 'Nutrisi & Asupan',
                  value: info.nutritionRecommendation,
                  icon: Icons.restaurant_rounded,
                  accentColor: phaseColor,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _GuideRecommendationTile extends StatelessWidget {
  const _GuideRecommendationTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.accentColor,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark
            ? CycleColors.backgroundDark.withValues(alpha: 0.55)
            : accentColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.16),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: accentColor),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: accentColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.bodySmall?.copyWith(
                    height: 1.35,
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
