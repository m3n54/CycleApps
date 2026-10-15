import 'day_entry.dart';

const flowLabels = <FlowLevel, String>{
  FlowLevel.spotting: 'Bercak',
  FlowLevel.light: 'Ringan',
  FlowLevel.medium: 'Sedang',
  FlowLevel.heavy: 'Berat',
};

const symptomLabels = <Symptom, String>{
  Symptom.cramps: 'Kram',
  Symptom.headache: 'Sakit kepala',
  Symptom.breastTenderness: 'Nyeri payudara',
  Symptom.acne: 'Jerawat',
  Symptom.backache: 'Sakit punggung',
  Symptom.bloating: 'Kembung',
  Symptom.nausea: 'Mual',
};

const moodLabels = <Mood, String>{
  Mood.happy: 'Senang',
  Mood.calm: 'Tenang',
  Mood.sad: 'Sedih',
  Mood.anxious: 'Cemas',
  Mood.irritable: 'Mudah marah',
  Mood.sensitive: 'Sensitif',
};

// Sengaja berbeda dari label flow agar tidak ada teks ganda di layar.
const energyLabels = <Energy, String>{
  Energy.low: 'Lemas',
  Energy.medium: 'Normal',
  Energy.high: 'Bertenaga',
};
