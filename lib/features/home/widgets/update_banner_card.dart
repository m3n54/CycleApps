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
      subtitle = updateState.downloadProgress > 0
          ? 'Sedang mengunduh APK (${updateState.downloadProgress}%). Installer akan terbuka otomatis.'
          : 'Menghubungkan ke server pembaruan...';
    } else if (isRestartRequired) {
      title = '🎉 Pembaruan Siap Dipasang!';
      subtitle =
          'File update selesai diunduh. Ketuk tombol untuk membuka jendela pemasangan Android.';
    } else {
      final versionName = updateState.releaseInfo?.versionName;
      title = versionName != null
          ? '✨ Pembaruan Siklus v$versionName Tersedia'
          : '✨ Pembaruan Siklus Tersedia';
      subtitle = updateState.releaseInfo?.releaseNotes != null &&
              updateState.releaseInfo!.releaseNotes.trim().isNotEmpty
          ? updateState.releaseInfo!.releaseNotes
          : 'Ada peningkatan & fitur baru untuk kalian berdua. Unduh instan tanpa perlu kirim file manual.';
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Mengunduh...',
                  style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  '${updateState.downloadProgress}%',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: CycleColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: updateState.downloadProgress > 0
                    ? updateState.downloadProgress / 100
                    : null,
                minHeight: 6,
                backgroundColor: CycleColors.primary.withValues(alpha: 0.15),
                color: CycleColors.primary,
              ),
            ),
          ] else ...[
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
                icon: Icon(
                  isRestartRequired ? Icons.install_mobile_rounded : Icons.download_rounded,
                  size: 16,
                ),
                label: Text(
                  isRestartRequired ? 'Pasang Sekarang' : 'Perbarui Sekarang',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
