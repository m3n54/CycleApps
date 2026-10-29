import 'package:flutter_test/flutter_test.dart';
import 'package:siklus/domain/couple_interaction.dart';
import 'package:siklus/domain/couple_streak_calculator.dart';
import 'package:siklus/domain/cycle_mascot.dart';
import 'package:siklus/domain/cycle_phase.dart';
import 'package:siklus/domain/cycle_profile.dart';
import 'package:siklus/domain/day_entry.dart';

void main() {
  group('CycleMascotAdvisor', () {
    test('resolves comfyRest during menstrual phase or cramps symptom', () {
      expect(
        CycleMascotAdvisor.resolveMoodState(
          phase: CyclePhase.menstrual,
          todayEntry: null,
        ),
        MascotMoodState.comfyRest,
      );

      expect(
        CycleMascotAdvisor.resolveMoodState(
          phase: CyclePhase.follicular,
          todayEntry: const DayEntry(
            date: '2026-10-29',
            symptoms: {Symptom.cramps},
          ),
        ),
        MascotMoodState.comfyRest,
      );
    });

    test('resolves cravingPouty on luteal phase or sensitive/sad mood', () {
      expect(
        CycleMascotAdvisor.resolveMoodState(
          phase: CyclePhase.luteal,
          todayEntry: null,
        ),
        MascotMoodState.cravingPouty,
      );

      expect(
        CycleMascotAdvisor.resolveMoodState(
          phase: CyclePhase.follicular,
          todayEntry: const DayEntry(
            date: '2026-10-29',
            moods: {Mood.sensitive},
          ),
        ),
        MascotMoodState.cravingPouty,
      );
    });

    test('returns non-empty owner and partner bubble messages for all characters', () {
      for (final character in MascotCharacter.values) {
        final ownerQuotes = CycleMascotAdvisor.bubbleMessages(
          character: character,
          state: MascotMoodState.glowingLove,
          isPartner: false,
          partnerName: 'Nata',
        );
        final partnerQuotes = CycleMascotAdvisor.bubbleMessages(
          character: character,
          state: MascotMoodState.comfyRest,
          isPartner: true,
          partnerName: 'Nata',
        );
        expect(ownerQuotes.length, greaterThanOrEqualTo(3));
        expect(partnerQuotes.length, greaterThanOrEqualTo(3));
        expect(partnerQuotes.first, contains('Nata'));
      }
    });
  });

  group('CoupleStreakCalculator', () {
    test('calculates daysTogether accurately including day 1', () {
      final today = DateTime(2026, 10, 29);
      expect(
        CoupleStreakCalculator.daysTogether(
          anniversaryDate: DateTime(2026, 10, 20),
          today: today,
        ),
        10,
      );
      expect(
        CoupleStreakCalculator.daysTogether(
          anniversaryDate: null,
          today: today,
        ),
        isNull,
      );
    });

    test('calculates consecutive care streak across days', () {
      final today = DateTime(2026, 10, 29, 14, 0);
      final interactions = [
        CoupleInteraction(
          id: '1',
          senderUid: 'u1',
          senderName: 'Nata',
          emoji: '🧋',
          text: 'Boba',
          createdAt: DateTime(2026, 10, 29, 10, 0),
          isRead: false,
        ),
        CoupleInteraction(
          id: '2',
          senderUid: 'u2',
          senderName: 'Menza',
          emoji: '🧸',
          text: 'Peluk',
          createdAt: DateTime(2026, 10, 28, 20, 0),
          isRead: true,
        ),
        CoupleInteraction(
          id: '3',
          senderUid: 'u1',
          senderName: 'Nata',
          emoji: '🍫',
          text: 'Cokelat',
          createdAt: DateTime(2026, 10, 27, 9, 0),
          isRead: true,
        ),
      ];

      expect(
        CoupleStreakCalculator.calculateStreak(
          interactions: interactions,
          today: today,
        ),
        3,
      );
    });

    test('preserves streak if no interaction today yet but yesterday had one', () {
      final today = DateTime(2026, 10, 29, 8, 0);
      final interactions = [
        CoupleInteraction(
          id: '1',
          senderUid: 'u2',
          senderName: 'Menza',
          emoji: '🧸',
          text: 'Peluk',
          createdAt: DateTime(2026, 10, 28, 21, 0),
          isRead: true,
        ),
        CoupleInteraction(
          id: '2',
          senderUid: 'u1',
          senderName: 'Nata',
          emoji: '🍫',
          text: 'Cokelat',
          createdAt: DateTime(2026, 10, 27, 15, 0),
          isRead: true,
        ),
      ];

      expect(
        CoupleStreakCalculator.calculateStreak(
          interactions: interactions,
          today: today,
        ),
        2,
      );
    });
  });

  group('CycleProfile new fields serialization', () {
    test('parses selectedMascot, partnerName, and anniversaryDate from map', () {
      final profile = CycleProfile.fromMap('p1', {
        'ownerUid': 'u1',
        'memberUids': ['u1', 'u2'],
        'name': 'Nata',
        'partnerName': 'Menza',
        'selectedMascot': 'fluffyBunny',
        'anniversaryDate': '2025-02-14',
      });

      expect(profile.partnerName, 'Menza');
      expect(profile.selectedMascot, MascotCharacter.fluffyBunny);
      expect(profile.anniversaryDate, DateTime(2025, 2, 14));
    });
  });
}
