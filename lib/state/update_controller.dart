import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';

import '../data/app_updater_service.dart';

enum AppUpdatePhase {
  idle,
  checking,
  upToDate,
  updateAvailable,
  downloading,
  restartRequired,
  unavailable,
  error,
}

class AppUpdateState {
  const AppUpdateState({
    this.version = kAppVersion,
    this.isShorebirdAvailable = false,
    this.currentPatchNumber,
    this.nextPatchNumber,
    this.releaseInfo,
    this.downloadProgress = 0,
    this.phase = AppUpdatePhase.idle,
    this.bannerDismissed = false,
    this.statusMessage = '',
  });

  final String version;
  final bool isShorebirdAvailable;
  final int? currentPatchNumber;
  final int? nextPatchNumber;
  final AppReleaseInfo? releaseInfo;
  final int downloadProgress;
  final AppUpdatePhase phase;
  final bool bannerDismissed;
  final String statusMessage;

  bool get isBusy =>
      phase == AppUpdatePhase.checking || phase == AppUpdatePhase.downloading;

  bool get shouldShowBanner =>
      !bannerDismissed &&
      (phase == AppUpdatePhase.updateAvailable ||
          phase == AppUpdatePhase.downloading ||
          phase == AppUpdatePhase.restartRequired);

  String get versionSubtitle {
    if (releaseInfo != null) {
      return 'Versi $version • Pembaruan v${releaseInfo!.versionName} Tersedia';
    }
    if (currentPatchNumber != null) {
      return 'Versi $version • Patch #$currentPatchNumber (Auto-Update Aktif)';
    }
    return 'Versi $version • Auto-Update Aktif';
  }

  AppUpdateState copyWith({
    String? version,
    bool? isShorebirdAvailable,
    int? currentPatchNumber,
    bool clearCurrentPatch = false,
    int? nextPatchNumber,
    bool clearNextPatch = false,
    AppReleaseInfo? releaseInfo,
    bool clearReleaseInfo = false,
    int? downloadProgress,
    AppUpdatePhase? phase,
    bool? bannerDismissed,
    String? statusMessage,
  }) {
    return AppUpdateState(
      version: version ?? this.version,
      isShorebirdAvailable: isShorebirdAvailable ?? this.isShorebirdAvailable,
      currentPatchNumber: clearCurrentPatch
          ? null
          : (currentPatchNumber ?? this.currentPatchNumber),
      nextPatchNumber:
          clearNextPatch ? null : (nextPatchNumber ?? this.nextPatchNumber),
      releaseInfo: clearReleaseInfo
          ? null
          : (releaseInfo ?? this.releaseInfo),
      downloadProgress: downloadProgress ?? this.downloadProgress,
      phase: phase ?? this.phase,
      bannerDismissed: bannerDismissed ?? this.bannerDismissed,
      statusMessage: statusMessage ?? this.statusMessage,
    );
  }
}

class AppUpdateController extends StateNotifier<AppUpdateState> {
  AppUpdateController(this._service)
      : super(
          AppUpdateState(
            isShorebirdAvailable: _service.isAvailable,
          ),
        ) {
    unawaited(_initialize());
  }

  final AppUpdaterService _service;

  Future<void> _initialize() async {
    final available = _service.isAvailable;
    if (!available) {
      if (!mounted) return;
      state = state.copyWith(
        isShorebirdAvailable: false,
        phase: AppUpdatePhase.unavailable,
        statusMessage: 'Pengecekan pembaruan tidak aktif pada platform ini.',
      );
      return;
    }

    final currentPatch = await _service.readCurrentPatchNumber();
    final nextPatch = await _service.readNextPatchNumber();
    if (!mounted) return;

    state = state.copyWith(
      isShorebirdAvailable: true,
      currentPatchNumber: currentPatch,
      nextPatchNumber: nextPatch,
    );

    await checkForUpdates(manual: false);
  }

