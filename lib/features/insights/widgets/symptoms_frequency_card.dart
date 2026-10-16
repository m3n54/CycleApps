import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/day_entry.dart';
import '../../../domain/labels.dart';
import '../../../state/providers.dart';
import '../../../theme/cycle_theme.dart';

class SymptomsFrequencyCard extends ConsumerWidget {
  const SymptomsFrequencyCard({
    super.key,
    this.entries,
  });

  final List<DayEntry>? entries;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final List<DayEntry> resolvedEntries =
        entries ?? ref.watch(dayEntriesProvider).valueOrNull ?? const <DayEntry>[];

    final symptomCounts = <Symptom, int>{};
    final moodCounts = <Mood, int>{};

    for (final entry in resolvedEntries) {
      for (final symptom in entry.symptoms) {
        symptomCounts[symptom] = (symptomCounts[symptom] ?? 0) + 1;
      }
      for (final mood in entry.moods) {
        moodCounts[mood] = (moodCounts[mood] ?? 0) + 1;
      }
    }

    final topSymptoms = symptomCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topMoods = moodCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final hasData = topSymptoms.isNotEmpty || topMoods.isNotEmpty;

    var maxCount = 1;
    for (final item in topSymptoms) {
      maxCount = math.max(maxCount, item.value);
    }
    for (final item in topMoods) {
      maxCount = math.max(maxCount, item.value);
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? CycleColors.surfaceDark : CycleColors.surfaceLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? CycleColors.borderDark : CycleColors.borderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: CycleColors.secondary.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: CycleColors.secondary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.bar_chart_rounded,
                  size: 18,
                  color: CycleColors.secondary,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Frekuensi Gejala & Mood',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (!hasData)
            Text(
              'Belum ada gejala yang tercatat',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
              ),
            )
          else ...[
            if (topSymptoms.isNotEmpty) ...[
              Text(
                'Gejala Teratas',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: CycleColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              for (final entry in topSymptoms.take(5))
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _FrequencyBarRow(
                    label: symptomLabels[entry.key] ?? entry.key.name,
                    count: entry.value,
                    maxCount: maxCount,
                    barColor: CycleColors.primary,
                  ),
                ),
            ],
            if (topMoods.isNotEmpty) ...[
              if (topSymptoms.isNotEmpty) const SizedBox(height: 6),
              Text(
                'Mood Teratas',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: CycleColors.accent,
                ),
              ),
              const SizedBox(height: 8),
              for (final entry in topMoods.take(5))
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _FrequencyBarRow(
                    label: moodLabels[entry.key] ?? entry.key.name,
                    count: entry.value,
                    maxCount: maxCount,
                    barColor: CycleColors.accent,
                  ),
                ),
            ],
          ],
        ],
      ),
    );
  }
}

class _FrequencyBarRow extends StatelessWidget {
  const _FrequencyBarRow({
    required this.label,
    required this.count,
    required this.maxCount,
    required this.barColor,
  });

  final String label;
  final int count;
  final int maxCount;
  final Color barColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = (count / maxCount).clamp(0.1, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '$count hari',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: barColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 7,
            backgroundColor: barColor.withValues(alpha: 0.12),
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
          ),
        ),
      ],
    );
  }
}
