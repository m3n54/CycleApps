import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/cycle_profile.dart';
import '../../state/providers.dart';
import '../../theme/cycle_theme.dart';
import 'widgets/care_sticker_tray.dart';
import 'widgets/love_header_badge.dart';
import 'widgets/love_timeline_card.dart';

class CoupleSpaceScreen extends ConsumerWidget {
  const CoupleSpaceScreen({super.key});

  Future<void> _createInviteCode(
    BuildContext context,
    WidgetRef ref,
    CycleProfile profile,
  ) async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;

    try {
      final code = await ref
          .read(profileRepositoryProvider)
          .createInvite(uid: user.uid, profileId: profile.id);

      if (!context.mounted) return;

      await showDialog<void>(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Text('💌', style: TextStyle(fontSize: 20)),
              SizedBox(width: 8),
              Text(
                'Kode Undangan',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: CycleColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: CycleColors.primary.withValues(alpha: 0.25),
                  ),
                ),
                child: SelectableText(
                  code,
                  style: Theme.of(dialogCtx).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 3,
                        color: CycleColors.primary,
                      ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Bagikan kode 6 karakter ini kepada pasanganmu. Berlaku selama 24 jam.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: code));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Kode undangan berhasil disalin!')),
                );
                Navigator.of(dialogCtx).pop();
              },
              child: const Text('Salin'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Tutup'),
            ),
          ],
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal membuat undangan. Pastikan terhubung ke internet.'),
        ),
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
              title: const Row(
                children: [
                  Icon(Icons.link_rounded, color: CycleColors.primary),
                  SizedBox(width: 8),
                  Text(
                    'Gabung dengan Kode',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Masukkan 6 digit kode undangan dari pasanganmu untuk menghubungkan ruang cinta kalian.',
                    style: TextStyle(fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    key: const Key('joinCodeInputCouple'),
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
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final code = textController.text.trim().toUpperCase();
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
                                .joinWithCode(uid: user.uid, rawCode: code);
                            if (dialogContext.mounted) {
                              Navigator.of(dialogContext).pop();
                            }
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Berhasil terhubung dengan pasangan! 💑'),
                                ),
                              );
                            }
                          } catch (e) {
                            setDialogState(() {
                              isSubmitting = false;
                              errorText = e.toString().replaceFirst('Exception: ', '');
                            });
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Gabung'),
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
    final profileAsync = ref.watch(activeProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ruang Pasangan 💑'),
        centerTitle: true,
      ),
      body: profileAsync.when(
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('Profil tidak ditemukan.'));
          }

          if (profile.memberUids.length < 2) {
            return _buildUnlinkedView(context, ref, profile);
          }

          return _buildConnectedView(context, ref, profile);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Terjadi kesalahan: $err')),
      ),
    );
  }

  Widget _buildUnlinkedView(
    BuildContext context,
    WidgetRef ref,
    CycleProfile profile,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      CycleColors.primary.withValues(alpha: 0.15),
                      CycleColors.secondary.withValues(alpha: 0.25),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Text('💑', style: TextStyle(fontSize: 42)),
              ),
              const SizedBox(height: 20),
              const Text(
                'Belum Terhubung dengan Pasangan',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Hubungkan akun dengan pasangan tercinta untuk saling kirim stiker perhatian manis, pantau fase siklus, dan memahami satu sama lain.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.5,
                  color: isDark ? Colors.grey[300] : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 28),
              FilledButton.icon(
                key: const Key('createInviteBtn'),
                onPressed: () => _createInviteCode(context, ref, profile),
                style: FilledButton.styleFrom(
                  backgroundColor: CycleColors.primary,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.share_rounded, size: 20),
                label: const Text(
                  'Buat Kode Undangan',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                key: const Key('joinCodeBtn'),
                onPressed: () => _joinWithCode(context, ref),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  side: const BorderSide(color: CycleColors.primary, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.link_rounded, color: CycleColors.primary, size: 20),
                label: const Text(
                  'Gabung dengan Kode',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: CycleColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConnectedView(
    BuildContext context,
    WidgetRef ref,
    CycleProfile profile,
  ) {
    final interactionsAsync = ref.watch(coupleInteractionsProvider);
    final interactions = interactionsAsync.valueOrNull ?? const [];

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        // Top Header
        LoveHeaderBadge(profile: profile),
        const SizedBox(height: 14),

        // Sticker Tray
        CareStickerTray(profile: profile),
        const SizedBox(height: 20),

        // Timeline Title
        Row(
          children: [
            const Expanded(
              child: Text(
                'Timeline Perhatian & Cinta 💌',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (interactions.isNotEmpty) ...[
              const SizedBox(width: 8),
              Text(
                '${interactions.length} pesan',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.withValues(alpha: 0.8),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 10),

        // Timeline items
        if (interactions.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
            alignment: Alignment.center,
            child: Column(
              children: [
                const Text('💌', style: TextStyle(fontSize: 36)),
                const SizedBox(height: 8),
                const Text(
                  'Belum ada pesan perhatian manis',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Kirim stiker perhatian pertamamu di atas untuk si dia! 💕',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          )
        else
          ...interactions.map(
            (interaction) => LoveTimelineCard(
              key: ValueKey('interaction_${interaction.id}'),
              interaction: interaction,
              profile: profile,
            ),
          ),
      ],
    );
  }
}
