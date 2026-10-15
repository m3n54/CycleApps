import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/date_key.dart';
import '../../domain/day_entry.dart';
import '../../domain/labels.dart';
import '../../state/providers.dart';

class DayLogScreen extends ConsumerStatefulWidget {
  const DayLogScreen({super.key, required this.date});
  final DateTime date;

  @override
  ConsumerState<DayLogScreen> createState() => _DayLogScreenState();
}

class _DayLogScreenState extends ConsumerState<DayLogScreen> {
  FlowLevel? _flow;
  final Set<Symptom> _symptoms = {};
  final Set<Mood> _moods = {};
  Energy? _energy;
  final _note = TextEditingController();

  String get _key => dateKey(widget.date);

  @override
  void initState() {
    super.initState();
    final entries = ref.read(dayEntriesProvider).valueOrNull ?? const <DayEntry>[];
    for (final e in entries) {
      if (e.date == _key) {
        _flow = e.flow;
        _symptoms.addAll(e.symptoms);
        _moods.addAll(e.moods);
        _energy = e.energy;
        _note.text = e.note;
        break;
      }
    }
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  void _save() {
    final profileId = ref.read(activeProfileIdProvider).valueOrNull;
    final user = ref.read(authStateProvider).valueOrNull;
    if (profileId == null || user == null) return;
    final entry = DayEntry(
      date: _key,
      flow: _flow,
      symptoms: {..._symptoms},
      moods: {..._moods},
      energy: _energy,
      note: _note.text.trim(),
    );
    // Tidak di-await: saat offline Future baru selesai setelah sinkron.
    unawaited(ref.read(dayRepositoryProvider).saveDay(profileId: profileId, uid: user.uid, entry: entry));
    Navigator.of(context).pop();
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 8),
        child: Text(title, style: Theme.of(context).textTheme.titleMedium),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(DateFormat('EEEE, d MMMM y', 'id_ID').format(widget.date)),
        actions: [TextButton(onPressed: _save, child: const Text('Simpan'))],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _section('Haid'),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final f in FlowLevel.values)
                ChoiceChip(
                  label: Text(flowLabels[f]!),
                  selected: _flow == f,
                  onSelected: (s) => setState(() => _flow = s ? f : null),
                ),
            ]),
            _section('Gejala fisik'),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final s in Symptom.values)
                FilterChip(
                  label: Text(symptomLabels[s]!),
                  selected: _symptoms.contains(s),
                  onSelected: (on) => setState(() => on ? _symptoms.add(s) : _symptoms.remove(s)),
                ),
            ]),
            _section('Mood'),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final m in Mood.values)
                FilterChip(
                  label: Text(moodLabels[m]!),
                  selected: _moods.contains(m),
                  onSelected: (on) => setState(() => on ? _moods.add(m) : _moods.remove(m)),
                ),
            ]),
            _section('Energi'),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final e in Energy.values)
                ChoiceChip(
                  label: Text(energyLabels[e]!),
                  selected: _energy == e,
                  onSelected: (s) => setState(() => _energy = s ? e : null),
                ),
            ]),
            _section('Catatan'),
            TextField(
              key: const Key('note'),
              controller: _note,
              maxLines: 4,
              maxLength: 2000,
              decoration: const InputDecoration(
                hintText: 'Tulis catatan…',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
