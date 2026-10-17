import 'package:flutter/material.dart';

import '../../../state/update_controller.dart';
import '../../../theme/cycle_theme.dart';

class InAppUpdateDialog extends StatelessWidget {
  const InAppUpdateDialog({
    super.key,
    required this.updateState,
    required this.onDownload,
    required this.onDismiss,
  });

  final AppUpdateState updateState;
  final VoidCallback onDownload;
  final VoidCallback onDismiss;

  static Future<void> showIfAvailable({
    required BuildContext context,
    required AppUpdateState updateState,
    required VoidCallback onDownload,
    required VoidCallback onDismiss,
  }) async {
    if (updateState.phase != AppUpdatePhase.updateAvailable ||
        updateState.bannerDismissed) {
      return;
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: !updateState.isBusy,
      builder: (dialogCtx) => InAppUpdateDialog(
        updateState: updateState,
        onDownload: () {
          Navigator.of(dialogCtx).pop();
          onDownload();
        },
        onDismiss: () {
          Navigator.of(dialogCtx).pop();
          onDismiss();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final release = updateState.releaseInfo;
    final versionName = release?.versionName ?? 'Baru';
    final releaseNotes = release?.releaseNotes ??
        'Pembaruan fitur terbaru untuk kenyamanan Anda dan pasangan.';

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: CycleColors.primary.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.system_update_rounded,
              color: CycleColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pembaruan Siklus 🌸',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'Versi $versionName Tersedia',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: CycleColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Catatan Pembaruan:',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              releaseNotes,
              style: theme.textTheme.bodySmall?.copyWith(height: 1.4),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Aplikasi akan mengunduh dan memasang update otomatis di HP Anda tanpa kehilangan data.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: onDismiss,
          child: const Text('Nanti Saja'),
        ),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: CycleColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: onDownload,
          icon: const Icon(Icons.download_rounded, size: 18),
          label: const Text('Perbarui Sekarang', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}
