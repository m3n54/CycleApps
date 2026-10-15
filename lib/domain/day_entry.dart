enum FlowLevel { spotting, light, medium, heavy }

enum Energy { low, medium, high }

enum Symptom { cramps, headache, breastTenderness, acne, backache, bloating, nausea }

enum Mood { happy, calm, sad, anxious, irritable, sensitive }

class DayEntry {
  const DayEntry({
    required this.date,
    this.flow,
    this.symptoms = const {},
    this.moods = const {},
    this.energy,
    this.note = '',
    this.updatedBy,
  });

  final String date;
  final FlowLevel? flow;
  final Set<Symptom> symptoms;
  final Set<Mood> moods;
  final Energy? energy;
  final String note;
  final String? updatedBy;

  bool get isPeriodDay =>
      flow == FlowLevel.light || flow == FlowLevel.medium || flow == FlowLevel.heavy;

  bool get isEmpty =>
      flow == null && symptoms.isEmpty && moods.isEmpty && energy == null && note.trim().isEmpty;

  /// Tidak memuat updatedBy/updatedAt; keduanya diisi repository.
  Map<String, dynamic> toMap() => {
        'date': date,
        'flow': flow?.name,
        'symptoms': (symptoms.map((s) => s.name).toList()..sort()),
        'moods': (moods.map((m) => m.name).toList()..sort()),
        'energy': energy?.name,
        'note': note,
      };

  factory DayEntry.fromMap(Map<String, dynamic> map) => DayEntry(
        date: map['date'] as String,
        flow: _enumOrNull(FlowLevel.values, map['flow']),
        symptoms: _enumSet(Symptom.values, map['symptoms']),
        moods: _enumSet(Mood.values, map['moods']),
        energy: _enumOrNull(Energy.values, map['energy']),
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
