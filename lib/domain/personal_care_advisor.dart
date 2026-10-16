import 'cycle_phase.dart';
import 'day_entry.dart';
import 'labels.dart';

class ContextualGreeting {
  const ContextualGreeting({
    required this.headline,
    required this.message,
  });

  final String headline;
  final String message;
}

class BodyExplanation {
  const BodyExplanation({
    required this.title,
    required this.whyItHappens,
    required this.quickRelief,
  });

  final String title;
  final String whyItHappens;
  final String quickRelief;
}

class SelfCareMission {
  const SelfCareMission({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.emoji,
  });

  final String id;
  final String title;
  final String subtitle;
  final String emoji;
}

class PersonalCareAdvisor {
  const PersonalCareAdvisor._();

  static ContextualGreeting contextualGreeting({
    required String profileName,
    required CyclePhase phase,
    DayEntry? todayEntry,
    DayEntry? yesterdayEntry,
    bool isPartner = false,
  }) {
    final trimmedName = profileName.trim();

    if (isPartner) {
      final headline = trimmedName.isEmpty
          ? 'Mode Pasangan Siaga 💑'
          : 'Mendampingi $trimmedName 💑';
      final subject = trimmedName.isEmpty ? 'Pasanganmu' : trimmedName;
      final message = switch (phase) {
        CyclePhase.menstrual =>
          '$subject sedang di fase menstruasi hari ini. Perhatian ekstra dan kehangatan darimu sangat berarti untuknya.',
        CyclePhase.follicular =>
          '$subject sedang di fase folikuler dengan energi yang mulai bangkit. Waktu yang pas untuk beraktivitas seru bersama!',
        CyclePhase.ovulation =>
          '$subject sedang berada di puncak masa subur (ovulasi). Pancaran energinya sedang hangat dan siap berbagi cerita.',
        CyclePhase.luteal =>
          '$subject sedang di fase luteal menjelang siklus baru. Sedikit kesabaran ekstra dan pelukan darimu akan membuatnya tenang.',
      };
      return ContextualGreeting(headline: headline, message: message);
    }

    final headline =
        trimmedName.isEmpty ? 'Halo, Cantik' : 'Halo, $trimmedName';

    if (yesterdayEntry != null && yesterdayEntry.symptoms.isNotEmpty) {
      final symptomNames = yesterdayEntry.symptoms
          .map((s) => (symptomLabels[s] ?? s.name).toLowerCase())
          .toList();
      final formattedSymptoms = symptomNames.join(', ');
      return ContextualGreeting(
        headline: headline,
        message:
            'Kemarin kamu sempat merasakan $formattedSymptoms. Semoga hari ini tubuhmu terasa jauh lebih nyaman dan ringan ya!',
      );
    }

    if (yesterdayEntry != null &&
        yesterdayEntry.moods.any(
          (m) =>
              m == Mood.sad ||
              m == Mood.anxious ||
              m == Mood.irritable ||
              m == Mood.sensitive,
        )) {
      final heavyMoods = yesterdayEntry.moods
          .where(
            (m) =>
                m == Mood.sad ||
                m == Mood.anxious ||
                m == Mood.irritable ||
                m == Mood.sensitive,
          )
          .map((m) => (moodLabels[m] ?? m.name).toLowerCase())
          .join(' & ');
      return ContextualGreeting(
        headline: headline,
        message:
            'Kemarin terasa cukup menguras emosi ($heavyMoods). Pelan-pelan saja hari ini, kamu sudah hebat melewati hari kemarin.',
      );
    }

    if (todayEntry != null &&
        todayEntry.moods.any((m) => m == Mood.happy || m == Mood.calm)) {
      return ContextualGreeting(
        headline: headline,
        message:
            'Senang melihat suasana hatimu sedang positif dan tenang hari ini! Nikmati setiap momen berhargamu ya.',
      );
    }

    final defaultMessage = switch (phase) {
      CyclePhase.menstrual =>
        'Tubuhmu sedang bekerja keras di fase menstruasi. Dengarkan sinyal tubuhmu dan jangan ragu beristirahat lebih banyak hari ini.',
      CyclePhase.follicular =>
        'Memasuki fase folikuler, energimu perlahan kembali segar. Hari yang indah untuk memulai langkah kecil yang menyenangkan!',
      CyclePhase.ovulation =>
        'Kamu sedang di fase ovulasi! Energi dan rasa percaya dirimu sedang bersinar hangat hari ini.',
      CyclePhase.luteal =>
        'Di fase luteal ini, wajar jika tubuh mulai meminta tempo yang lebih lambat. Rawat dirimu dengan penuh kelembutan ya.',
    };

    return ContextualGreeting(headline: headline, message: defaultMessage);
  }

