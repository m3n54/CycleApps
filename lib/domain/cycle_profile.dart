import 'couple_care.dart';
import 'couple_interaction.dart';

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
    this.customStickers = const [],
    this.lastInteraction,
  });

  final String id;
  final String ownerUid;
  final List<String> memberUids;
  final String name;
  final int defaultCycleLength;
  final int defaultPeriodLength;
  final CoupleSignal? activeSignal;
  final PartnerReaction? signalReaction;
  final List<CustomCoupleSticker> customStickers;
  final Map<String, dynamic>? lastInteraction;

  bool isOwner(String? uid) => uid != null && uid == ownerUid;

  bool get hasPartner => memberUids.length > 1;

  CycleProfile copyWith({
    String? id,
    String? ownerUid,
    List<String>? memberUids,
    String? name,
    int? defaultCycleLength,
    int? defaultPeriodLength,
    CoupleSignal? activeSignal,
    PartnerReaction? signalReaction,
    List<CustomCoupleSticker>? customStickers,
    Map<String, dynamic>? lastInteraction,
  }) =>
      CycleProfile(
        id: id ?? this.id,
        ownerUid: ownerUid ?? this.ownerUid,
        memberUids: memberUids ?? this.memberUids,
        name: name ?? this.name,
        defaultCycleLength: defaultCycleLength ?? this.defaultCycleLength,
        defaultPeriodLength: defaultPeriodLength ?? this.defaultPeriodLength,
        activeSignal: activeSignal ?? this.activeSignal,
        signalReaction: signalReaction ?? this.signalReaction,
        customStickers: customStickers ?? this.customStickers,
        lastInteraction: lastInteraction ?? this.lastInteraction,
      );

  factory CycleProfile.fromMap(String id, Map<String, dynamic> map) {
    final rawStickers = map['customStickers'] as List?;
    final customStickers = rawStickers != null
        ? rawStickers
            .whereType<Map>()
            .map((e) => CustomCoupleSticker.fromMap(Map<String, dynamic>.from(e)))
            .toList()
        : const <CustomCoupleSticker>[];

    final rawLastInteraction = map['lastInteraction'];
    final lastInteraction = rawLastInteraction is Map
        ? Map<String, dynamic>.from(rawLastInteraction)
        : null;

    return CycleProfile(
      id: id,
      ownerUid: (map['ownerUid'] as String?) ?? '',
      memberUids: List<String>.from(map['memberUids'] as List? ?? const []),
      name: (map['name'] as String?) ?? '',
      defaultCycleLength: (map['defaultCycleLength'] as num?)?.toInt() ?? 28,
      defaultPeriodLength: (map['defaultPeriodLength'] as num?)?.toInt() ?? 5,
      activeSignal: _enumOrNull(CoupleSignal.values, map['activeSignal']),
      signalReaction: _enumOrNull(PartnerReaction.values, map['signalReaction']),
      customStickers: customStickers,
      lastInteraction: lastInteraction,
    );
  }

  factory CycleProfile.fromDoc(dynamic doc) =>
      CycleProfile.fromMap(doc.id as String, (doc.data() as Map<String, dynamic>?) ?? {});
}

T? _enumOrNull<T extends Enum>(List<T> values, Object? name) {
  for (final v in values) {
    if (v.name == name) return v;
  }
  return null;
}
