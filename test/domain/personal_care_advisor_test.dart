import 'package:flutter_test/flutter_test.dart';
import 'package:siklus/domain/cycle_phase.dart';
import 'package:siklus/domain/day_entry.dart';
import 'package:siklus/domain/personal_care_advisor.dart';

void main() {
  group('PersonalCareAdvisor.contextualGreeting', () {
    test('remembers yesterday symptoms and adapts message', () {
      const yesterday = DayEntry(
        date: '2026-10-15',
        symptoms: {Symptom.cramps},
      );
      final greeting = PersonalCareAdvisor.contextualGreeting(
        profileName: 'Nata',
        phase: CyclePhase.menstrual,
        todayEntry: null,
        yesterdayEntry: yesterday,
        isPartner: false,
      );
      expect(greeting.headline, 'Halo, Nata 🌸');
      expect(greeting.message.toLowerCase(), contains('kram'));
    });

    test('uses default headline when owner profileName is empty', () {
      final greeting = PersonalCareAdvisor.contextualGreeting(
        profileName: '   ',
        phase: CyclePhase.follicular,
      );
      expect(greeting.headline, 'Halo, Cantik 🌸');
      expect(greeting.message, isNotEmpty);
    });

    test('acknowledges yesterday heavy mood when no symptoms yesterday', () {
      const yesterday = DayEntry(
        date: '2026-10-15',
        moods: {Mood.sad, Mood.anxious},
      );
      final greeting = PersonalCareAdvisor.contextualGreeting(
        profileName: 'Nata',
        phase: CyclePhase.luteal,
        yesterdayEntry: yesterday,
      );
      expect(greeting.headline, 'Halo, Nata 🌸');
      expect(greeting.message.toLowerCase(), contains('kemarin'));
    });

    test('celebrates positive mood today when yesterday had no symptoms or heavy mood', () {
      const today = DayEntry(
        date: '2026-10-16',
        moods: {Mood.happy},
      );
      final greeting = PersonalCareAdvisor.contextualGreeting(
        profileName: 'Nata',
        phase: CyclePhase.ovulation,
        todayEntry: today,
      );
      expect(greeting.headline, 'Halo, Nata 🌸');
      expect(greeting.message, isNotEmpty);
    });

    test('formats partner greeting with profileName and phase context', () {
      for (final phase in CyclePhase.values) {
        final greeting = PersonalCareAdvisor.contextualGreeting(
          profileName: 'Nata',
          phase: phase,
          isPartner: true,
        );
        expect(greeting.headline, 'Mendampingi Nata 💑');
        expect(greeting.message, isNotEmpty);
      }

      final emptyNamePartner = PersonalCareAdvisor.contextualGreeting(
        profileName: '',
        phase: CyclePhase.menstrual,
        isPartner: true,
      );
      expect(emptyNamePartner.headline, 'Mode Pasangan Siaga 💑');
    });
  });

  group('PersonalCareAdvisor.explainToday', () {
    test('returns hormonal explanation and relief tip when symptoms or moods logged', () {
      const today = DayEntry(
        date: '2026-10-16',
        symptoms: {Symptom.cramps, Symptom.bloating},
        moods: {Mood.sensitive},
      );
      final explanation = PersonalCareAdvisor.explainToday(
        phase: CyclePhase.menstrual,
        todayEntry: today,
      );
      expect(explanation, isNotNull);
      expect(explanation!.title, 'Kenapa Tubuhmu Merasa Begini?');
      expect(explanation.whyItHappens.toLowerCase(), contains('prostaglandin'));
      expect(explanation.quickRelief, isNotEmpty);
    });

    test('handles each individual symptom and mood across phases', () {
      for (final symptom in Symptom.values) {
        final explanation = PersonalCareAdvisor.explainToday(
          phase: CyclePhase.luteal,
          todayEntry: DayEntry(date: '2026-10-16', symptoms: {symptom}),
        );
        expect(explanation, isNotNull);
        expect(explanation!.whyItHappens, isNotEmpty);
        expect(explanation.quickRelief, isNotEmpty);
      }

      for (final mood in Mood.values) {
        final explanation = PersonalCareAdvisor.explainToday(
          phase: CyclePhase.follicular,
          todayEntry: DayEntry(date: '2026-10-16', moods: {mood}),
        );
        expect(explanation, isNotNull);
        expect(explanation!.whyItHappens, isNotEmpty);
        expect(explanation.quickRelief, isNotEmpty);
      }
    });

    test('returns null when todayEntry is null or has no symptoms/moods', () {
      expect(
        PersonalCareAdvisor.explainToday(
          phase: CyclePhase.follicular,
          todayEntry: null,
        ),
        isNull,
      );
      expect(
        PersonalCareAdvisor.explainToday(
          phase: CyclePhase.follicular,
          todayEntry: const DayEntry(date: '2026-10-16'),
        ),
        isNull,
      );
    });
  });

  group('PersonalCareAdvisor.missionsForPhase', () {
    test('returns 3 actionable missions for every phase with exact IDs', () {
      for (final phase in CyclePhase.values) {
        final missions = PersonalCareAdvisor.missionsForPhase(phase);
        expect(missions.length, 3);
        expect(missions.map((m) => m.id).toSet().length, 3);
        for (final m in missions) {
          expect(m.title, isNotEmpty);
          expect(m.subtitle, isNotEmpty);
          expect(m.emoji, isNotEmpty);
        }
      }

      expect(
        PersonalCareAdvisor.missionsForPhase(CyclePhase.menstrual).map((m) => m.id).toList(),
        ['menstrual_warm_drink', 'menstrual_warm_compress', 'menstrual_early_rest'],
      );
      expect(
        PersonalCareAdvisor.missionsForPhase(CyclePhase.follicular).map((m) => m.id).toList(),
        ['follicular_hydration', 'follicular_light_move', 'follicular_protein'],
      );
      expect(
        PersonalCareAdvisor.missionsForPhase(CyclePhase.ovulation).map((m) => m.id).toList(),
        ['ovulation_extra_water', 'ovulation_connect', 'ovulation_antioxidant'],
      );
      expect(
        PersonalCareAdvisor.missionsForPhase(CyclePhase.luteal).map((m) => m.id).toList(),
        ['luteal_less_caffeine', 'luteal_magnesium', 'luteal_mindfulness'],
      );
    });
  });
}