  static BodyExplanation? explainToday({
    required CyclePhase phase,
    DayEntry? todayEntry,
  }) {
    if (todayEntry == null ||
        (todayEntry.symptoms.isEmpty && todayEntry.moods.isEmpty)) {
      return null;
    }

    final phaseContext = switch (phase) {
      CyclePhase.menstrual => 'Saat fase menstruasi',
      CyclePhase.follicular => 'Di fase folikuler',
      CyclePhase.ovulation => 'Memasuki masa ovulasi',
      CyclePhase.luteal => 'Di fase luteal',
    };

    final reasons = <String>[];

    if (todayEntry.symptoms.contains(Symptom.cramps)) {
      reasons.add(
        'pelepasan zat prostaglandin memicu kontraksi otot rahim sehingga perut terasa kram',
      );
    }
    if (todayEntry.symptoms.contains(Symptom.bloating)) {
      reasons.add(
        'fluktuasi hormon progesteron membuat tubuh menahan lebih banyak cairan sehingga perut terasa kembung',
      );
    }
    if (todayEntry.symptoms.contains(Symptom.headache)) {
      reasons.add(
        'perubahan kadar estrogen memengaruhi pembuluh darah dan memicu sakit kepala',
      );
    }
    if (todayEntry.symptoms.contains(Symptom.breastTenderness)) {
      reasons.add(
        'lonjakan hormon luteal menstimulasi kelenjar payudara sehingga terasa lebih sensitif atau nyeri',
      );
    }
    if (todayEntry.symptoms.contains(Symptom.acne)) {
      reasons.add(
        'pergeseran rasio hormon memicu peningkatan produksi sebum di kulit yang memunculkan jerawat',
      );
    }
    if (todayEntry.symptoms.contains(Symptom.backache)) {
      reasons.add(
        'ketegangan otot panggul dan jaringan sekitarnya menjalar hingga ke punggung bawah',
      );
    }
    if (todayEntry.symptoms.contains(Symptom.nausea)) {
      reasons.add(
        'sensitivitas pencernaan meningkat akibat dinamika hormon prostaglandin dan progesteron',
      );
    }

    final hasHeavyMood = todayEntry.moods.any(
      (m) =>
          m == Mood.sensitive ||
          m == Mood.irritable ||
          m == Mood.anxious ||
          m == Mood.sad,
    );
    if (hasHeavyMood) {
      reasons.add(
        'fluktuasi serotonin dan hormon siklus membuat respons emosimu terasa lebih peka dari biasanya',
      );
    } else if (todayEntry.moods.isNotEmpty && reasons.isEmpty) {
      reasons.add(
        'keseimbangan hormon siklus dan endorfin alami membantu menjaga suasana hatimu tetap nyaman',
      );
    }

    final whyItHappens = '$phaseContext, ${reasons.join('; selain itu, ')}.';

    final String quickRelief;
    if (todayEntry.symptoms.contains(Symptom.cramps) ||
        todayEntry.symptoms.contains(Symptom.backache)) {
      quickRelief =
          'Coba tempelkan kompres hangat di perut atau punggung bawah selama 15 menit sambil menyeruput teh jahe hangat.';
    } else if (todayEntry.symptoms.contains(Symptom.nausea) ||
        todayEntry.symptoms.contains(Symptom.bloating)) {
      quickRelief =
          'Minum teh chamomile atau air jahe hangat secara perlahan dan hindari makanan tinggi garam untuk meredakan rasa tidak nyaman.';
    } else if (todayEntry.symptoms.contains(Symptom.headache)) {
      quickRelief =
          'Redupkan layar sejenak, minum segelas air putih, dan lakukan pijatan lembut di area pelipis serta leher.';
    } else if (todayEntry.symptoms.contains(Symptom.breastTenderness)) {
      quickRelief =
          'Gunakan pakaian dalam yang longgar tanpa kawat hari ini dan kurangi asupan kafein agar jaringan payudara lebih rileks.';
    } else if (todayEntry.symptoms.contains(Symptom.acne)) {
      quickRelief =
          'Jaga kebersihan wajah dengan pembersih lembut, hindari menyentuh area berjerawat, dan perbanyak minum air putih.';
    } else if (hasHeavyMood) {
      quickRelief =
          'Ambil jeda 5 menit untuk teknik napas 4-7-8 dan beri ruang bagi dirimu untuk beristirahat tanpa rasa bersalah.';
    } else {
      quickRelief =
          'Pertahankan ritme nyaman ini dengan peregangan ringan dan hidrasi yang cukup sepanjang hari.';
    }

    return BodyExplanation(
      title: 'Kenapa Tubuhmu Merasa Begini?',
      whyItHappens: whyItHappens,
      quickRelief: quickRelief,
    );
  }

