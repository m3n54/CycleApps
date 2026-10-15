import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siklus/data/auth_repository.dart';

void main() {
  test('register signs the user in and trims email', () async {
    final auth = MockFirebaseAuth();
    final repo = AuthRepository(auth);
    await repo.register('  a@b.co ', 'rahasia1');
    expect(repo.currentUser, isNotNull);
    expect(repo.currentUser!.email, 'a@b.co');
  });

  test('signOut clears the current user', () async {
    final auth = MockFirebaseAuth(signedIn: true, mockUser: MockUser(uid: 'u1', email: 'a@b.co'));
    final repo = AuthRepository(auth);
    await repo.signOut();
    expect(repo.currentUser, isNull);
  });

  test('authErrorMessage maps common Firebase codes to Indonesian', () {
    expect(authErrorMessage(FirebaseAuthException(code: 'invalid-credential')),
        'Email atau password salah.');
    expect(authErrorMessage(FirebaseAuthException(code: 'email-already-in-use')),
        'Email sudah terdaftar. Silakan masuk.');
    expect(authErrorMessage(FirebaseAuthException(code: 'weak-password')),
        'Password minimal 6 karakter.');
    expect(authErrorMessage(FirebaseAuthException(code: 'network-request-failed')),
        'Tidak ada koneksi internet.');
    expect(authErrorMessage(Exception('x')), 'Terjadi kesalahan. Coba lagi.');
  });
}
