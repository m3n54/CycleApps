import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/providers.dart';
import '../calendar/prediction_summary.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _invite(BuildContext context, WidgetRef ref) async {
    final user = ref.read(authStateProvider).valueOrNull;
    final profileId = ref.read(activeProfileIdProvider).valueOrNull;
    if (user == null || profileId == null) return;
    try {
      final code = await ref
          .read(profileRepositoryProvider)
          .createInvite(uid: user.uid, profileId: profileId)
          .timeout(const Duration(seconds: 15));
      if (!context.mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Kode undangan'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            SelectableText(code, style: Theme.of(dialogContext).textTheme.headlineMedium),
            const SizedBox(height: 8),
            const Text('Minta pasangan memasukkan kode ini di layar "Mulai". Berlaku 24 jam.'),
          ]),
          actions: [
            TextButton(
              onPressed: () => Clipboard.setData(ClipboardData(text: code)),
              child: const Text('Salin'),
            ),
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Tutup')),
          ],
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal membuat undangan. Pastikan terhubung ke internet.')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(activeProfileProvider).valueOrNull;
    final user = ref.watch(authStateProvider).valueOrNull;
    return SafeArea(
      child: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.favorite),
            title: Text(profile?.name ?? '-'),
            subtitle: Text('${profile?.memberUids.length ?? 0} anggota'),
          ),
          ListTile(
            leading: const Icon(Icons.group_add),
            title: const Text('Undang pasangan'),
            subtitle: const Text('Buat kode undangan (berlaku 24 jam)'),
            onTap: () => _invite(context, ref),
          ),
          const Divider(),
          ListTile(leading: const Icon(Icons.email), title: Text(user?.email ?? '')),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Keluar'),
            onTap: () => ref.read(authRepositoryProvider).signOut(),
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(cycleDisclaimer, style: TextStyle(fontSize: 12, color: Colors.grey)),
          ),
        ],
      ),
    );
  }
}
