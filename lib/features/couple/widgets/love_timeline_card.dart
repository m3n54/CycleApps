import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/couple_interaction.dart';
import '../../../domain/cycle_profile.dart';
import '../../../state/providers.dart';
import '../../../theme/cycle_theme.dart';

class LoveTimelineCard extends ConsumerWidget {
  const LoveTimelineCard({
    super.key,
    required this.interaction,
    required this.profile,
  });

  final CoupleInteraction interaction;
  final CycleProfile profile;

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inSeconds < 60) {
      return 'Baru saja';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} menit lalu';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} jam lalu';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} hari lalu';
    } else {
      return '${dt.day}/${dt.month}/${dt.year}';
    }
  }

  Future<void> _handleReply(
    BuildContext context,
    WidgetRef ref,
    CustomCoupleSticker replySticker,
  ) async {
    try {
      await ref.read(profileRepositoryProvider).replyInteraction(
            profileId: profile.id,
            interactionId: interaction.id,
            replyEmoji: replySticker.emoji,
            replyText: replySticker.text,
          );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${replySticker.emoji} Balasan manis terkirim!'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengirim balasan: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final isMe = interaction.senderUid == user?.uid;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final customReplyStickers =
        profile.customStickers.where((s) => s.isReply).toList();
    final allReplyStickers = [
      ...CoupleCareCatalog.defaultReplyStickers,
      ...customReplyStickers,
    ];

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? CycleColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isMe
              ? CycleColors.primary.withValues(alpha: 0.25)
              : (isDark ? CycleColors.borderDark : CycleColors.borderLight),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Sender info + Timestamp
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: isMe
                    ? CycleColors.primary.withValues(alpha: 0.15)
                    : CycleColors.secondary.withValues(alpha: 0.15),
                child: Text(
                  isMe ? 'K' : (interaction.senderName.isNotEmpty ? interaction.senderName[0] : 'P'),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isMe ? CycleColors.primary : CycleColors.secondary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isMe ? 'Kamu' : interaction.senderName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      _formatTime(interaction.createdAt),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              if (interaction.isRead)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.done_all_rounded, size: 12, color: Colors.green),
                      SizedBox(width: 3),
                      Text(
                        'Dibaca',
                        style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Message content
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                interaction.emoji,
                style: const TextStyle(fontSize: 28),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  interaction.text,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),

          // Custom note if present
          if (interaction.customNote != null &&
              interaction.customNote!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.25)
                    : CycleColors.backgroundLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? CycleColors.borderDark : CycleColors.borderLight,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('💬', style: TextStyle(fontSize: 12)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      interaction.customNote!,
                      style: const TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Reply section
          if (interaction.hasReply) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: CycleColors.primary.withValues(alpha: isDark ? 0.15 : 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: CycleColors.primary.withValues(alpha: 0.25),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.reply_rounded,
                        size: 14,
                        color: CycleColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Balasan Manis:',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: CycleColors.primary.withValues(alpha: 0.9),
                        ),
                      ),
                      const Spacer(),
                      if (interaction.repliedAt != null)
                        Text(
                          _formatTime(interaction.repliedAt!),
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.withValues(alpha: 0.8),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        interaction.replyEmoji ?? '💖',
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          interaction.replyText ?? '',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ] else if (!isMe) ...[
            // 1-tap quick reply chip row if recipient hasn't replied yet
            const SizedBox(height: 12),
            const Text(
              'Kirim Balasan Cepat: ✨',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: CycleColors.primary,
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: allReplyStickers.length,
                separatorBuilder: (context, index) => const SizedBox(width: 6),
                itemBuilder: (context, index) {
                  final replySticker = allReplyStickers[index];
                  return ActionChip(
                    key: Key('reply_chip_${replySticker.id}'),
                    avatar: Text(
                      replySticker.emoji,
                      style: const TextStyle(fontSize: 14),
                    ),
                    label: Text(
                      replySticker.text,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                    ),
                    backgroundColor: isDark
                        ? CycleColors.primary.withValues(alpha: 0.12)
                        : CycleColors.primary.withValues(alpha: 0.06),
                    side: BorderSide(
                      color: CycleColors.primary.withValues(alpha: 0.2),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    onPressed: () => _handleReply(context, ref, replySticker),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
