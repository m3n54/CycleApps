import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/providers.dart';
import '../../theme/cycle_theme.dart';
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Kode undangan'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: CycleColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: CycleColors.primary.withValues(alpha: 0.25)),
                ),
                child: SelectableText(
                  code,
                  style: Theme.of(dialogContext).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 3,
                        color: CycleColors.primary,
                      ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Minta pasangan memasukkan kode ini di layar "Mulai". Berlaku 24 jam.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Clipboard.setData(ClipboardData(text: code)),
              child: const Text('Salin'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Tutup'),
            ),
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
    final theme = Theme.of(context);
    final profile = ref.watch(activeProfileProvider).valueOrNull;
    final user = ref.watch(authStateProvider).valueOrNull;
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan & Profil')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            // Profile Card
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: [
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: CycleColors.primary.withValues(alpha: 0.14),
                        child: const Icon(Icons.favorite_rounded, color: CycleColors.primary),
                      ),
                      title: Text(
                        profile?.name ?? '-',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text('${profile?.memberUids.length ?? 0} anggota'),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: CycleColors.accent.withValues(alpha: 0.14),
                        child: const Icon(Icons.group_add_rounded, color: CycleColors.accent),
                      ),
                      title: const Text(
                        'Undang pasangan',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: const Text('Buat kode undangan (berlaku 24 jam)'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => _invite(context, ref),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Theme Mode Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.palette_outlined, size: 20, color: CycleColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Tampilan Tema',
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<ThemeMode>(
                        segments: const [
                          ButtonSegment(
                            value: ThemeMode.system,
                            icon: Icon(Icons.brightness_auto_rounded, size: 18),
                            label: Text('Sistem'),
                          ),
                          ButtonSegment(
                            value: ThemeMode.light,
                            icon: Icon(Icons.wb_sunny_outlined, size: 18),
                            label: Text('Terang'),
                          ),
                          ButtonSegment(
                            value: ThemeMode.dark,
                            icon: Icon(Icons.nightlight_round, size: 18),
                            label: Text('Gelap'),
                          ),
                        ],
                        selected: {themeMode},
                        onSelectionChanged: (modes) {
                          ref.read(themeModeProvider.notifier).state = modes.first;
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Account Card
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.email_outlined),
                    title: Text(user?.email ?? ''),
                    subtitle: const Text('Email Akun'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.logout_rounded, color: theme.colorScheme.error),
                    title: Text(
                      'Keluar',
                      style: TextStyle(
                        color: theme.colorScheme.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onTap: () => ref.read(authRepositoryProvider).signOut(),
                  ),
                ],
              ),
            ),

            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                cycleDisclaimer,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
