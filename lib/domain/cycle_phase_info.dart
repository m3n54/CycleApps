import 'cycle_phase.dart';

class CyclePhaseInfo {
  const CyclePhaseInfo({
    required this.phase,
    required this.title,
    required this.subtitle,
    required this.hormoneDescription,
    required this.energyLevel,
    required this.workoutRecommendation,
    required this.nutritionRecommendation,
  });

  final CyclePhase phase;
  final String title;
  final String subtitle;
  final String hormoneDescription;
  final String energyLevel;
  final String workoutRecommendation;
  final String nutritionRecommendation;

  static CyclePhaseInfo forPhase(CyclePhase phase) {
    switch (phase) {
      case CyclePhase.menstrual:
        return const CyclePhaseInfo(
          phase: CyclePhase.menstrual,
          title: 'Fase Menstruasi',
          subtitle: 'Waktu Istirahat & Pemulihan',
          hormoneDescription: 'Kadar estrogen dan progesteron berada di titik terendah.',
          energyLevel: 'Rendah - Sedang',
          workoutRecommendation: 'Yoga lembut, jalan santai, peregangan ringan.',
          nutritionRecommendation: 'Makanan kaya zat besi, sup hangat, teh herbal jahe.',
        );
      case CyclePhase.follicular:
        return const CyclePhaseInfo(
          phase: CyclePhase.follicular,
          title: 'Fase Folikular',
          subtitle: 'Energi Baru & Optimisme',
          hormoneDescription: 'Estrogen mulai meningkat, folikel indung telur berkembang.',
          energyLevel: 'Tinggi & Segar',
          workoutRecommendation: 'Latihan beban ringan, kardio dinamis, hiking.',
          nutritionRecommendation: 'Sayuran berdaun hijau, buah berry, protein tanpa lemak.',
        );
      case CyclePhase.ovulation:
        return const CyclePhaseInfo(
          phase: CyclePhase.ovulation,
          title: 'Fase Ovulasi',
          subtitle: 'Masa Subur & Percaya Diri Puncak',
          hormoneDescription: 'Lonjakan hormon LH dan estrogen mencapai puncaknya.',
          energyLevel: 'Sangat Tinggi / Maksimal',
          workoutRecommendation: 'HIIT, lari intensif, kelas tari atau kekuatan penuh.',
          nutritionRecommendation: 'Makanan kaya antioksidan, serat, asam lemak omega-3.',
        );
      case CyclePhase.luteal:
        return const CyclePhaseInfo(
          phase: CyclePhase.luteal,
          title: 'Fase Luteal',
          subtitle: 'Persiapan Tubuh & Self-Care',
          hormoneDescription: 'Progesteron mendominasi dan kemudian perlahan menurun.',
          energyLevel: 'Menurun bertahap',
          workoutRecommendation: 'Pilates, renang santai, latihan kekuatan ritme lambat.',
          nutritionRecommendation: 'Karbohidrat kompleks, magnesium (dark chocolate), alpukat.',
        );
    }
  }
}
