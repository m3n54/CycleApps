import 'package:flutter/material.dart';

import '../../domain/cycle_predictor.dart';
import '../../domain/date_key.dart';
import '../../domain/day_entry.dart';
import '../../theme/cycle_theme.dart';

enum DayMarker { period, spotting, ovulation, predictedPeriod, fertile, logged, none }

/// Prioritas: data tercatat > prediksi.
DayMarker markerFor(DateTime day, Map<String, DayEntry> entriesByDate, CyclePrediction prediction) {
  final entry = entriesByDate[dateKey(day)];
  if (entry != null && entry.isPeriodDay) return DayMarker.period;
  if (entry?.flow == FlowLevel.spotting) return DayMarker.spotting;
  if (prediction.isOvulation(day)) return DayMarker.ovulation;
  if (prediction.isPredictedPeriod(day)) return DayMarker.predictedPeriod;
  if (prediction.isFertile(day)) return DayMarker.fertile;
  if (entry != null && !entry.isEmpty) return DayMarker.logged;
  return DayMarker.none;
}

const periodColor = CycleColors.phaseMenstrual;
const fertileColor = CycleColors.phaseOvulation;

class DayCell extends StatelessWidget {
  const DayCell({super.key, required this.day, required this.marker, this.isToday = false});

  final DateTime day;
  final DayMarker marker;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Color? fill;
    Color? border;
    var textColor = theme.colorScheme.onSurface;
    switch (marker) {
      case DayMarker.period:
        fill = periodColor;
        textColor = Colors.white;
      case DayMarker.spotting:
        fill = periodColor.withValues(alpha: 0.22);
        textColor = periodColor;
      case DayMarker.ovulation:
        fill = fertileColor;
        textColor = Colors.white;
      case DayMarker.predictedPeriod:
        border = periodColor;
        fill = periodColor.withValues(alpha: 0.08);
      case DayMarker.fertile:
        fill = fertileColor.withValues(alpha: 0.16);
        textColor = fertileColor;
      case DayMarker.logged:
      case DayMarker.none:
        break;
    }
    return Container(
      margin: const EdgeInsets.all(4),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(14),
        border: border != null
            ? Border.all(color: border, width: 1.8)
            : isToday
                ? Border.all(color: CycleColors.primary, width: 1.8)
                : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${day.day}',
            style: TextStyle(
              color: textColor,
              fontWeight: isToday || marker == DayMarker.period || marker == DayMarker.ovulation
                  ? FontWeight.w700
                  : FontWeight.w500,
            ),
          ),
          if (marker == DayMarker.logged)
            Container(
              margin: const EdgeInsets.only(top: 2),
              width: 5,
              height: 5,
              decoration: const BoxDecoration(
                color: CycleColors.secondary,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }
}
