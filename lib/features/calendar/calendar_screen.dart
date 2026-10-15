import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../domain/day_entry.dart';
import '../../state/providers.dart';
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

  void _openDay(DateTime day) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => DayLogScreen(date: day)));
  }

  @override
  Widget build(BuildContext context) {
    final today = ref.watch(todayProvider);
    final entries = ref.watch(dayEntriesProvider).valueOrNull ?? const <DayEntry>[];
    final byDate = {for (final e in entries) e.date: e};
    final prediction = ref.watch(predictionProvider);
    final focused = _focused ?? today;

    Widget cell(DateTime day, {bool isToday = false}) =>
        DayCell(day: day, marker: markerFor(day, byDate, prediction), isToday: isToday);

    return Scaffold(
      appBar: AppBar(title: const Text('Kalender')),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(predictionSummary(prediction, today),
                style: Theme.of(context).textTheme.titleLarge),
          ),
          TableCalendar<void>(
            locale: 'id_ID',
            firstDay: DateTime(2020, 1, 1),
            lastDay: DateTime(today.year + 2, 12, 31),
            focusedDay: focused,
            startingDayOfWeek: StartingDayOfWeek.monday,
            availableCalendarFormats: const {CalendarFormat.month: 'Bulan'},
            onPageChanged: (day) => _focused = day,
            onDaySelected: (selected, newFocused) {
              setState(() => _focused = newFocused);
              _openDay(selected);
            },
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, _) => cell(day),
              todayBuilder: (context, day, _) => cell(day, isToday: true),
            ),
          ),
          const _Legend(),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(cycleDisclaimer, style: TextStyle(fontSize: 12, color: Colors.grey)),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openDay(today),
        icon: const Icon(Icons.edit),
        label: const Text('Catat hari ini'),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    Widget item(Widget dot, String label) =>
        Row(mainAxisSize: MainAxisSize.min, children: [dot, const SizedBox(width: 6), Text(label)]);
    Widget dot({Color? fill, Color? border}) => Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: fill,
            shape: BoxShape.circle,
            border: border != null ? Border.all(color: border, width: 2) : null,
          ),
        );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(spacing: 16, runSpacing: 8, children: [
        item(dot(fill: periodColor), 'Haid'),
        item(dot(border: periodColor), 'Prediksi haid'),
        item(dot(fill: fertileColor.withValues(alpha: 0.2)), 'Masa subur'),
        item(dot(fill: fertileColor), 'Ovulasi'),
      ]),
    );
  }
}
