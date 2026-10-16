import 'cycle_phase.dart';

enum CoupleSignal {
  cravingSweet,
  needHug,
  needRest,
  sensitiveMood,
  qualityTime,
}

enum PartnerReaction {
  hugSent,
  onTheWay,
  takeRest,
  hereForYou,
}

class PartnerPhaseTip {
  const PartnerPhaseTip({
    required this.phase,
    required this.title,
    required this.bodyCondition,
    required this.actionSuggestion,
  });

  final CyclePhase phase;
  final String title;
  final String bodyCondition;
  final String actionSuggestion;
}

class CoupleCareCatalog {
  const CoupleCareCatalog._();

  static String signalLabel(CoupleSignal signal) {
    switch (signal) {
      case CoupleSignal.cravingSweet:
        return 'Pengen yang manis 🍫';
      case CoupleSignal.needHug:
        return 'Butuh pelukan hangat 🫂';
      case CoupleSignal.needRest:
        return 'Lagi kram, butuh istirahat 🛌';
      case CoupleSignal.sensitiveMood:
        return 'Mood lagi sensitif 🥺';
      case CoupleSignal.qualityTime:
        return 'Pengen ditemenin ngobrol 💬';
    }
  }

  static String reactionLabel(PartnerReaction reaction) {
    switch (reaction) {
      case PartnerReaction.hugSent:
        return 'Peluk hangat dikirim! ❤️';
      case PartnerReaction.onTheWay:
        return 'Siap, meluncur bawain! 🛵🍫';
      case PartnerReaction.takeRest:
        return 'Istirahat yang nyaman ya sayang 🤍';
      case PartnerReaction.hereForYou:
        return 'Aku siap nemenin kamu kapan aja ✨';
    }
  }

  static PartnerPhaseTip partnerTipForPhase(CyclePhase phase) {
    switch (phase) {
      case CyclePhase.menstrual:
        return const PartnerPhaseTip(
          phase: CyclePhase.menstrual,
          title: 'Fase Menstruasi: Waktu Terbaik Memberi Kenyamanan Ekstra',
          bodyCondition:
              'Energi sedang di titik terendah dan perut mungkin terasa kram atau pegal.',
          actionSuggestion:
              'Tawarkan minuman hangat, bantu pekerjaan rumah ringan, dan biarkan dia beristirahat lebih awal.',
        );
      case CyclePhase.follicular:
        return const PartnerPhaseTip(
          phase: CyclePhase.follicular,
          title: 'Fase Folikuler: Energi & Semangat Kembali Bangkit',
          bodyCondition:
              'Hormon estrogen mulai naik sehingga suasana hati lebih cerah dan rasa ingin tahu meningkat.',
          actionSuggestion:
              'Ajak mencoba tempat makan baru, jalan santai, atau rencanakan aktivitas seru berdua.',
        );
      case CyclePhase.ovulation:
        return const PartnerPhaseTip(
          phase: CyclePhase.ovulation,
          title: 'Fase Ovulasi: Puncak Kepercayaan Diri & Koneksi',
          bodyCondition:
              'Energi sosial dan rasa percaya diri sedang tinggi, waktu yang hangat untuk kedekatan emosional.',
          actionSuggestion:
              'Berikan pujian tulus, luangkan quality time tanpa gangguan gadget, atau kencan romantis.',
        );
      case CyclePhase.luteal:
        return const PartnerPhaseTip(
          phase: CyclePhase.luteal,
          title: 'Fase Luteal: Butuh Pengertian & Ruang Tenang',
          bodyCondition:
              'Perubahan hormon menjelang haid bisa memicu lelah, kembung, atau emosi yang lebih sensitif.',
          actionSuggestion:
              'Jadilah pendengar yang sabar tanpa buru-buru menghakimi, dan siapkan camilan favoritnya.',
        );
    }
  }
}
