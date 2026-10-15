import 'package:flutter/material.dart';

import '../../domain/cycle_predictor.dart';
import '../../domain/date_key.dart';
import '../../domain/day_entry.dart';

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

const periodColor = Color(0xFFD9475B);
const fertileColor = Color(0xFF2A9D8F);

class DayCell extends StatelessWidget {
  const DayCell({super.key, required this.day, required this.marker, this.isToday = false});

  final DateTime day;
  final DayMarker marker;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    Color? fill;
    Color? border;
    var textColor = Theme.of(context).colorScheme.onSurface;
    switch (marker) {
      case DayMarker.period:
        fill = periodColor;
        textColor = Colors.white;
      case DayMarker.spotting:
        fill = periodColor.withValues(alpha: 0.25);
      case DayMarker.ovulation:
        fill = fertileColor;
        textColor = Colors.white;
      case DayMarker.predictedPeriod:
        border = periodColor;
      case DayMarker.fertile:
        fill = fertileColor.withValues(alpha: 0.2);
      case DayMarker.logged:
      case DayMarker.none:
        break;
    }
    return Container(
      margin: const EdgeInsets.all(4),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: fill,
        shape: BoxShape.circle,
        border: border != null
            ? Border.all(color: border, width: 2)
            : isToday
                ? Border.all(color: Theme.of(context).colorScheme.outline)
                : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('${day.day}', style: TextStyle(color: textColor, fontWeight: isToday ? FontWeight.bold : null)),
          if (marker == DayMarker.logged)
            Container(width: 4, height: 4, decoration: const BoxDecoration(color: Colors.grey, shape: BoxShape.circle)),
        ],
      ),
    );
  }
}
