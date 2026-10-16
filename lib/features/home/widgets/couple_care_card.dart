import 'package:flutter/material.dart';

import '../../../domain/couple_care.dart';
import '../../../domain/cycle_phase.dart';
import '../../../theme/cycle_theme.dart';

class CoupleCareCard extends StatelessWidget {
  const CoupleCareCard({
    super.key,
    required this.isPartner,
    required this.partnerName,
    required this.phase,
    required this.activeSignal,
    required this.signalReaction,
    required this.onSelectSignal,
    required this.onSelectReaction,
  });

  final bool isPartner;
  final String partnerName;
  final CyclePhase phase;
  final CoupleSignal? activeSignal;
  final PartnerReaction? signalReaction;
  final ValueChanged<CoupleSignal?> onSelectSignal;
  final ValueChanged<PartnerReaction?> onSelectReaction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? CycleColors.surfaceDark : CycleColors.surfaceLight;
    final borderColor = isDark ? CycleColors.borderDark : CycleColors.borderLight;

    if (isPartner) {
      return _buildPartnerCard(context, theme, isDark, cardColor, borderColor);
    }
    return _buildOwnerCard(context, theme, isDark, cardColor, borderColor);
  }

  Widget _buildOwnerCard(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    Color cardColor,
    Color borderColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: CycleColors.secondary.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: CycleColors.secondary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.favorite_rounded,
                  size: 18,
                  color: CycleColors.secondary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kode Cepat ke Pasangan',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Kirim sinyal 1-klik tentang apa yang kamu butuhkan hari ini',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final signal in CoupleSignal.values)
                ChoiceChip(
                  label: Text(
                    CoupleCareCatalog.signalLabel(signal),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: activeSignal == signal
                          ? Colors.white
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  selected: activeSignal == signal,
                  selectedColor: CycleColors.secondary,
                  backgroundColor: isDark
                      ? CycleColors.backgroundDark
                      : CycleColors.backgroundLight,
                  side: BorderSide(
                    color: activeSignal == signal
                        ? CycleColors.secondary
                        : borderColor,
                  ),
                  onSelected: (_) => onSelectSignal(
                    activeSignal == signal ? null : signal,
                  ),
                ),
            ],
          ),
          if (signalReaction != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: CycleColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: CycleColors.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.mark_chat_read_rounded,
                    size: 18,
                    color: CycleColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Balasan Pasangan: ${CoupleCareCatalog.reactionLabel(signalReaction!)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: CycleColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPartnerCard(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    Color cardColor,
    Color borderColor,
  ) {
    final tip = CoupleCareCatalog.partnerTipForPhase(phase);
    final subject = partnerName.trim().isEmpty ? 'Pasanganmu' : partnerName.trim();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: CycleColors.primary.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: CycleColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.volunteer_activism_rounded,
                  size: 18,
                  color: CycleColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Panduan Pasangan Hari Ini',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            tip.title,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: CycleColors.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            tip.bodyCondition,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.78),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isDark
                  ? CycleColors.backgroundDark.withValues(alpha: 0.6)
                  : CycleColors.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.tips_and_updates_rounded,
                  size: 16,
                  color: CycleColors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tip.actionSuggestion,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (activeSignal != null) ...[
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Text(
              '🔔 Kode dari $subject: "${CoupleCareCatalog.signalLabel(activeSignal!)}"',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Kirim reaksi balasan cepat:',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final reaction in PartnerReaction.values)
                  ChoiceChip(
                    label: Text(
                      CoupleCareCatalog.reactionLabel(reaction),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: signalReaction == reaction
                            ? Colors.white
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                    selected: signalReaction == reaction,
                    selectedColor: CycleColors.primary,
                    backgroundColor: isDark
                        ? CycleColors.backgroundDark
                        : CycleColors.backgroundLight,
                    side: BorderSide(
                      color: signalReaction == reaction
                          ? CycleColors.primary
                          : borderColor,
                    ),
                    onSelected: (_) => onSelectReaction(
                      signalReaction == reaction ? null : reaction,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
