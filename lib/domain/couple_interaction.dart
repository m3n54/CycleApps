export 'couple_care.dart' show CoupleCareCatalog;

class CustomCoupleSticker {
  const CustomCoupleSticker({
    required this.id,
    required this.emoji,
    required this.text,
    this.isReply = false,
  });

  final String id;
  final String emoji;
  final String text;
  final bool isReply;

  Map<String, dynamic> toMap() => {
        'id': id,
        'emoji': emoji,
        'text': text,
        'isReply': isReply,
      };

  factory CustomCoupleSticker.fromMap(Map<String, dynamic> map) => CustomCoupleSticker(
        id: (map['id'] as String?) ?? '',
        emoji: (map['emoji'] as String?) ?? '',
        text: (map['text'] as String?) ?? '',
        isReply: (map['isReply'] as bool?) ?? false,
      );

  CustomCoupleSticker copyWith({
    String? id,
    String? emoji,
    String? text,
    bool? isReply,
  }) =>
      CustomCoupleSticker(
        id: id ?? this.id,
        emoji: emoji ?? this.emoji,
        text: text ?? this.text,
        isReply: isReply ?? this.isReply,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomCoupleSticker &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          emoji == other.emoji &&
          text == other.text &&
          isReply == other.isReply;

  @override
  int get hashCode => Object.hash(id, emoji, text, isReply);
}

class CoupleInteraction {
  const CoupleInteraction({
    required this.id,
    required this.senderUid,
    required this.senderName,
    required this.emoji,
    required this.text,
    this.customNote,
    this.replyEmoji,
    this.replyText,
    this.repliedAt,
    required this.createdAt,
    this.isRead = false,
  });

  final String id;
  final String senderUid;
  final String senderName;
  final String emoji;
  final String text;
  final String? customNote;
  final String? replyEmoji;
  final String? replyText;
  final DateTime? repliedAt;
  final DateTime createdAt;
  final bool isRead;

  bool get hasReply => replyEmoji != null && replyText != null;

  Map<String, dynamic> toMap() => {
        'senderUid': senderUid,
        'senderName': senderName,
        'emoji': emoji,
        'text': text,
        'customNote': customNote,
        'replyEmoji': replyEmoji,
        'replyText': replyText,
        'repliedAt': repliedAt?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'isRead': isRead,
      };

  factory CoupleInteraction.fromMap(String id, Map<String, dynamic> map) {
    return CoupleInteraction(
      id: id,
      senderUid: (map['senderUid'] as String?) ?? '',
      senderName: (map['senderName'] as String?) ?? '',
      emoji: (map['emoji'] as String?) ?? '',
      text: (map['text'] as String?) ?? '',
      customNote: map['customNote'] as String?,
      replyEmoji: map['replyEmoji'] as String?,
      replyText: map['replyText'] as String?,
      repliedAt: _parseNullableDateTime(map['repliedAt']),
      createdAt: _parseDateTime(map['createdAt']),
      isRead: (map['isRead'] as bool?) ?? false,
    );
  }

  CoupleInteraction copyWith({
    String? id,
    String? senderUid,
    String? senderName,
    String? emoji,
    String? text,
    String? customNote,
    String? replyEmoji,
    String? replyText,
    DateTime? repliedAt,
    DateTime? createdAt,
    bool? isRead,
  }) {
    return CoupleInteraction(
      id: id ?? this.id,
      senderUid: senderUid ?? this.senderUid,
      senderName: senderName ?? this.senderName,
      emoji: emoji ?? this.emoji,
      text: text ?? this.text,
      customNote: customNote ?? this.customNote,
      replyEmoji: replyEmoji ?? this.replyEmoji,
      replyText: replyText ?? this.replyText,
      repliedAt: repliedAt ?? this.repliedAt,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
    );
  }

  static DateTime _parseDateTime(dynamic val) {
    if (val == null) return DateTime.now();
    if (val is DateTime) return val;
    if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
    try {
      return (val as dynamic).toDate() as DateTime;
    } catch (_) {
      return DateTime.now();
    }
  }

  static DateTime? _parseNullableDateTime(dynamic val) {
    if (val == null) return null;
    if (val is DateTime) return val;
    if (val is String) return DateTime.tryParse(val);
    try {
      return (val as dynamic).toDate() as DateTime;
    } catch (_) {
      return null;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoupleInteraction &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          senderUid == other.senderUid &&
          senderName == other.senderName &&
          emoji == other.emoji &&
          text == other.text &&
          customNote == other.customNote &&
          replyEmoji == other.replyEmoji &&
          replyText == other.replyText &&
          repliedAt == other.repliedAt &&
          createdAt == other.createdAt &&
          isRead == other.isRead;

  @override
  int get hashCode => Object.hash(
        id,
        senderUid,
        senderName,
        emoji,
        text,
        customNote,
        replyEmoji,
        replyText,
        repliedAt,
        createdAt,
        isRead,
      );
}
