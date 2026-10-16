import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../domain/date_key.dart';
import '../../domain/day_entry.dart';
import '../../domain/labels.dart';
import '../../state/providers.dart';
import '../../theme/cycle_theme.dart';
import '../log/day_log_screen.dart';
import 'day_marker.dart';
import 'prediction_summary.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime? _focused;
  DateTime? _selected;

  void _openDay(DateTime day) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => DayLogScreen(date: day)),
    );
  }

  String _formatDate(DateTime date) {
    try {
      return DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(date);
    } catch (_) {
      return DateFormat('yyyy-MM-dd').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final today = ref.watch(todayProvider);
    final entries = ref.watch(dayEntriesProvider).valueOrNull ?? const <DayEntry>[];
    final byDate = {for (final e in entries) e.date: e};
    final prediction = ref.watch(predictionProvider);
    final focused = _focused ?? today;
    final selectedDay = _selected ?? today;
    final selectedEntry = byDate[dateKey(selectedDay)];

    Widget cell(DateTime day, {bool isToday = false}) =>
        DayCell(day: day, marker: markerFor(day, byDate, prediction), isToday: isToday);

    return Scaffold(
      appBar: AppBar(title: const Text('Kalender Siklus')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          // Prediction Summary Banner Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [
                        CycleColors.surfaceDark,
                        CycleColors.phaseMenstrual.withValues(alpha: 0.15),
                      ]
                    : [
                        const Color(0xFFFFF1F5),
                        const Color(0xFFFDF2F8),
                      ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? CycleColors.borderDark : CycleColors.borderLight,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: CycleColors.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: CycleColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    predictionSummary(prediction, today),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Calendar Card
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              child: TableCalendar<void>(
                locale: 'id_ID',
                firstDay: DateTime(2020, 1, 1),
                lastDay: DateTime(today.year + 2, 12, 31),
                focusedDay: focused,
                selectedDayPredicate: (day) => isSameDay(day, selectedDay),
                startingDayOfWeek: StartingDayOfWeek.monday,
                availableCalendarFormats: const {CalendarFormat.month: 'Bulan'},
                headerStyle: HeaderStyle(
                  titleCentered: true,
                  formatButtonVisible: false,
                  titleTextStyle: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ) ??
                      const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                onPageChanged: (day) => setState(() => _focused = day),
                onDaySelected: (selected, newFocused) {
                  setState(() {
                    _selected = selected;
                    _focused = newFocused;
                  });
                  _openDay(selected);
                },
                calendarBuilders: CalendarBuilders(
                  defaultBuilder: (context, day, _) => cell(day),
                  todayBuilder: (context, day, _) => cell(day, isToday: true),
                  selectedBuilder: (context, day, _) =>
                      cell(day, isToday: isSameDay(day, today)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Legend Pills
          const _Legend(),
          const SizedBox(height: 16),

          // Selected Day Detail Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          _formatDate(selectedDay),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => _openDay(selectedDay),
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: const Text('Catat / Edit'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (selectedEntry == null || selectedEntry.isEmpty)
                    Text(
                      'Belum ada catatan pada tanggal ini.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        if (selectedEntry.flow != null)
                          Chip(
                            label: Text('Aliran: ${flowLabels[selectedEntry.flow!]}'),
                            visualDensity: VisualDensity.compact,
                          ),
                        for (final s in selectedEntry.symptoms)
                          Chip(
                            label: Text(symptomLabels[s] ?? s.name),
                            visualDensity: VisualDensity.compact,
                          ),
                        for (final m in selectedEntry.moods)
                          Chip(
                            label: Text(moodLabels[m] ?? m.name),
                            visualDensity: VisualDensity.compact,
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ),

          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              cycleDisclaimer,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: CycleColors.primary,
        foregroundColor: Colors.white,
        onPressed: () => _openDay(today),
        icon: const Icon(Icons.edit_calendar_rounded),
        label: const Text('Catat hari ini'),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    Widget pill(Widget dot, String label) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark
                  ? CycleColors.borderDark
                  : CycleColors.borderLight,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              dot,
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        );

    Widget dot({Color? fill, Color? border}) => Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: fill,
            shape: BoxShape.circle,
            border: border != null ? Border.all(color: border, width: 2) : null,
          ),
        );

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        pill(dot(fill: periodColor), 'Haid'),
        pill(dot(border: periodColor), 'Prediksi haid'),
        pill(dot(fill: fertileColor.withValues(alpha: 0.25)), 'Masa subur'),
        pill(dot(fill: fertileColor), 'Ovulasi'),
      ],
    );
  }
}
