import { after, before, beforeEach, test } from 'node:test';
import { readFileSync } from 'node:fs';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  Timestamp,
  arrayUnion,
  doc,
  getDoc,
  serverTimestamp,
  setDoc,
  updateDoc,
} from 'firebase/firestore';

let env;

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-siklus',
    firestore: { rules: readFileSync(new URL('../firestore.rules', import.meta.url), 'utf8') },
  });
});

after(async () => env.cleanup());

beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await setDoc(doc(db, 'profiles/p1'), {
      ownerUid: 'alice',
      memberUids: ['alice'],
      name: 'Alice',
      defaultCycleLength: 28,
      defaultPeriodLength: 5,
    });
    await setDoc(doc(db, 'invites/ABC234'), {
      profileId: 'p1',
      createdBy: 'alice',
      expiresAt: Timestamp.fromMillis(Date.now() + 3_600_000),
    });
    await setDoc(doc(db, 'invites/OLD234'), {
      profileId: 'p1',
      createdBy: 'alice',
      expiresAt: Timestamp.fromMillis(Date.now() - 1_000),
    });
  });
});

const as = (uid) => env.authenticatedContext(uid).firestore();
const day = (uid, extra = {}) => ({
  date: '2026-10-15',
  flow: 'medium',
  symptoms: [],
  moods: [],
  energy: null,
  note: '',
  updatedBy: uid,
  updatedAt: serverTimestamp(),
  ...extra,
});

test('user can only access their own user doc', async () => {
  await assertSucceeds(setDoc(doc(as('alice'), 'users/alice'), { activeProfileId: 'p1' }));
  await assertFails(getDoc(doc(as('bob'), 'users/alice')));
});

test('stranger cannot read profile or days', async () => {
  await assertFails(getDoc(doc(as('bob'), 'profiles/p1')));
  await assertFails(getDoc(doc(as('bob'), 'profiles/p1/days/2026-10-15')));
});

test('member can write a valid day', async () => {
  await assertSucceeds(setDoc(doc(as('alice'), 'profiles/p1/days/2026-10-15'), day('alice')));
});

test('day must carry the writer uid, matching date and allowed keys', async () => {
  const db = as('alice');
  await assertFails(setDoc(doc(db, 'profiles/p1/days/2026-10-15'), day('bob')));
  await assertFails(setDoc(doc(db, 'profiles/p1/days/2026-10-16'), day('alice')));
  await assertFails(setDoc(doc(db, 'profiles/p1/days/2026-10-15'), day('alice', { hacked: true })));
  await assertFails(setDoc(doc(db, 'profiles/p1/days/2026-10-15'), day('alice', { note: 'x'.repeat(2001) })));
});

test('stranger cannot write days', async () => {
  await assertFails(setDoc(doc(as('bob'), 'profiles/p1/days/2026-10-15'), day('bob')));
});

test('user can create a profile only as its sole member', async () => {
  const db = as('bob');
  await assertSucceeds(setDoc(doc(db, 'profiles/p2'), {
    ownerUid: 'bob',
    memberUids: ['bob'],
    name: 'Bob',
    defaultCycleLength: 28,
    defaultPeriodLength: 5,
  }));
  await assertFails(setDoc(doc(db, 'profiles/p3'), {
    ownerUid: 'bob',
    memberUids: ['bob', 'alice'],
    name: 'X',
    defaultCycleLength: 28,
    defaultPeriodLength: 5,
  }));
});

test('valid invite lets bob join, then bob can write days', async () => {
  const db = as('bob');
  await assertSucceeds(getDoc(doc(db, 'invites/ABC234')));
  await assertSucceeds(updateDoc(doc(db, 'profiles/p1'), {
    memberUids: arrayUnion('bob'),
    joinedWithCode: 'ABC234',
  }));
  await assertSucceeds(setDoc(doc(db, 'profiles/p1/days/2026-10-15'), day('bob')));
});

test('expired or missing invite cannot be used', async () => {
  const db = as('bob');
  await assertFails(updateDoc(doc(db, 'profiles/p1'), { memberUids: arrayUnion('bob'), joinedWithCode: 'OLD234' }));
  await assertFails(updateDoc(doc(db, 'profiles/p1'), { memberUids: arrayUnion('bob'), joinedWithCode: 'NOPE22' }));
  await assertFails(updateDoc(doc(db, 'profiles/p1'), { memberUids: arrayUnion('bob') }));
});

test('invite cannot be used to add someone else', async () => {
  await assertFails(updateDoc(doc(as('bob'), 'profiles/p1'), {
    memberUids: arrayUnion('charlie'),
    joinedWithCode: 'ABC234',
  }));
});

test('only members can create invites for a profile', async () => {
  const future = Timestamp.fromMillis(Date.now() + 3_600_000);
  await assertSucceeds(setDoc(doc(as('alice'), 'invites/NEW234'), { profileId: 'p1', createdBy: 'alice', expiresAt: future }));
  await assertFails(setDoc(doc(as('bob'), 'invites/BAD234'), { profileId: 'p1', createdBy: 'bob', expiresAt: future }));
});
