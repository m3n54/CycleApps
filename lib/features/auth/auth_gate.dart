import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/providers.dart';
import '../home/home_shell.dart';
import '../onboarding/onboarding_screen.dart';
import 'login_screen.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    return auth.when(
      loading: () => const _Loading(),
      error: (e, _) => _Error('$e'),
      data: (user) {
        if (user == null) return const LoginScreen();
        final active = ref.watch(activeProfileIdProvider);
        return active.when(
          loading: () => const _Loading(),
          error: (e, _) => _Error('$e'),
          data: (id) => id == null ? const OnboardingScreen() : const HomeShell(),
        );
      },
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}

class _Error extends StatelessWidget {
  const _Error(this.message);
  final String message;
  @override
  Widget build(BuildContext context) =>
      Scaffold(body: Center(child: Text('Terjadi kesalahan: $message')));
}
