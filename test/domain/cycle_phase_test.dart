import 'package:flutter_test/flutter_test.dart';
import 'package:siklus/domain/cycle_phase.dart';
import 'package:siklus/domain/cycle_phase_info.dart';
import 'package:siklus/domain/cycle_predictor.dart';
import 'package:siklus/domain/day_entry.dart';

void main() {
  group('CyclePredictor cycleDayNumber and currentPhase', () {
    test('returns null cycleDayNumber and luteal phase when periods is empty', () {
      final prediction = CyclePredictor.predict(
        entries: const [],
        today: DateTime(2026, 10, 15),
      );
      expect(prediction.cycleDayNumber(DateTime(2026, 10, 15)), isNull);
      expect(prediction.currentPhase(DateTime(2026, 10, 15)), CyclePhase.luteal);
    });

    test('returns null cycleDayNumber when today is before last period start', () {
      final entries = [
        const DayEntry(date: '2026-10-05', flow: FlowLevel.medium),
      ];
      final prediction = CyclePredictor.predict(
        entries: entries,
        today: DateTime(2026, 10, 5),
      );
      expect(prediction.cycleDayNumber(DateTime(2026, 10, 4)), isNull);
      expect(prediction.cycleDayNumber(DateTime(2026, 10, 5)), 1);
    });

    test('accurately identifies cycle day number and all 4 cycle phases', () {
      // Period: 2026-10-01 to 2026-10-03 (3 days)
      // Cycle: 28 days -> next period: 2026-10-29
      // Ovulation: 2026-10-15 (lutealDays = 14)
      // Fertile: 2026-10-10 to 2026-10-16
      final entries = [
        const DayEntry(date: '2026-10-01', flow: FlowLevel.medium),
        const DayEntry(date: '2026-10-02', flow: FlowLevel.medium),
        const DayEntry(date: '2026-10-03', flow: FlowLevel.light),
      ];
      final prediction = CyclePredictor.predict(
        entries: entries,
        today: DateTime(2026, 10, 15),
      );

      // Menstrual phase (Oct 1 - Oct 3)
      expect(prediction.cycleDayNumber(DateTime(2026, 10, 1)), 1);
      expect(prediction.currentPhase(DateTime(2026, 10, 1)), CyclePhase.menstrual);
      expect(prediction.cycleDayNumber(DateTime(2026, 10, 3)), 3);
      expect(prediction.currentPhase(DateTime(2026, 10, 3)), CyclePhase.menstrual);

      // Follicular phase (Oct 4 - Oct 9)
      expect(prediction.cycleDayNumber(DateTime(2026, 10, 4)), 4);
      expect(prediction.currentPhase(DateTime(2026, 10, 4)), CyclePhase.follicular);
      expect(prediction.cycleDayNumber(DateTime(2026, 10, 7)), 7);
      expect(prediction.currentPhase(DateTime(2026, 10, 7)), CyclePhase.follicular);
      expect(prediction.cycleDayNumber(DateTime(2026, 10, 9)), 9);
      expect(prediction.currentPhase(DateTime(2026, 10, 9)), CyclePhase.follicular);

      // Ovulation / Fertile phase (Oct 10 - Oct 16)
      expect(prediction.cycleDayNumber(DateTime(2026, 10, 10)), 10);
      expect(prediction.currentPhase(DateTime(2026, 10, 10)), CyclePhase.ovulation);
      expect(prediction.cycleDayNumber(DateTime(2026, 10, 15)), 15);
      expect(prediction.currentPhase(DateTime(2026, 10, 15)), CyclePhase.ovulation);
      expect(prediction.cycleDayNumber(DateTime(2026, 10, 16)), 16);
      expect(prediction.currentPhase(DateTime(2026, 10, 16)), CyclePhase.ovulation);

      // Luteal phase (Oct 17 - Oct 28)
      expect(prediction.cycleDayNumber(DateTime(2026, 10, 17)), 17);
      expect(prediction.currentPhase(DateTime(2026, 10, 17)), CyclePhase.luteal);
      expect(prediction.cycleDayNumber(DateTime(2026, 10, 22)), 22);
      expect(prediction.currentPhase(DateTime(2026, 10, 22)), CyclePhase.luteal);
    });
  });

  group('CyclePhaseInfo', () {
    test('provides complete wellness info for all phases', () {
      for (final phase in CyclePhase.values) {
        final info = CyclePhaseInfo.forPhase(phase);
        expect(info.phase, phase);
        expect(info.title, isNotEmpty);
        expect(info.subtitle, isNotEmpty);
        expect(info.hormoneDescription, isNotEmpty);
        expect(info.energyLevel, isNotEmpty);
        expect(info.workoutRecommendation, isNotEmpty);
        expect(info.nutritionRecommendation, isNotEmpty);
      }

      final menstrual = CyclePhaseInfo.forPhase(CyclePhase.menstrual);
      expect(menstrual.title, 'Fase Menstruasi');
      expect(menstrual.subtitle, 'Waktu Istirahat & Pemulihan');

      final follicular = CyclePhaseInfo.forPhase(CyclePhase.follicular);
      expect(follicular.title, 'Fase Folikular');
      expect(follicular.subtitle, 'Energi Baru & Optimisme');

      final ovulation = CyclePhaseInfo.forPhase(CyclePhase.ovulation);
      expect(ovulation.title, 'Fase Ovulasi');
      expect(ovulation.subtitle, 'Masa Subur & Percaya Diri Puncak');

      final luteal = CyclePhaseInfo.forPhase(CyclePhase.luteal);
      expect(luteal.title, 'Fase Luteal');
      expect(luteal.subtitle, 'Persiapan Tubuh & Self-Care');
    });
  });
}
