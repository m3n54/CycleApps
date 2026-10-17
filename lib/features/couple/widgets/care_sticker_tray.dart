import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/couple_interaction.dart';
import '../../../domain/cycle_profile.dart';
import '../../../state/providers.dart';
import '../../../theme/cycle_theme.dart';
import 'add_custom_sticker_dialog.dart';

class CareStickerTray extends ConsumerStatefulWidget {
  const CareStickerTray({
    super.key,
    required this.profile,
  });

  final CycleProfile profile;

  @override
  ConsumerState<CareStickerTray> createState() => _CareStickerTrayState();
}

class _CareStickerTrayState extends ConsumerState<CareStickerTray> {
  final TextEditingController _noteController = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  String _chipLabel(CustomCoupleSticker sticker) {
    switch (sticker.id) {
      case 'default_care_1':
        return 'Peluk Erat';
      case 'default_care_2':
        return 'Boba';
      case 'default_care_3':
        return 'Pijat Bahu';
      case 'default_care_4':
        return 'Dengerin Curhat';
      case 'default_care_5':
        return 'Camilan Manis';
      case 'default_care_6':
        return 'Kompres Hangat';
      case 'default_care_7':
        return 'Ajak Istirahat';
      case 'default_care_8':
        return 'Kangen Banget';
      default:
        return sticker.text.length > 14
            ? '${sticker.text.substring(0, 14)}…'
            : sticker.text;
    }
  }

  Future<void> _sendSticker(CustomCoupleSticker sticker) async {
    if (_isSending) return;

    final user = ref.read(authStateProvider).valueOrNull;
    final isOwner = widget.profile.isOwner(user?.uid);
    final senderName = user?.displayName?.isNotEmpty == true
        ? user!.displayName!
        : (isOwner ? widget.profile.name : 'Pasangan');

    final note = _noteController.text.trim();

    setState(() => _isSending = true);

    try {
      await ref.read(profileRepositoryProvider).sendInteraction(
            profileId: widget.profile.id,
            senderUid: user?.uid ?? '',
            senderName: senderName,
            emoji: sticker.emoji,
            text: sticker.text,
            customNote: note.isNotEmpty ? note : null,
          );

      _noteController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${sticker.emoji} Perhatian manis terkirim!'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengirim perhatian: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  Future<void> _openAddStickerDialog() async {
    await showDialog<CustomCoupleSticker>(
      context: context,
      builder: (ctx) => AddCustomStickerDialog(
        profileId: widget.profile.id,
        initialIsReply: false,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final customCareStickers =
        widget.profile.customStickers.where((s) => !s.isReply).toList();
    final allStickers = [
      ...CoupleCareCatalog.defaultCareStickers,
      ...customCareStickers,
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? CycleColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? CycleColors.borderDark : CycleColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Kirim Perhatian Cepat',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton.icon(
                key: const Key('addStickerBtn'),
                onPressed: _openAddStickerDialog,
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  foregroundColor: CycleColors.primary,
                ),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text(
                  '+ Tambah',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Horizontal scrollable sticker chips
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: allStickers.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final sticker = allStickers[index];
                return ActionChip(
                  key: Key('sticker_chip_${sticker.id}'),
                  avatar: Text(
                    sticker.emoji,
                    style: const TextStyle(fontSize: 16),
                  ),
                  label: Text(
                    _chipLabel(sticker),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                  tooltip: sticker.text,
                  backgroundColor: isDark
                      ? CycleColors.primary.withValues(alpha: 0.15)
                      : CycleColors.primary.withValues(alpha: 0.08),
                  side: BorderSide(
                    color: CycleColors.primary.withValues(alpha: 0.2),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  onPressed: _isSending ? null : () => _sendSticker(sticker),
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // Optional quick love note field
          TextField(
            key: const Key('quickLoveNoteInput'),
            controller: _noteController,
            textInputAction: TextInputAction.send,
            decoration: InputDecoration(
              hintText: 'Tulis pesan manis tambahan... (opsional)',
              hintStyle: TextStyle(
                fontSize: 13,
                color: Colors.grey.withValues(alpha: 0.7),
              ),
              prefixIcon: const Icon(
                Icons.favorite_border_rounded,
                size: 18,
                color: CycleColors.primary,
              ),
              filled: true,
              fillColor: isDark
                  ? Colors.black.withValues(alpha: 0.2)
                  : CycleColors.backgroundLight,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: isDark ? CycleColors.borderDark : CycleColors.borderLight,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: isDark ? CycleColors.borderDark : CycleColors.borderLight,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: CycleColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
