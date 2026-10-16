import 'package:flutter/material.dart';

import '../../../theme/cycle_theme.dart';

class SelectableTile extends StatelessWidget {
  const SelectableTile({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.activeColor,
  });

  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;
  final Color? activeColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = activeColor ?? theme.colorScheme.primary;
    final bgColor = selected
        ? color.withValues(alpha: isDark ? 0.24 : 0.12)
        : (isDark ? CycleColors.backgroundDark : CycleColors.backgroundLight);
    final borderColor = selected
        ? color
        : (isDark ? CycleColors.borderDark : CycleColors.borderLight);
    final fgColor = selected
        ? color
        : theme.colorScheme.onSurface.withValues(alpha: 0.85);
    final iconColor = selected
        ? color
        : theme.colorScheme.onSurface.withValues(alpha: 0.65);

    return Semantics(
      selected: selected,
      button: true,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: borderColor,
                width: selected ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: 18,
                    color: iconColor,
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: fgColor,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
