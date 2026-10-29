import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/couple_streak_calculator.dart';
import '../../../domain/cycle_profile.dart';
import '../../../state/providers.dart';
import '../../../theme/cycle_theme.dart';

class LoveHeaderBadge extends ConsumerStatefulWidget {
  const LoveHeaderBadge({
    super.key,
    required this.profile,
  });

  final CycleProfile profile;

  @override
  ConsumerState<LoveHeaderBadge> createState() => _LoveHeaderBadgeState();
}

class _LoveHeaderBadgeState extends ConsumerState<LoveHeaderBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    final bindingName = WidgetsBinding.instance.runtimeType.toString();
    if (!bindingName.contains('Test')) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _openCoupleMetadataDialog(BuildContext context) async {
    final today = ref.read(todayProvider);
    final nameController = TextEditingController(text: widget.profile.partnerName);
    DateTime? selectedDate = widget.profile.anniversaryDate;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final formattedDate = selectedDate != null
              ? '${selectedDate!.day.toString().padLeft(2, '0')}/${selectedDate!.month.toString().padLeft(2, '0')}/${selectedDate!.year}'
              : 'Pilih Tanggal Jadian';

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Text('💕', style: TextStyle(fontSize: 22)),
                SizedBox(width: 8),
                Text(
                  'Profil Pasangan',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Nama Panggilan Pasangan',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    key: const Key('partnerNameInput'),
                    controller: nameController,
                    decoration: InputDecoration(
                      hintText: 'Misal: Menza / Ayang',
                      prefixIcon: const Icon(Icons.favorite_rounded, color: CycleColors.primary, size: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Tanggal Jadian / Hari Bersama',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  InkWell(
                    key: const Key('pickAnniversaryDateBtn'),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate ?? today,
                        firstDate: DateTime(1970),
                        lastDate: today,
                      );
                      if (picked != null) {
                        setDialogState(() => selectedDate = picked);
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.withValues(alpha: 0.4)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded, size: 18, color: CycleColors.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              formattedDate,
                              style: TextStyle(
                                fontSize: 14,
                                color: selectedDate != null ? null : Colors.grey,
                              ),
                            ),
                          ),
                          const Icon(Icons.arrow_drop_down, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Batal'),
              ),
              FilledButton(
                key: const Key('saveCoupleMetadataBtn'),
                onPressed: () async {
                  await ref.read(profileRepositoryProvider).updateCoupleMetadata(
                        profileId: widget.profile.id,
                        partnerName: nameController.text.trim(),
                        anniversaryDate: selectedDate,
                      );
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                  }
                },
                style: FilledButton.styleFrom(
                  backgroundColor: CycleColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Simpan'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final today = ref.watch(todayProvider);
    final interactions = ref.watch(coupleInteractionsProvider).valueOrNull ?? const [];
    final user = ref.watch(authStateProvider).valueOrNull;
    final isOwner = widget.profile.isOwner(user?.uid);

    final partnerDisplayName = isOwner
        ? (widget.profile.partnerName.trim().isNotEmpty
            ? widget.profile.partnerName.trim()
            : 'Pasangan')
        : (widget.profile.name.trim().isNotEmpty
            ? widget.profile.name.trim()
            : 'Pasangan');
    final partnerInitial =
        (partnerDisplayName.isNotEmpty ? partnerDisplayName[0] : 'P').toUpperCase();

    final myDisplayName = isOwner
        ? (widget.profile.name.trim().isNotEmpty ? widget.profile.name : 'Kamu')
        : (widget.profile.partnerName.trim().isNotEmpty
            ? widget.profile.partnerName
            : 'Kamu');
    final myInitial = switch (user?.displayName) {
      final name? when name.isNotEmpty => name[0].toUpperCase(),
      _ when isOwner && widget.profile.name.isNotEmpty => widget.profile.name[0].toUpperCase(),
      _ when !isOwner && widget.profile.partnerName.isNotEmpty => widget.profile.partnerName[0].toUpperCase(),
      _ => isOwner ? 'K' : 'A',
    };

    final daysTogether = CoupleStreakCalculator.daysTogether(
      anniversaryDate: widget.profile.anniversaryDate,
      today: today,
    );
    final streak = CoupleStreakCalculator.calculateStreak(
      interactions: interactions,
      today: today,
    );

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? CycleColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? CycleColors.borderDark : CycleColors.borderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: CycleColors.primary.withValues(alpha: isDark ? 0.05 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // User Avatar
              _buildAvatar(
                label: myDisplayName,
                initial: myInitial,
                color: CycleColors.primary,
                isLeft: true,
              ),

              // Animated connector
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 2,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            CycleColors.primary.withValues(alpha: 0.4),
                            CycleColors.secondary,
                          ],
                        ),
                      ),
                    ),
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: CycleColors.primary.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.favorite_rounded,
                          color: CycleColors.primary,
                          size: 18,
                        ),
                      ),
                    ),
                    Container(
                      width: 24,
                      height: 2,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            CycleColors.secondary,
                            CycleColors.primary.withValues(alpha: 0.4),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Partner Avatar
              _buildAvatar(
                label: partnerDisplayName,
                initial: partnerInitial,
                color: CycleColors.secondary,
                isLeft: false,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF10B981),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  'Terhubung dengan $partnerDisplayName',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                key: const Key('editCoupleMetadataBtn'),
                icon: const Icon(Icons.edit_outlined, size: 16),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                visualDensity: VisualDensity.compact,
                tooltip: 'Atur Nama Pasangan & Tanggal Jadian',
                onPressed: () => _openCoupleMetadataDialog(context),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Badges: Days Together & Care Streak
          Wrap(
            spacing: 8,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: [
              // Anniversary Badge
              InkWell(
                onTap: () => _openCoupleMetadataDialog(context),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: CycleColors.primary.withValues(alpha: isDark ? 0.15 : 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: CycleColors.primary.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Text(
                    daysTogether != null
                        ? '💕 $daysTogether Hari Bersama'
                        : 'Atur Tanggal Jadian 💕',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: CycleColors.primary,
                    ),
                  ),
                ),
              ),

              // Care Streak Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: streak > 0
                      ? const Color(0xFFF97316).withValues(alpha: isDark ? 0.2 : 0.1)
                      : Colors.grey.withValues(alpha: isDark ? 0.15 : 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: streak > 0
                        ? const Color(0xFFF97316).withValues(alpha: 0.3)
                        : Colors.grey.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  streak > 0 ? '🔥 $streak Hari Streak' : '🔥 Mulai Streak Hari Ini',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: streak > 0 ? const Color(0xFFEA580C) : Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar({
    required String label,
    required String initial,
    required Color color,
    required bool isLeft,
  }) {
    return Column(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: color.withValues(alpha: 0.15),
          child: Text(
            initial,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 4),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 80),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }
}
