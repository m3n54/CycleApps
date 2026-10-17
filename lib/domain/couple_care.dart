import 'couple_interaction.dart';
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

  static const List<CustomCoupleSticker> defaultCareStickers = [
    CustomCoupleSticker(
      id: 'default_care_1',
      emoji: '🧸',
      text: 'Puk-puk kepala & peluk eratt 🤗',
      isReply: false,
    ),
    CustomCoupleSticker(
      id: 'default_care_2',
      emoji: '🧋',
      text: 'Boba favorit meluncuurr! 🛵💨',
      isReply: false,
    ),
    CustomCoupleSticker(
      id: 'default_care_3',
      emoji: '💆‍♂️',
      text: 'Sesi pijat punggung & bahu siap! ✨',
      isReply: false,
    ),
    CustomCoupleSticker(
      id: 'default_care_4',
      emoji: '👂',
      text: 'Aku pasang telinga, mau curhat apa sayaang? 🥺',
      isReply: false,
    ),
    CustomCoupleSticker(
      id: 'default_care_5',
      emoji: '🍫',
      text: 'Camilan manis anti-badmood buat kamu 🍫💖',
      isReply: false,
    ),
    CustomCoupleSticker(
      id: 'default_care_6',
      emoji: '🧸',
      text: 'Kompres hangat udah siap di kasur 🛋️',
      isReply: false,
    ),
    CustomCoupleSticker(
      id: 'default_care_7',
      emoji: '💤',
      text: 'Tidur yuk, jangan begadang cantikk 😴',
      isReply: false,
    ),
    CustomCoupleSticker(
      id: 'default_care_8',
      emoji: '🥺',
      text: 'Cepat pulang yaa, kangeen bangett 🥺',
      isReply: false,
    ),
  ];

  static const List<CustomCoupleSticker> defaultReplyStickers = [
    CustomCoupleSticker(
      id: 'default_reply_1',
      emoji: '🧋',
      text: 'Benerannn mawuuuu 🧋✨',
      isReply: true,
    ),
    CustomCoupleSticker(
      id: 'default_reply_2',
      emoji: '🥺',
      text: 'aaaaa mauu ditemenin 🥺👉👈',
      isReply: true,
    ),
    CustomCoupleSticker(
      id: 'default_reply_3',
      emoji: '💖',
      text: 'Loveee youu soo muchh 💖🥹',
      isReply: true,
    ),
    CustomCoupleSticker(
      id: 'default_reply_4',
      emoji: '🥰',
      text: 'Makasih banyaakk sayangkuuu 🥰',
      isReply: true,
    ),
    CustomCoupleSticker(
      id: 'default_reply_5',
      emoji: '🛌',
      text: 'Mode mager parah, usap-usap duluu 🦥',
      isReply: true,
    ),
    CustomCoupleSticker(
      id: 'default_reply_6',
      emoji: '🌸',
      text: 'Hatiku langsung adem denger ini 🌸',
      isReply: true,
    ),
  ];

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
