import 'package:flutter/material.dart';

import '../../../domain/day_entry.dart';
import '../../../domain/labels.dart';
import '../../../theme/cycle_theme.dart';

class TodaySummaryCard extends StatelessWidget {
  const TodaySummaryCard({
    super.key,
    this.entry,
  });

  final DayEntry? entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? CycleColors.surfaceDark : CycleColors.surfaceLight;
    final borderColor = isDark ? CycleColors.borderDark : CycleColors.borderLight;
    final hasData = entry != null && !entry!.isEmpty;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: CycleColors.primary.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.today_rounded,
                size: 18,
                color: CycleColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Ringkasan Hari Ini',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (!hasData)
            Text(
              'Belum ada catatan hari ini. Luangkan 1 menit untuk mencatat kondisi tubuh Anda.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.68),
                height: 1.4,
              ),
            )
          else ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (entry!.flow != null)
                  _SummaryChip(
                    icon: Icons.water_drop_rounded,
                    label: flowLabels[entry!.flow!]!,
                    color: CycleColors.phaseMenstrual,
                  ),
                if (entry!.energy != null)
                  _SummaryChip(
                    icon: Icons.bolt_rounded,
                    label: energyLabels[entry!.energy!]!,
                    color: CycleColors.secondary,
                  ),
                for (final symptom in entry!.symptoms)
                  _SummaryChip(
                    icon: Icons.healing_rounded,
                    label: symptomLabels[symptom]!,
                    color: CycleColors.primary,
                  ),
                for (final mood in entry!.moods)
                  _SummaryChip(
                    icon: Icons.mood_rounded,
                    label: moodLabels[mood]!,
                    color: CycleColors.accent,
                  ),
                if (entry!.cervicalMucus != null)
                  _SummaryChip(
                    icon: Icons.opacity_rounded,
                    label: cervicalMucusLabel(entry!.cervicalMucus!),
                    color: CycleColors.phaseFollicular,
                  ),
                if (entry!.sexualActivity != null)
                  _SummaryChip(
                    icon: Icons.favorite_rounded,
                    label: sexualActivityLabel(entry!.sexualActivity!),
                    color: CycleColors.phaseLuteal,
                  ),
              ],
            ),
            if (entry!.note.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                entry!.note.trim(),
                style: theme.textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 15, color: color),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
      backgroundColor: color.withValues(alpha: 0.1),
      side: BorderSide(color: color.withValues(alpha: 0.25)),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
