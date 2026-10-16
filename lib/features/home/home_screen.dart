import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/cycle_phase_info.dart';
import '../../domain/date_key.dart';
import '../../domain/day_entry.dart';
import '../../state/providers.dart';
import '../../theme/cycle_theme.dart';
import '../log/day_log_screen.dart';
import 'widgets/cycle_dial.dart';
import 'widgets/phase_card.dart';
import 'widgets/today_summary_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String _formatDate(DateTime date) {
    try {
      return DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(date);
    } catch (_) {
      return DateFormat('EEEE, d MMMM yyyy').format(date);
    }
  }

  void _openTodayLog(BuildContext context, DateTime today) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DayLogScreen(date: today),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final today = ref.watch(todayProvider);
    final profile = ref.watch(activeProfileProvider).valueOrNull;
    final entries = ref.watch(dayEntriesProvider).valueOrNull ?? const <DayEntry>[];
    final prediction = ref.watch(predictionProvider);

    final todayKey = dateKey(today);
    DayEntry? todayEntry;
    for (final entry in entries) {
      if (entry.date == todayKey) {
        todayEntry = entry;
        break;
      }
    }

    final phase = prediction.currentPhase(today);
    final phaseInfo = CyclePhaseInfo.forPhase(phase);

    final profileName = profile?.name.trim() ?? '';
    final greeting = profileName.isEmpty ? 'Halo, Cantik' : 'Halo, $profileName';
    final dateSubtitle = _formatDate(today);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Custom Header
              Text(
                dateSubtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                greeting,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 16),

              // Hero Cycle Dial
              Center(
                child: CycleDial(
                  prediction: prediction,
                  today: today,
                ),
              ),
              const SizedBox(height: 16),

              // Prominent Quick Log CTA Button
              Container(
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    colors: [
                      CycleColors.primary,
                      CycleColors.secondary,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: CycleColors.primary.withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () => _openTodayLog(context, today),
                  icon: const Icon(Icons.edit_calendar_rounded, color: Colors.white),
                  label: const Text(
                    'Catat Hari Ini',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Daily Cycle Phase Status Card
              PhaseCard(phaseInfo: phaseInfo),
              const SizedBox(height: 14),

              // Today's Recorded Summary Card
              TodaySummaryCard(entry: todayEntry),
            ],
          ),
        ),
      ),
    );
  }
}
