import 'package:flutter/material.dart';

import '../../../state/update_controller.dart';
import '../../../theme/cycle_theme.dart';

class UpdateBannerCard extends StatelessWidget {
  const UpdateBannerCard({
    super.key,
    required this.updateState,
    required this.onDownload,
    required this.onDismiss,
  });

  final AppUpdateState updateState;
  final VoidCallback onDownload;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    if (!updateState.shouldShowBanner) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final isDownloading = updateState.phase == AppUpdatePhase.downloading;
    final isRestartRequired =
        updateState.phase == AppUpdatePhase.restartRequired;

    final String title;
    final String subtitle;
    if (isDownloading) {
      title = '⏳ Mengunduh Pembaruan...';
      subtitle =
          'Mohon tunggu sebentar, fitur terbaru sedang diunduh di latar belakang.';
    } else if (isRestartRequired) {
      title = '🎉 Pembaruan Siap Digunakan!';
      subtitle =
          'Tutup dan buka kembali aplikasi Siklus untuk menerapkan fitur terbaru.';
    } else {
      title = '✨ Pembaruan Siklus Tersedia';
      subtitle =
          'Ada peningkatan & fitur baru untuk kalian berdua. Unduh instan tanpa perlu instal ulang.';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [
            CycleColors.primary.withValues(alpha: 0.14),
            CycleColors.accent.withValues(alpha: 0.14),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: CycleColors.primary.withValues(alpha: 0.32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: CycleColors.primary.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isRestartRequired
                      ? Icons.check_circle_outline_rounded
                      : Icons.system_update_rounded,
                  size: 20,
                  color: CycleColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.78),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isDownloading)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Sembunyikan',
                  onPressed: onDismiss,
                  icon: const Icon(Icons.close_rounded, size: 18),
                ),
            ],
          ),
          if (isDownloading) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: const LinearProgressIndicator(minHeight: 6),
            ),
          ] else if (!isRestartRequired) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: CycleColors.primary,
                  foregroundColor: Colors.white,
                  visualDensity: VisualDensity.compact,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: onDownload,
                icon: const Icon(Icons.download_rounded, size: 16),
                label: const Text(
                  'Perbarui Sekarang',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
