import 'couple_care.dart';
import 'couple_interaction.dart';
import 'cycle_mascot.dart';

class CycleProfile {
  const CycleProfile({
    required this.id,
    required this.ownerUid,
    required this.memberUids,
    required this.name,
    this.partnerName = '',
    this.defaultCycleLength = 28,
    this.defaultPeriodLength = 5,
    this.activeSignal,
    this.signalReaction,
    this.customStickers = const [],
    this.lastInteraction,
    this.selectedMascot = MascotCharacter.mochiKitten,
    this.anniversaryDate,
  });

  final String id;
  final String ownerUid;
  final List<String> memberUids;
  final String name;
  final String partnerName;
  final int defaultCycleLength;
  final int defaultPeriodLength;
  final CoupleSignal? activeSignal;
  final PartnerReaction? signalReaction;
  final List<CustomCoupleSticker> customStickers;
  final Map<String, dynamic>? lastInteraction;
  final MascotCharacter selectedMascot;
  final DateTime? anniversaryDate;

  bool isOwner(String? uid) => uid != null && uid == ownerUid;

  bool get hasPartner => memberUids.length > 1;

  CycleProfile copyWith({
    String? id,
    String? ownerUid,
    List<String>? memberUids,
    String? name,
    String? partnerName,
    int? defaultCycleLength,
    int? defaultPeriodLength,
    CoupleSignal? activeSignal,
    PartnerReaction? signalReaction,
    List<CustomCoupleSticker>? customStickers,
    Map<String, dynamic>? lastInteraction,
    MascotCharacter? selectedMascot,
    DateTime? anniversaryDate,
  }) =>
      CycleProfile(
        id: id ?? this.id,
        ownerUid: ownerUid ?? this.ownerUid,
        memberUids: memberUids ?? this.memberUids,
        name: name ?? this.name,
        partnerName: partnerName ?? this.partnerName,
        defaultCycleLength: defaultCycleLength ?? this.defaultCycleLength,
        defaultPeriodLength: defaultPeriodLength ?? this.defaultPeriodLength,
        activeSignal: activeSignal ?? this.activeSignal,
        signalReaction: signalReaction ?? this.signalReaction,
        customStickers: customStickers ?? this.customStickers,
        lastInteraction: lastInteraction ?? this.lastInteraction,
        selectedMascot: selectedMascot ?? this.selectedMascot,
        anniversaryDate: anniversaryDate ?? this.anniversaryDate,
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

    DateTime? parsedAnniversary;
    final rawAnniversary = map['anniversaryDate'];
    if (rawAnniversary is String && rawAnniversary.isNotEmpty) {
      parsedAnniversary = DateTime.tryParse(rawAnniversary);
    } else if (rawAnniversary is DateTime) {
      parsedAnniversary = rawAnniversary;
    } else {
      try {
        parsedAnniversary = (rawAnniversary as dynamic)?.toDate() as DateTime?;
      } catch (_) {
        parsedAnniversary = null;
      }
    }

    return CycleProfile(
      id: id,
      ownerUid: (map['ownerUid'] as String?) ?? '',
      memberUids: List<String>.from(map['memberUids'] as List? ?? const []),
      name: (map['name'] as String?) ?? '',
      partnerName: (map['partnerName'] as String?) ?? '',
      defaultCycleLength: (map['defaultCycleLength'] as num?)?.toInt() ?? 28,
      defaultPeriodLength: (map['defaultPeriodLength'] as num?)?.toInt() ?? 5,
      activeSignal: _enumOrNull(CoupleSignal.values, map['activeSignal']),
      signalReaction: _enumOrNull(PartnerReaction.values, map['signalReaction']),
      customStickers: customStickers,
      lastInteraction: lastInteraction,
      selectedMascot: _enumOrNull(MascotCharacter.values, map['selectedMascot']) ??
          MascotCharacter.mochiKitten,
      anniversaryDate: parsedAnniversary,
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
