import 'cycle_phase.dart';
import 'day_entry.dart';

enum MascotCharacter {
  mochiKitten(
    emoji: '🐱',
    displayName: 'Mochi Kitten',
    tagline: 'Kucing mochi manja & suka dipeluk',
  ),
  fluffyBunny(
    emoji: '🐰',
    displayName: 'Fluffy Bunny',
    tagline: 'Kelinci lembut penuh perhatian',
  ),
  babyDino(
    emoji: '🦕',
    displayName: 'Baby Dino',
    tagline: 'Dino mungil ceria penjaga mood',
  ),
  chibiGirl(
    emoji: '👧',
    displayName: 'Chibi Girl',
    tagline: 'Sahabat ekspresif cerminan hatimu',
  );

  const MascotCharacter({
    required this.emoji,
    required this.displayName,
    required this.tagline,
  });

  final String emoji;
  final String displayName;
  final String tagline;
}

enum MascotMoodState {
  comfyRest(
    badgeEmoji: '🧸',
    statusLabel: 'Mode Istirahat & Kompres Hangat',
  ),
  sparklingHappy(
    badgeEmoji: '✨',
    statusLabel: 'Mode Ceria & Penuh Semangat',
  ),
  glowingLove(
    badgeEmoji: '💖',
    statusLabel: 'Mode Berbinar & Penuh Cinta',
  ),
  cravingPouty(
    badgeEmoji: '🍫',
    statusLabel: 'Mode Manja & Pengen Jajan Manis',
  );

  const MascotMoodState({
    required this.badgeEmoji,
    required this.statusLabel,
  });

  final String badgeEmoji;
  final String statusLabel;
}

class CycleMascotAdvisor {
  const CycleMascotAdvisor._();

  static MascotMoodState resolveMoodState({
    required CyclePhase phase,
    DayEntry? todayEntry,
  }) {
    if (todayEntry != null) {
      if (todayEntry.flow != null ||
          todayEntry.symptoms.contains(Symptom.cramps) ||
          todayEntry.symptoms.contains(Symptom.backache) ||
          todayEntry.energy == Energy.low) {
        return MascotMoodState.comfyRest;
      }
      if (todayEntry.moods.contains(Mood.sensitive) ||
          todayEntry.moods.contains(Mood.anxious) ||
          todayEntry.moods.contains(Mood.irritable) ||
          todayEntry.moods.contains(Mood.sad)) {
        return MascotMoodState.cravingPouty;
      }
      if (todayEntry.moods.contains(Mood.happy) ||
          todayEntry.energy == Energy.high) {
        return MascotMoodState.sparklingHappy;
      }
    }

    switch (phase) {
      case CyclePhase.menstrual:
        return MascotMoodState.comfyRest;
      case CyclePhase.follicular:
        return MascotMoodState.sparklingHappy;
      case CyclePhase.ovulation:
        return MascotMoodState.glowingLove;
      case CyclePhase.luteal:
        return MascotMoodState.cravingPouty;
    }
  }

  static List<String> bubbleMessages({
    required MascotCharacter character,
    required MascotMoodState state,
    required bool isPartner,
    required String partnerName,
  }) {
    final targetName = partnerName.trim().isEmpty ? 'Sayang' : partnerName.trim();
    final prefix = character.emoji;

    if (isPartner) {
      switch (state) {
        case MascotMoodState.comfyRest:
          return [
            '$prefix Psst! $targetName lagi butuh istirahat ekstra & pelukan hangat darimu~',
            '$prefix Jangan lupa tanyain perut $targetName masih kram atau nggak yaa 🧸',
            '$prefix Kirim stiker kompres hangat atau boba pasti bikin $targetName senyum! 💖',
          ];
        case MascotMoodState.sparklingHappy:
          return [
            '$prefix Energi $targetName lagi cerah banget hari ini! Ajak ngobrol seru yuk ✨',
            '$prefix Hari yang pas buat jalan bareng atau kirim pujian manis ke $targetName 🌸',
            '$prefix Mood $targetName lagi bagus, jangan lupa kirim stiker cinta hari ini yaa 💕',
          ];
        case MascotMoodState.glowingLove:
          return [
            '$prefix $targetName lagi di fase paling glowing & penuh cinta! Kirim perhatian yuk 💖',
            '$prefix Waktu terbaik buat quality time romantis bareng $targetName 🥰',
            '$prefix Bilang ke $targetName kalau dia kelihatan cantik banget hari ini! ✨',
          ];
        case MascotMoodState.cravingPouty:
          return [
            '$prefix $targetName lagi mode sensitif & manja, sabar ekstra dan peluk erat yaa 🥺',
            '$prefix Sedia camilan manis atau cokelat buat $targetName biar anti-badmood 🍫',
            '$prefix Kalau $targetName tiba-tiba cemberut, itu hormonnya lagi naik turun~ usap kepalanya ya! 🫂',
          ];
      }
    }

    switch (state) {
      case MascotMoodState.comfyRest:
        return [
          '$prefix Tubuhmu lagi bekerja keras hari ini, rebahan & minum yang hangat dulu yaa 🧸',
          '$prefix Jangan paksakan diri! Minta pelukan atau kompres hangat ke pasanganmu yuk 💕',
          '$prefix Peluk hangat dari ${character.displayName}! Kamu hebat banget hari ini 🌸',
        ];
      case MascotMoodState.sparklingHappy:
        return [
          '$prefix Yay! Energimu lagi bersinar cerah hari ini, semangat jalani harimu yaa ✨',
          '$prefix ${character.displayName} ikut senang lihat aura positifmu hari ini! 🌟',
          '$prefix Jangan lupa bagi senyum manismu ke pasangan di Ruang Pasangan yaa 💌',
        ];
      case MascotMoodState.glowingLove:
        return [
          '$prefix Kamu lagi glowing banget hari ini! Saatnya kirim kode manja ke si dia 💖',
          '$prefix Rasanya hati lagi berbunga-bunga ya? ${character.displayName} siap nemenin kamu! 🥰',
          '$prefix Jangan lupa minum air putih yang cukup biar makin segar seharian ✨',
        ];
      case MascotMoodState.cravingPouty:
        return [
          '$prefix Lagi pengen yang manis-manis atau tiba-tiba baper? Wajar banget kok, sini peluk! 🍫',
          '$prefix Kalau lagi capek atau sensitif, langsung kirim stiker kode ke pasanganmu yaa 🥺',
          '$prefix Tarik napas pelan-pelan... kamu berhak istirahat & dimanja hari ini 🤍',
        ];
    }
  }
}
