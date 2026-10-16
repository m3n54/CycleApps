import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/date_key.dart';
import '../../domain/day_entry.dart';
import '../../state/providers.dart';
import '../../theme/cycle_theme.dart';
import 'widgets/category_section.dart';
import 'widgets/selectable_tile.dart';

class DayLogScreen extends ConsumerStatefulWidget {
  const DayLogScreen({super.key, required this.date});
  final DateTime date;

  @override
  ConsumerState<DayLogScreen> createState() => _DayLogScreenState();
}

class _DayLogScreenState extends ConsumerState<DayLogScreen> {
  FlowLevel? _flow;
  Energy? _energy;
  final Set<Mood> _moods = {};
  bool _tiredMood = false;
  final Set<Symptom> _symptoms = {};
  CervicalMucus? _cervicalMucus;
  SexualActivity? _sexualActivity;
  final _note = TextEditingController();

  String get _key => dateKey(widget.date);

  static const _flowOptions = <(FlowLevel, String, IconData)>[
    (FlowLevel.spotting, 'Spotting', Icons.water_drop_outlined),
    (FlowLevel.light, 'Ringan', Icons.water_drop),
    (FlowLevel.medium, 'Sedang', Icons.invert_colors),
    (FlowLevel.heavy, 'Deras', Icons.opacity),
  ];

  static const _energyOptions = <(Energy, String, IconData)>[
    (Energy.low, 'Lemas', Icons.battery_2_bar_rounded),
    (Energy.medium, 'Normal', Icons.battery_5_bar_rounded),
    (Energy.high, 'Bertenaga', Icons.bolt_rounded),
  ];

  static const _moodOptions = <(Mood, String, IconData)>[
    (Mood.happy, 'Senang', Icons.sentiment_very_satisfied),
    (Mood.calm, 'Tenang', Icons.spa),
    (Mood.sensitive, 'Sensitif', Icons.favorite),
    (Mood.sad, 'Sedih', Icons.sentiment_dissatisfied),
    (Mood.anxious, 'Cemas', Icons.mood_bad),
    (Mood.irritable, 'Mudah Marah', Icons.local_fire_department),
  ];

  static const _symptomOptions = <(Symptom, String, IconData)>[
    (Symptom.cramps, 'Kram', Icons.sick_outlined),
    (Symptom.headache, 'Sakit kepala', Icons.psychology),
    (Symptom.breastTenderness, 'Nyeri payudara', Icons.favorite_border),
    (Symptom.acne, 'Jerawat', Icons.face),
    (Symptom.backache, 'Sakit punggung', Icons.airline_seat_recline_normal),
    (Symptom.bloating, 'Kembung', Icons.circle_outlined),
    (Symptom.nausea, 'Mual', Icons.sentiment_very_dissatisfied),
  ];

  static const _cervicalMucusOptions = <(CervicalMucus, String, IconData)>[
    (CervicalMucus.dry, 'Kering', Icons.wb_sunny_outlined),
    (CervicalMucus.sticky, 'Lengket', Icons.water_drop_outlined),
    (CervicalMucus.creamy, 'Krimi', Icons.cloud_outlined),
    (CervicalMucus.eggWhite, 'Bening & Licin', Icons.auto_awesome_outlined),
  ];