  Future<AppUpdateState> checkForUpdates({bool manual = true}) async {
    final available = _service.isAvailable;
    if (!available) {
      if (!mounted) return state;
      state = state.copyWith(
        isShorebirdAvailable: false,
        phase: AppUpdatePhase.unavailable,
        statusMessage: 'Pengecekan pembaruan tidak aktif pada platform ini.',
      );
      return state;
    }

    if (!mounted) return state;
    state = state.copyWith(
      isShorebirdAvailable: true,
      phase: AppUpdatePhase.checking,
      statusMessage: 'Mengecek pembaruan terbaru...',
    );

    try {
      final currentPatch = await _service.readCurrentPatchNumber();
      final status = await _service.checkForUpdate();
      final nextPatch = await _service.readNextPatchNumber();
      final releaseInfo = _service.latestReleaseInfo;
      if (!mounted) return state;

      switch (status) {
        case UpdateStatus.outdated:
          state = state.copyWith(
            currentPatchNumber: currentPatch,
            nextPatchNumber: nextPatch,
            releaseInfo: releaseInfo,
            phase: AppUpdatePhase.updateAvailable,
            bannerDismissed: manual ? false : state.bannerDismissed,
            statusMessage: releaseInfo != null
                ? 'Versi ${releaseInfo.versionName} siap diunduh! 🌸'
                : 'Ada pembaruan fitur Siklus baru yang siap diunduh!',
          );
        case UpdateStatus.restartRequired:
          state = state.copyWith(
            currentPatchNumber: currentPatch,
            nextPatchNumber: nextPatch,
            releaseInfo: releaseInfo,
            phase: AppUpdatePhase.restartRequired,
            bannerDismissed: manual ? false : state.bannerDismissed,
            statusMessage:
                'Pembaruan siap! Buka instalasi untuk memperbarui.',
          );
        case UpdateStatus.upToDate:
          state = state.copyWith(
            currentPatchNumber: currentPatch,
            nextPatchNumber: nextPatch,
            clearReleaseInfo: true,
            phase: AppUpdatePhase.upToDate,
            statusMessage: 'Aplikasi Siklus sudah menggunakan versi terbaru (v${state.version}).',
          );
        case UpdateStatus.unavailable:
          state = state.copyWith(
            currentPatchNumber: currentPatch,
            phase: AppUpdatePhase.unavailable,
            statusMessage: 'Layanan pembaruan belum tersedia pada perangkat ini.',
          );
      }
    } catch (_) {
      if (!mounted) return state;
      state = state.copyWith(
        phase: AppUpdatePhase.error,
        statusMessage: 'Gagal memeriksa pembaruan. Pastikan koneksi internet stabil.',
      );
    }
    return state;
  }

  Future<AppUpdateState> downloadAndApplyPatch() async {
    if (!_service.isAvailable) return state;
    if (!mounted) return state;

    state = state.copyWith(
      phase: AppUpdatePhase.downloading,
      downloadProgress: 0,
      bannerDismissed: false,
      statusMessage: 'Mengunduh pembaruan fitur terbaru...',
    );

    try {
      await _service.downloadUpdate(
        onProgress: (progress) {
          if (!mounted) return;
          state = state.copyWith(
            downloadProgress: progress,
            statusMessage: 'Mengunduh pembaruan ($progress%)...',
          );
        },
      );
      final nextPatch = await _service.readNextPatchNumber();
      if (!mounted) return state;
      state = state.copyWith(
        nextPatchNumber: nextPatch,
        downloadProgress: 100,
        phase: AppUpdatePhase.restartRequired,
        statusMessage:
            'Pembaruan selesai diunduh! Pemasangan sedang dibuka...',
      );
    } catch (_) {
      if (!mounted) return state;
      state = state.copyWith(
        phase: AppUpdatePhase.error,
        statusMessage: 'Gagal mengunduh pembaruan. Coba lagi beberapa saat lagi.',
      );
    }
    return state;
  }

  void dismissBanner() {
    if (!mounted) return;
    state = state.copyWith(bannerDismissed: true);
  }
}
