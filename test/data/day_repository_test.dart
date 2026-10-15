import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siklus/data/day_repository.dart';
import 'package:siklus/domain/day_entry.dart';

void main() {
  late FakeFirebaseFirestore db;
  late DayRepository repo;

  setUp(() {
    db = FakeFirebaseFirestore();
    repo = DayRepository(db);
  });

  test('saveDay writes one document per date with updatedBy', () async {
    await repo.saveDay(
      profileId: 'p1',
      uid: 'alice',
      entry: const DayEntry(date: '2026-10-15', flow: FlowLevel.heavy, symptoms: {Symptom.cramps}),
    );
    final doc = await db.doc('profiles/p1/days/2026-10-15').get();
    expect(doc.data()!['flow'], 'heavy');
    expect(doc.data()!['symptoms'], ['cramps']);
    expect(doc.data()!['updatedBy'], 'alice');
    expect(doc.data()!.containsKey('updatedAt'), isTrue);
  });

  test('saving again overwrites the whole day (last write wins)', () async {
    await repo.saveDay(
      profileId: 'p1',
      uid: 'alice',
      entry: const DayEntry(date: '2026-10-15', flow: FlowLevel.heavy, note: 'a'),
    );
    await repo.saveDay(
      profileId: 'p1',
      uid: 'bob',
      entry: const DayEntry(date: '2026-10-15', moods: {Mood.calm}),
    );
    final data = (await db.doc('profiles/p1/days/2026-10-15').get()).data()!;
    expect(data['flow'], isNull);
    expect(data['note'], '');
    expect(data['moods'], ['calm']);
    expect(data['updatedBy'], 'bob');
  });

  test('saving an empty entry deletes the day', () async {
    await repo.saveDay(profileId: 'p1', uid: 'alice', entry: const DayEntry(date: '2026-10-15', note: 'x'));
    await repo.saveDay(profileId: 'p1', uid: 'alice', entry: const DayEntry(date: '2026-10-15'));
    expect((await db.doc('profiles/p1/days/2026-10-15').get()).exists, isFalse);
  });

  test('watchAll emits parsed entries', () async {
    await repo.saveDay(profileId: 'p1', uid: 'a', entry: const DayEntry(date: '2026-10-14', flow: FlowLevel.light));
    await repo.saveDay(profileId: 'p1', uid: 'a', entry: const DayEntry(date: '2026-10-15', flow: FlowLevel.medium));
    final entries = await repo.watchAll('p1').first;
    expect(entries.map((e) => e.date).toSet(), {'2026-10-14', '2026-10-15'});
    expect(entries.every((e) => e.updatedBy == 'a'), isTrue);
  });
}
