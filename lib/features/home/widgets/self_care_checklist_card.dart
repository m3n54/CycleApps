import 'package:flutter/material.dart';

import '../../../domain/personal_care_advisor.dart';
import '../../../theme/cycle_theme.dart';

class SelfCareChecklistCard extends StatelessWidget {
  const SelfCareChecklistCard({
    super.key,
    required this.missions,
    required this.completedIds,
    required this.onToggleMission,
  });

  final List<SelfCareMission> missions;
  final Set<String> completedIds;
  final ValueChanged<String> onToggleMission;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? CycleColors.surfaceDark : CycleColors.surfaceLight;
    final borderColor = isDark ? CycleColors.borderDark : CycleColors.borderLight;

    final completedCount =
        missions.where((m) => completedIds.contains(m.id)).length;
    final totalCount = missions.length;
    final progress = totalCount == 0 ? 0.0 : completedCount / totalCount;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: CycleColors.primary.withValues(alpha: 0.04),
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
                  Icons.task_alt_rounded,
                  size: 18,
                  color: CycleColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Misi Self-Care Hari Ini',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: CycleColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$completedCount/$totalCount selesai',
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: CycleColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: CycleColors.primary.withValues(alpha: 0.12),
              valueColor: const AlwaysStoppedAnimation<Color>(CycleColors.primary),
            ),
          ),
          const SizedBox(height: 12),
          for (final mission in missions) ...[
            _MissionTile(
              mission: mission,
              isCompleted: completedIds.contains(mission.id),
              onTap: () => onToggleMission(mission.id),
            ),
            if (mission != missions.last) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _MissionTile extends StatelessWidget {
  const _MissionTile({
    required this.mission,
    required this.isCompleted,
    required this.onTap,
  });

  final SelfCareMission mission;
  final bool isCompleted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isCompleted
                ? CycleColors.primary.withValues(alpha: isDark ? 0.16 : 0.08)
                : (isDark
                    ? CycleColors.backgroundDark.withValues(alpha: 0.5)
                    : CycleColors.backgroundLight),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isCompleted
                  ? CycleColors.primary.withValues(alpha: 0.4)
                  : (isDark ? CycleColors.borderDark : CycleColors.borderLight),
            ),
          ),
          child: Row(
            children: [
              Text(
                mission.emoji,
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mission.title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        decoration:
                            isCompleted ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      mission.subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.68),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                isCompleted
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: isCompleted
                    ? CycleColors.primary
                    : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
