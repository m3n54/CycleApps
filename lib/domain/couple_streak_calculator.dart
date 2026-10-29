import 'couple_interaction.dart';
import 'date_key.dart';

class CoupleStreakCalculator {
  const CoupleStreakCalculator._();

  /// Menghitung jumlah hari bersama sejak [anniversaryDate] hingga [today] (hari ke-1 dihitung).
  static int? daysTogether({
    required DateTime? anniversaryDate,
    required DateTime today,
  }) {
    if (anniversaryDate == null) return null;
    final diff = daysBetween(anniversaryDate, today);
    if (diff < 0) return 1;
    return diff + 1;
  }

  /// Menghitung berapa hari berturut-turut pasangan saling mengirim perhatian.
  /// Jika hari ini belum ada interaksi tetapi kemarin ada, streak tetap bertahan dari kemarin.
  static int calculateStreak({
    required List<CoupleInteraction> interactions,
    required DateTime today,
  }) {
    if (interactions.isEmpty) return 0;

    final activeDates = <String>{
      for (final item in interactions) dateKey(item.createdAt),
    };

    var cursor = dateOnly(today);
    if (!activeDates.contains(dateKey(cursor))) {
      final yesterday = addDays(cursor, -1);
      if (!activeDates.contains(dateKey(yesterday))) {
        return 0;
      }
      cursor = yesterday;
    }

    var streak = 0;
    while (activeDates.contains(dateKey(cursor))) {
      streak++;
      cursor = addDays(cursor, -1);
    }
    return streak;
  }
}
