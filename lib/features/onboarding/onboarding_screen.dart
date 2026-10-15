import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/profile_repository.dart';
import '../../state/providers.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _name = TextEditingController();
  final _code = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _code.dispose();
    super.dispose();
  }

  void _snack(String message) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

  Future<void> _create() async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;
    if (_name.text.trim().isEmpty) {
      _snack('Isi nama profil.');
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(profileRepositoryProvider).createProfile(uid: user.uid, name: _name.text);
    } catch (e) {
      if (mounted) _snack('Gagal membuat profil. Pastikan terhubung ke internet.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _join() async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;
    setState(() => _busy = true);
    try {
      await ref.read(profileRepositoryProvider).joinWithCode(uid: user.uid, rawCode: _code.text);
    } on JoinException catch (e) {
      if (mounted) _snack(e.message);
    } catch (e) {
      if (mounted) _snack('Gagal bergabung. Pastikan terhubung ke internet.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(authStateProvider); // menjaga stream login tetap aktif
    final title = Theme.of(context).textTheme.titleMedium;
    return Scaffold(
      appBar: AppBar(title: const Text('Mulai')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('Saya yang mencatat siklus', style: title),
          const SizedBox(height: 12),
          TextField(
            key: const Key('profileName'),
            controller: _name,
            decoration: const InputDecoration(
              labelText: 'Nama profil (mis. nama Anda)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(onPressed: _busy ? null : _create, child: const Text('Buat profil')),
          const Divider(height: 48),
          Text('Saya diundang pasangan', style: title),
          const SizedBox(height: 12),
          TextField(
            key: const Key('inviteCode'),
            controller: _code,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(labelText: 'Kode undangan', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: _busy ? null : _join, child: const Text('Gabung')),
        ],
      ),
    );
  }
}
