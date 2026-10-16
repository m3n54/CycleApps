import 'couple_care.dart';

class CycleProfile {
  const CycleProfile({
    required this.id,
    required this.ownerUid,
    required this.memberUids,
    required this.name,
    this.defaultCycleLength = 28,
    this.defaultPeriodLength = 5,
    this.activeSignal,
    this.signalReaction,
  });

  final String id;
  final String ownerUid;
  final List<String> memberUids;
  final String name;
  final int defaultCycleLength;
  final int defaultPeriodLength;
  final CoupleSignal? activeSignal;
  final PartnerReaction? signalReaction;

  bool isOwner(String? uid) => uid != null && uid == ownerUid;

  bool get hasPartner => memberUids.length > 1;

  factory CycleProfile.fromMap(String id, Map<String, dynamic> map) => CycleProfile(
        id: id,
        ownerUid: map['ownerUid'] as String,
        memberUids: List<String>.from(map['memberUids'] as List? ?? const []),
        name: (map['name'] as String?) ?? '',
        defaultCycleLength: (map['defaultCycleLength'] as num?)?.toInt() ?? 28,
        defaultPeriodLength: (map['defaultPeriodLength'] as num?)?.toInt() ?? 5,
        activeSignal: _enumOrNull(CoupleSignal.values, map['activeSignal']),
        signalReaction: _enumOrNull(PartnerReaction.values, map['signalReaction']),
      );
}

T? _enumOrNull<T extends Enum>(List<T> values, Object? name) {
  for (final v in values) {
    if (v.name == name) return v;
  }
  return null;
}
