class CycleProfile {
  const CycleProfile({
    required this.id,
    required this.ownerUid,
    required this.memberUids,
    required this.name,
    this.defaultCycleLength = 28,
    this.defaultPeriodLength = 5,
  });

  final String id;
  final String ownerUid;
  final List<String> memberUids;
  final String name;
  final int defaultCycleLength;
  final int defaultPeriodLength;

  factory CycleProfile.fromMap(String id, Map<String, dynamic> map) => CycleProfile(
        id: id,
        ownerUid: map['ownerUid'] as String,
        memberUids: List<String>.from(map['memberUids'] as List? ?? const []),
        name: (map['name'] as String?) ?? '',
        defaultCycleLength: (map['defaultCycleLength'] as num?)?.toInt() ?? 28,
        defaultPeriodLength: (map['defaultPeriodLength'] as num?)?.toInt() ?? 5,
      );
}
