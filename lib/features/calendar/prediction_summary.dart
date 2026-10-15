import '../../domain/cycle_predictor.dart';

const cycleDisclaimer =
    'Prediksi hanya perkiraan berdasarkan riwayat, bukan alat kontrasepsi atau diagnosis medis.';

String predictionSummary(CyclePrediction prediction, DateTime today) {
  final days = prediction.daysUntilNext(today);
  if (days == null) return 'Catat haid pertama untuk melihat prediksi.';
  if (days > 0) return 'Haid berikutnya dalam $days hari';
  if (days == 0) return 'Haid diperkirakan mulai hari ini';
  return 'Haid terlambat ${-days} hari';
}
