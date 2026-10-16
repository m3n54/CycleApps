enum FlowLevel { spotting, light, medium, heavy }

enum Energy { low, medium, high }

enum Symptom { cramps, headache, breastTenderness, acne, backache, bloating, nausea }

enum Mood { happy, calm, sad, anxious, irritable, sensitive }

enum CervicalMucus { dry, sticky, creamy, eggWhite }

enum SexualActivity { none, protected, unprotected, highDrive }

class DayEntry {
  const DayEntry({
    required this.date,
    this.flow,
    this.symptoms = const {},
    this.moods = const {},
    this.energy,
    this.cervicalMucus,
    this.sexualActivity,
    this.selfCareCompleted = const {},
    this.note = '',
    this.updatedBy,
  });

  final String date;
  final FlowLevel? flow;
  final Set<Symptom> symptoms;
  final Set<Mood> moods;
  final Energy? energy;
  final CervicalMucus? cervicalMucus;
  final SexualActivity? sexualActivity;
  final Set<String> selfCareCompleted;
  final String note;
  final String? updatedBy;

  bool get isPeriodDay =>
      flow == FlowLevel.light || flow == FlowLevel.medium || flow == FlowLevel.heavy;

  bool get isEmpty =>
      flow == null &&
      symptoms.isEmpty &&
      moods.isEmpty &&
      energy == null &&
      cervicalMucus == null &&
      sexualActivity == null &&
      selfCareCompleted.isEmpty &&
      note.trim().isEmpty;

  DayEntry copyWith({
    String? date,
    FlowLevel? flow,
    Set<Symptom>? symptoms,
    Set<Mood>? moods,
    Energy? energy,
    CervicalMucus? cervicalMucus,
    SexualActivity? sexualActivity,
    Set<String>? selfCareCompleted,
    String? note,
    String? updatedBy,
  }) =>
      DayEntry(
        date: date ?? this.date,
        flow: flow ?? this.flow,
        symptoms: symptoms ?? this.symptoms,
        moods: moods ?? this.moods,
        energy: energy ?? this.energy,
        cervicalMucus: cervicalMucus ?? this.cervicalMucus,
        sexualActivity: sexualActivity ?? this.sexualActivity,
        selfCareCompleted: selfCareCompleted ?? this.selfCareCompleted,
        note: note ?? this.note,
        updatedBy: updatedBy ?? this.updatedBy,
      );

  /// Tidak memuat updatedBy/updatedAt; keduanya diisi repository.
  Map<String, dynamic> toMap() => {
        'date': date,
        'flow': flow?.name,
        'symptoms': (symptoms.map((s) => s.name).toList()..sort()),
        'moods': (moods.map((m) => m.name).toList()..sort()),
        'energy': energy?.name,
        'cervicalMucus': cervicalMucus?.name,
        'sexualActivity': sexualActivity?.name,
        'selfCareCompleted': (selfCareCompleted.toList()..sort()),
        'note': note,
      };

  factory DayEntry.fromMap(Map<String, dynamic> map) => DayEntry(
        date: map['date'] as String,
        flow: _enumOrNull(FlowLevel.values, map['flow']),
        symptoms: _enumSet(Symptom.values, map['symptoms']),
        moods: _enumSet(Mood.values, map['moods']),
        energy: _enumOrNull(Energy.values, map['energy']),
        cervicalMucus: _enumOrNull(CervicalMucus.values, map['cervicalMucus']),
        sexualActivity: _enumOrNull(SexualActivity.values, map['sexualActivity']),
        selfCareCompleted: _stringSet(map['selfCareCompleted']),
        note: (map['note'] as String?) ?? '',
        updatedBy: map['updatedBy'] as String?,
      );
}

T? _enumOrNull<T extends Enum>(List<T> values, Object? name) {
  for (final v in values) {
    if (v.name == name) return v;
  }
  return null;
}

Set<T> _enumSet<T extends Enum>(List<T> values, Object? raw) {
  if (raw is! List) return <T>{};
  return raw.map((n) => _enumOrNull(values, n)).whereType<T>().toSet();
}

Set<String> _stringSet(Object? raw) {
  if (raw is! List) return <String>{};
  return raw.whereType<String>().toSet();
}
