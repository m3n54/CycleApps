import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:siklus/features/log/day_log_screen.dart';
import 'package:siklus/state/providers.dart';

void main() {
  late FakeFirebaseFirestore db;
  late MockFirebaseAuth auth;

  setUpAll(() => initializeDateFormatting('id_ID'));

  setUp(() async {
    auth = MockFirebaseAuth(signedIn: true, mockUser: MockUser(uid: 'u1', email: 'a@b.co'));
    db = FakeFirebaseFirestore();
    await db.doc('users/u1').set({'activeProfileId': 'p1'});
    await db.doc('profiles/p1').set({'ownerUid': 'u1', 'memberUids': ['u1'], 'name': 'A'});
  });

  /// Layar awal memantau dayEntriesProvider agar data sudah dimuat sebelum DayLogScreen dibuka.
  Future<void> openLog(WidgetTester tester, {required int expectedEntries}) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        firebaseAuthProvider.overrideWithValue(auth),
        firestoreProvider.overrideWithValue(db),
      ],
      child: MaterialApp(
        home: Consumer(builder: (context, ref, _) {
          final n = ref.watch(dayEntriesProvider).valueOrNull?.length;
          return Scaffold(
            body: ElevatedButton(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => DayLogScreen(date: DateTime(2026, 10, 15)),
              )),
              child: Text('buka ${n ?? '-'}'),
            ),
          );
        }),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('buka $expectedEntries'));
    await tester.pumpAndSettle();
  }

  testWidgets('saves flow, symptoms, mood, energy and note', (tester) async {
    await openLog(tester, expectedEntries: 0);
    await tester.tap(find.text('Sedang'));
    await tester.tap(find.text('Kram'));
    await tester.ensureVisible(find.text('Cemas'));
    await tester.tap(find.text('Cemas'));
    await tester.ensureVisible(find.text('Lemas'));
    await tester.tap(find.text('Lemas'));
    await tester.ensureVisible(find.byKey(const Key('note')));
    await tester.enterText(find.byKey(const Key('note')), 'perut sakit');
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();

    final data = (await db.doc('profiles/p1/days/2026-10-15').get()).data()!;
    expect(data['flow'], 'medium');
    expect(data['symptoms'], ['cramps']);
    expect(data['moods'], ['anxious']);
    expect(data['energy'], 'low');
    expect(data['note'], 'perut sakit');
    expect(data['updatedBy'], 'u1');
    expect(find.text('buka 1'), findsOneWidget); // kembali ke layar sebelumnya
  });

  testWidgets('prefills existing entry and tapping a selected chip clears it', (tester) async {
    await db.doc('profiles/p1/days/2026-10-15').set({
      'date': '2026-10-15', 'flow': 'heavy', 'symptoms': <String>[], 'moods': <String>[],
      'energy': null, 'note': '', 'updatedBy': 'u1',
    });
    await openLog(tester, expectedEntries: 1);
    final heavy = tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Berat'));
    expect(heavy.selected, isTrue);

    await tester.tap(find.text('Berat')); // batalkan pilihan → entri kosong
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();
    expect((await db.doc('profiles/p1/days/2026-10-15').get()).exists, isFalse);
  });
}