  static List<SelfCareMission> missionsForPhase(CyclePhase phase) {
    return switch (phase) {
      CyclePhase.menstrual => const [
          SelfCareMission(
            id: 'menstrual_warm_drink',
            emoji: '🍵',
            title: 'Minum air hangat / teh herbal',
            subtitle: 'Membantu merelaksasi otot perut & meredakan kram',
          ),
          SelfCareMission(
            id: 'menstrual_warm_compress',
            emoji: '🧸',
            title: 'Kompres hangat 15 menit',
            subtitle: 'Melancarkan aliran darah di area panggul',
          ),
          SelfCareMission(
            id: 'menstrual_early_rest',
            emoji: '😴',
            title: 'Tidur 30 menit lebih awal',
            subtitle: 'Beri waktu ekstra bagi tubuh untuk pulih',
          ),
        ],
      CyclePhase.follicular => const [
          SelfCareMission(
            id: 'follicular_hydration',
            emoji: '💧',
            title: 'Minum 8 gelas air putih',
            subtitle: 'Jaga hidrasi saat metabolisme mulai naik',
          ),
          SelfCareMission(
            id: 'follicular_light_move',
            emoji: '🏃‍♀️',
            title: 'Gerak aktif 20 menit',
            subtitle: 'Manfaatkan lonjakan energi estrogen hari ini',
          ),
          SelfCareMission(
            id: 'follicular_protein',
            emoji: '🥗',
            title: 'Asupan protein & sayur hijau',
            subtitle: 'Dukung pematangan folikel yang sehat',
          ),
        ],
      CyclePhase.ovulation => const [
          SelfCareMission(
            id: 'ovulation_extra_water',
            emoji: '🍋',
            title: 'Hidrasi ekstra & elektrolit',
            subtitle: 'Suhu basal tubuh sedikit meningkat di masa subur',
          ),
          SelfCareMission(
            id: 'ovulation_connect',
            emoji: '💬',
            title: 'Quality time bersama orang tersayang',
            subtitle: 'Energi sosial & komunikasi sedang di puncaknya',
          ),
          SelfCareMission(
            id: 'ovulation_antioxidant',
            emoji: '🍓',
            title: 'Konsumsi buah tinggi antioksidan',
            subtitle: 'Bantu keseimbangan hormon saat ovulasi',
          ),
        ],
      CyclePhase.luteal => const [
          SelfCareMission(
            id: 'luteal_less_caffeine',
            emoji: '🌿',
            title: 'Kurangi kafein & garam berlebih',
            subtitle: 'Mencegah kembung dan rasa cemas menjelang haid',
          ),
          SelfCareMission(
            id: 'luteal_magnesium',
            emoji: '🍫',
            title: 'Camilan sehat kaya magnesium',
            subtitle: 'Dark chocolate atau kacang bantu stabilkan mood',
          ),
          SelfCareMission(
            id: 'luteal_mindfulness',
            emoji: '🧘‍♀️',
            title: 'Jeda tenang & napas dalam 5 menit',
            subtitle: 'Turunkan hormon kortisol saat tubuh lebih sensitif',
          ),
        ],
    };
  }
}
