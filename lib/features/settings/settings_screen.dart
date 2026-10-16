import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/profile_repository.dart';
import '../../state/providers.dart';
import '../../state/update_controller.dart';
import '../../theme/cycle_theme.dart';
import '../calendar/prediction_summary.dart';
import '../common/widgets/responsive_bounds.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _handleUpdateAction(BuildContext context, WidgetRef ref) async {
    final current = ref.read(appUpdateControllerProvider);
    if (current.isBusy) return;

    final notifier = ref.read(appUpdateControllerProvider.notifier);
    final AppUpdateState nextState;
    if (current.phase == AppUpdatePhase.updateAvailable) {
      nextState = await notifier.downloadAndApplyPatch();
    } else {
      nextState = await notifier.checkForUpdates(manual: true);
    }

    if (!context.mounted) return;
    if (nextState.statusMessage.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(nextState.statusMessage)),
      );
    }
  }

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
                'Minta pasangan memasukkan kode ini di layar "Mulai" atau di menu Pengaturan. Berlaku 24 jam.',
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

  Future<void> _joinWithCode(BuildContext context, WidgetRef ref) async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;
    final textController = TextEditingController();
    var isSubmitting = false;
    String? errorText;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: CycleColors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.link_rounded, color: CycleColors.primary, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Gabung Profil Pasangan',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Masukkan 6 digit kode undangan dari pasangan Anda untuk menghubungkan akun.',
                    style: TextStyle(fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    key: const Key('joinCodeInput'),
                    controller: textController,
                    autofocus: true,
                    textCapitalization: TextCapitalization.characters,
                    textAlign: TextAlign.center,
                    maxLength: 6,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 6,
                      color: CycleColors.primary,
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: 'KODE',
                      hintStyle: TextStyle(
                        letterSpacing: 4,
                        color: Colors.grey.withValues(alpha: 0.5),
                      ),
                      errorText: errorText,
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onChanged: (_) {
                      if (errorText != null) {
                        setDialogState(() => errorText = null);
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Batal'),
                ),
                FilledButton(
                  key: const Key('submitJoinCodeBtn'),
                  style: FilledButton.styleFrom(
                    backgroundColor: CycleColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final code = textController.text.trim();
                          if (code.isEmpty) {
                            setDialogState(() => errorText = 'Masukkan kode undangan');
                            return;
                          }
                          setDialogState(() {
                            isSubmitting = true;
                            errorText = null;
                          });
                          try {
                            await ref
                                .read(profileRepositoryProvider)
                                .joinWithCode(uid: user.uid, rawCode: code)
                                .timeout(const Duration(seconds: 15));
                            if (!dialogContext.mounted) return;
                            Navigator.of(dialogContext).pop();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('🎉 Berhasil terhubung dengan profil pasangan!'),
                                ),
                              );
                            }
                          } on JoinException catch (e) {
                            setDialogState(() {
                              isSubmitting = false;
                              errorText = e.message;
                            });
                          } catch (_) {
                            setDialogState(() {
                              isSubmitting = false;
                              errorText = 'Gagal terhubung. Pastikan internet aktif.';
                            });
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Gabung', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final profile = ref.watch(activeProfileProvider).valueOrNull;
    final user = ref.watch(authStateProvider).valueOrNull;
    final themeMode = ref.watch(themeModeProvider);
    final updateState = ref.watch(appUpdateControllerProvider);

    final String updateActionTitle;
    final String updateActionSubtitle;
    if (updateState.phase == AppUpdatePhase.updateAvailable) {
      updateActionTitle = 'Unduh Pembaruan Sekarang';
      updateActionSubtitle =
          'Ada fitur baru! Ketuk untuk memperbarui tanpa instal ulang.';
    } else if (updateState.phase == AppUpdatePhase.restartRequired) {
      updateActionTitle = 'Pembaruan Siap Diterapkan';
      updateActionSubtitle =
          'Tutup dan buka kembali aplikasi untuk menikmati versi terbaru.';
    } else if (updateState.phase == AppUpdatePhase.downloading) {
      updateActionTitle = 'Mengunduh Pembaruan...';
      updateActionSubtitle = 'Mohon tunggu sebentar...';
    } else if (updateState.phase == AppUpdatePhase.checking) {
      updateActionTitle = 'Memeriksa Pembaruan...';
      updateActionSubtitle = 'Menghubungi server pembaruan...';
    } else {
      updateActionTitle = 'Cek Pembaruan Aplikasi';
      updateActionSubtitle =
          'Periksa update terbaru secara instan tanpa hapus aplikasi';
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan & Profil')),
      body: SafeArea(
        child: ResponsiveBounds(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
            // Profile Card
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: [
                    _SettingsTile(
                      leading: CircleAvatar(
                        backgroundColor: CycleColors.primary.withValues(alpha: 0.14),
                        child: const Icon(Icons.favorite_rounded, color: CycleColors.primary),
                      ),
                      title: Text(
                        profile?.name ?? '-',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        user != null && profile != null && profile.isOwner(user.uid)
                            ? 'Pemilik Profil • ${profile.memberUids.length} anggota'
                            : 'Mode Pasangan • ${profile?.memberUids.length ?? 0} anggota',
                      ),
                    ),
                    const Divider(height: 1),
                    _SettingsTile(
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
                    const Divider(height: 1),
                    _SettingsTile(
                      leading: CircleAvatar(
                        backgroundColor: CycleColors.primary.withValues(alpha: 0.14),
                        child: const Icon(Icons.link_rounded, color: CycleColors.primary),
                      ),
                      title: const Text(
                        'Gabung dengan kode undangan',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: const Text('Masukkan kode dari pasangan untuk sinkronisasi'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => _joinWithCode(context, ref),
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
                        Expanded(
                          child: Text(
                            'Tampilan Tema',
                            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
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
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // App Update & Version Card (Shorebird OTA)
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: [
                    _SettingsTile(
                      leading: CircleAvatar(
                        backgroundColor: CycleColors.primary.withValues(alpha: 0.14),
                        child: const Icon(
                          Icons.verified_outlined,
                          color: CycleColors.primary,
                        ),
                      ),
                      title: const Text(
                        'Versi Aplikasi Siklus',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(updateState.versionSubtitle),
                    ),
                    const Divider(height: 1),
                    _SettingsTile(
                      leading: CircleAvatar(
                        backgroundColor: CycleColors.accent.withValues(alpha: 0.14),
                        child: const Icon(
                          Icons.system_update_rounded,
                          color: CycleColors.accent,
                        ),
                      ),
                      title: Text(
                        updateActionTitle,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(updateActionSubtitle),
                      trailing: updateState.isBusy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh_rounded),
                      onTap: updateState.isBusy
                          ? null
                          : () => _handleUpdateAction(context, ref),
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
                  _SettingsTile(
                    leading: const Icon(Icons.email_outlined),
                    title: Text(user?.email ?? ''),
                    subtitle: const Text('Email Akun'),
                  ),
                  const Divider(height: 1),
                  _SettingsTile(
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
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  final Widget leading;
  final Widget title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Flexible(
              flex: 0,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: leading,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  DefaultTextStyle.merge(
                    style: theme.textTheme.bodyLarge,
                    child: title,
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    DefaultTextStyle.merge(
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                      ),
                      child: subtitle!,
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              Flexible(
                flex: 0,
                child: trailing!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

