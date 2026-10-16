import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/day_entry.dart';
import '../../state/providers.dart';
import 'widgets/cycle_stats_card.dart';
import 'widgets/phase_guide_sheet.dart';
import 'widgets/symptoms_frequency_card.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prediction = ref.watch(predictionProvider);
    final entries =
        ref.watch(dayEntriesProvider).valueOrNull ?? const <DayEntry>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analisis & Insight'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CycleStatsCard(prediction: prediction),
              const SizedBox(height: 16),
              SymptomsFrequencyCard(entries: entries),
              const SizedBox(height: 20),
              const PhaseGuideSheet(),
            ],
          ),
        ],
      ),
    );
  }
}