  static const _sexualActivityOptions = <(SexualActivity, String, IconData)>[
    (SexualActivity.none, 'Tidak Ada', Icons.do_not_disturb_on_outlined),
    (SexualActivity.protected, 'Dengan Pengaman', Icons.verified_user_outlined),
    (SexualActivity.unprotected, 'Tanpa Pengaman', Icons.favorite_border_rounded),
    (SexualActivity.highDrive, 'Hasrat Tinggi', Icons.local_fire_department_rounded),
  ];

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
        _cervicalMucus = e.cervicalMucus;
        _sexualActivity = e.sexualActivity;
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
      cervicalMucus: _cervicalMucus,
      sexualActivity: _sexualActivity,
      note: _note.text.trim(),
    );
    // Tidak di-await: saat offline Future baru selesai setelah sinkron.
    unawaited(
      ref.read(dayRepositoryProvider).saveDay(
            profileId: profileId,
            uid: user.uid,
            entry: entry,
          ),
    );
    Navigator.of(context).pop();
  }

  void _toggleMood(Mood mood) {
    setState(() {
      if (_moods.contains(mood)) {
        _moods.remove(mood);
      } else {
        _moods.add(mood);
      }
    });
  }

  void _toggleSymptom(Symptom symptom) {
    setState(() {
      if (_symptoms.contains(symptom)) {
        _symptoms.remove(symptom);
      } else {
        _symptoms.add(symptom);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final formattedDate = DateFormat('d MMMM y', 'id_ID').format(widget.date);

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: Text('Catatan $formattedDate'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CategorySection(
              title: 'Aliran Darah',
              subtitle: 'Pilih intensitas haid hari ini',
              icon: Icons.water_drop_rounded,
              accentColor: CycleColors.phaseMenstrual,
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final (level, label, icon) in _flowOptions)
                    SelectableTile(
                      label: label,
                      icon: icon,
                      selected: _flow == level,
                      activeColor: CycleColors.phaseMenstrual,
                      onTap: () => setState(() => _flow = _flow == level ? null : level),
                    ),
                ],
              ),
            ),
            CategorySection(
              title: 'Tingkat Energi',
              subtitle: 'Bagaimana stamina tubuh Anda?',
              icon: Icons.bolt_rounded,
              accentColor: CycleColors.secondary,
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final (energy, label, icon) in _energyOptions)
                    SelectableTile(
                      label: label,
                      icon: icon,
                      selected: _energy == energy,
                      activeColor: CycleColors.secondary,
                      onTap: () => setState(() => _energy = _energy == energy ? null : energy),
                    ),
                ],
              ),
            ),
            CategorySection(
              title: 'Suasana Hati',
              subtitle: 'Bisa pilih lebih dari satu',
              icon: Icons.mood_rounded,
              accentColor: CycleColors.accent,
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final (mood, label, icon) in _moodOptions)
                    SelectableTile(
                      label: label,
                      icon: icon,
                      selected: _moods.contains(mood),
                      activeColor: CycleColors.accent,
                      onTap: () => _toggleMood(mood),
                    ),
                  SelectableTile(
                    label: 'Lelah',
                    icon: Icons.nightlight,
                    selected: _tiredMood,
                    activeColor: CycleColors.accent,
                    onTap: () => setState(() => _tiredMood = !_tiredMood),
                  ),
                ],
              ),
            ),
            CategorySection(
              title: 'Gejala Tubuh',
              subtitle: 'Keluhan fisik yang dirasakan',
              icon: Icons.healing_rounded,
              accentColor: CycleColors.primary,
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final (symptom, label, icon) in _symptomOptions)
                    SelectableTile(
                      label: label,
                      icon: icon,
                      selected: _symptoms.contains(symptom),
                      activeColor: CycleColors.primary,
                      onTap: () => _toggleSymptom(symptom),
                    ),
                ],
              ),
            ),
            CategorySection(
              title: 'Cairan Serviks',
              subtitle: 'Indikator alami masa subur',
              icon: Icons.opacity_rounded,
              accentColor: CycleColors.phaseFollicular,
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final (mucus, label, icon) in _cervicalMucusOptions)
                    SelectableTile(
                      label: label,
                      icon: icon,
                      selected: _cervicalMucus == mucus,
                      activeColor: CycleColors.phaseFollicular,
                      onTap: () => setState(
                        () => _cervicalMucus = _cervicalMucus == mucus ? null : mucus,
                      ),
                    ),
                ],
              ),
            ),
            CategorySection(
              title: 'Aktivitas Seksual',
              subtitle: 'Catatan keintiman harian',
              icon: Icons.favorite_rounded,
              accentColor: CycleColors.phaseLuteal,
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final (activity, label, icon) in _sexualActivityOptions)
                    SelectableTile(
                      label: label,
                      icon: icon,
                      selected: _sexualActivity == activity,
                      activeColor: CycleColors.phaseLuteal,
                      onTap: () => setState(
                        () => _sexualActivity = _sexualActivity == activity ? null : activity,
                      ),
                    ),
                ],
              ),
            ),
            CategorySection(
              title: 'Catatan Harian',
              subtitle: 'Jurnal pribadi Anda',
              icon: Icons.edit_note_rounded,
              accentColor: CycleColors.primary,
              child: TextField(
                key: const Key('note'),
                controller: _note,
                maxLines: 4,
                maxLength: 2000,
                decoration: InputDecoration(
                  hintText: 'Ceritakan bagaimana perasaan dan kondisi Anda hari ini...',
                  filled: true,
                  fillColor: isDark ? CycleColors.backgroundDark : CycleColors.backgroundLight,
                  contentPadding: const EdgeInsets.all(14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: isDark ? CycleColors.borderDark : CycleColors.borderLight,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: isDark ? CycleColors.borderDark : CycleColors.borderLight,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: CycleColors.primary,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(
          color: isDark ? CycleColors.surfaceDark : CycleColors.surfaceLight,
          border: Border(
            top: BorderSide(
              color: isDark ? CycleColors.borderDark : CycleColors.borderLight,
            ),
          ),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 52,
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _save,
              style: FilledButton.styleFrom(
                backgroundColor: CycleColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              icon: const Icon(Icons.check_circle_outline_rounded, size: 20),
              label: const Text('Simpan Catatan'),
            ),
          ),
        ),
      ),
    );
  }
}
