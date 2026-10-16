import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../domain/cycle_predictor.dart';
import '../../../state/providers.dart';
import '../../../theme/cycle_theme.dart';

class CycleStatsCard extends ConsumerWidget {
  const CycleStatsCard({
    super.key,
    this.prediction,
  });

  final CyclePrediction? prediction;

  String _formatShortDate(DateTime date) {
    try {
      return DateFormat('d MMM yyyy', 'id_ID').format(date);
    } catch (_) {
      return DateFormat('d MMM yyyy').format(date);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final CyclePrediction resolvedPrediction =
        prediction ?? ref.watch(predictionProvider);
    final periods = resolvedPrediction.periods;
    final recentPeriods = periods.reversed.take(5).toList();

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
            color: CycleColors.primary.withValues(alpha: 0.05),
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
                  color: CycleColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.insights_rounded,
                  size: 18,
                  color: CycleColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Statistik Siklus',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  label: 'Rata-rata Siklus',
                  value: '${resolvedPrediction.avgCycleLength} hari',
                  accentColor: CycleColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricTile(
                  label: 'Rata-rata Durasi Haid',
                  value: '${resolvedPrediction.avgPeriodLength} hari',
                  accentColor: CycleColors.secondary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricTile(
                  label: 'Total Siklus Tercatat',
                  value: '${periods.length} siklus',
                  accentColor: CycleColors.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'Riwayat Haid Terakhir',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          if (recentPeriods.isEmpty)
            Text(
              'Belum ada riwayat siklus tercatat.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
              ),
            )
          else
            Column(
              children: [
                for (final period in recentPeriods)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _PeriodHistoryRow(
                      dateRange:
                          '${_formatShortDate(period.start)} – ${_formatShortDate(period.end)}',
                      lengthDays: period.length,
                      targetLength: resolvedPrediction.avgPeriodLength,
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.accentColor,
  });

  final String label;
  final String value;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? accentColor.withValues(alpha: 0.12)
            : accentColor.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: accentColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
              fontWeight: FontWeight.w600,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}

class _PeriodHistoryRow extends StatelessWidget {
  const _PeriodHistoryRow({
    required this.dateRange,
    required this.lengthDays,
    required this.targetLength,
  });

  final String dateRange;
  final int lengthDays;
  final int targetLength;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxDays = (targetLength * 2).clamp(7, 14);
    final progress = (lengthDays / maxDays).clamp(0.15, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              dateRange,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '$lengthDays hari',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: CycleColors.phaseMenstrual,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 7,
            backgroundColor: CycleColors.phaseMenstrual.withValues(alpha: 0.12),
            valueColor: const AlwaysStoppedAnimation<Color>(
              CycleColors.phaseMenstrual,
            ),
          ),
        ),
      ],
    );
  }
}
