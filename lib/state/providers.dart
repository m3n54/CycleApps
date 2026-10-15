import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_repository.dart';
import '../data/day_repository.dart';
import '../data/profile_repository.dart';
import '../domain/cycle_predictor.dart';
import '../domain/cycle_profile.dart';
import '../domain/date_key.dart';
import '../domain/day_entry.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);
final firestoreProvider = Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);

/// Di-override di test. Catatan: tidak otomatis berganti saat lewat tengah malam (cukup untuk MVP).
final todayProvider = Provider<DateTime>((ref) => dateOnly(DateTime.now()));

final authRepositoryProvider =
    Provider<AuthRepository>((ref) => AuthRepository(ref.watch(firebaseAuthProvider)));
final profileRepositoryProvider =
    Provider<ProfileRepository>((ref) => ProfileRepository(ref.watch(firestoreProvider)));
final dayRepositoryProvider =
    Provider<DayRepository>((ref) => DayRepository(ref.watch(firestoreProvider)));

final authStateProvider =
    StreamProvider<User?>((ref) => ref.watch(authRepositoryProvider).authStateChanges());

final activeProfileIdProvider = StreamProvider<String?>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value(null);
  return ref.watch(profileRepositoryProvider).watchActiveProfileId(user.uid);
});

final activeProfileProvider = StreamProvider<CycleProfile?>((ref) {
  final id = ref.watch(activeProfileIdProvider).valueOrNull;
  if (id == null) return Stream.value(null);
  return ref.watch(profileRepositoryProvider).watchProfile(id);
});

final dayEntriesProvider = StreamProvider<List<DayEntry>>((ref) {
  final id = ref.watch(activeProfileIdProvider).valueOrNull;
  if (id == null) return Stream.value(const <DayEntry>[]);
  return ref.watch(dayRepositoryProvider).watchAll(id);
});

final predictionProvider = Provider<CyclePrediction>((ref) {
  final entries = ref.watch(dayEntriesProvider).valueOrNull ?? const <DayEntry>[];
  final profile = ref.watch(activeProfileProvider).valueOrNull;
  return CyclePredictor.predict(
    entries: entries,
    today: ref.watch(todayProvider),
    defaultCycleLength: profile?.defaultCycleLength ?? 28,
    defaultPeriodLength: profile?.defaultPeriodLength ?? 5,
  );
});
