import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:ota_update/ota_update.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';

/// Versi aplikasi saat ini (sesuai `pubspec.yaml`).
const String kAppVersion = '1.0.1';
const int kAppVersionCode = 2;

/// Informasi rilis aplikasi terbaru dari remote (Firestore / GitHub).
class AppReleaseInfo {
  const AppReleaseInfo({
    required this.versionCode,
    required this.versionName,
    required this.releaseNotes,
    required this.downloadUrl,
    this.forceUpdate = false,
  });

  final int versionCode;
  final String versionName;
  final String releaseNotes;
  final String downloadUrl;
  final bool forceUpdate;

  factory AppReleaseInfo.fromMap(Map<String, dynamic> map) {
    return AppReleaseInfo(
      versionCode: (map['versionCode'] as num?)?.toInt() ?? 1,
      versionName: (map['versionName'] as String?) ?? '1.0.0',
      releaseNotes: (map['releaseNotes'] as String?) ?? 'Pembaruan aplikasi Siklus.',
      downloadUrl: (map['downloadUrl'] as String?) ?? '',
      forceUpdate: (map['forceUpdate'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'versionCode': versionCode,
        'versionName': versionName,
        'releaseNotes': releaseNotes,
        'downloadUrl': downloadUrl,
        'forceUpdate': forceUpdate,
      };
}

/// Abstraksi layanan OTA Update (In-App Direct APK & Shorebird Code Push)
abstract class AppUpdaterService {
  /// Apakah engine OTA aktif pada build saat ini.
  bool get isAvailable;

  /// Informasi rilis terbaru yang ditemukan saat pengecekan (null jika belum ada / up to date).
  AppReleaseInfo? get latestReleaseInfo;

  /// Membaca nomor patch aktif saat ini (null jika belum ada patch / rilis dasar).
  Future<int?> readCurrentPatchNumber();

  /// Membaca nomor patch berikutnya yang sudah terunduh dan menunggu restart.
  Future<int?> readNextPatchNumber();

  /// Mengecek apakah ada versi baru di Firestore atau server Shorebird.
  Future<UpdateStatus> checkForUpdate();

  /// Mengunduh update terbaru secara in-app dengan pelaporan progress.
  Future<void> downloadUpdate({void Function(int progress)? onProgress});
}

class CombinedAppUpdaterService implements AppUpdaterService {
  CombinedAppUpdaterService({
    this.firestore,
    ShorebirdUpdater? updater,
  })  : _updater = updater ?? ShorebirdUpdater();

  final FirebaseFirestore? firestore;
  final ShorebirdUpdater _updater;
  AppReleaseInfo? _latestReleaseInfo;

  @override
  AppReleaseInfo? get latestReleaseInfo => _latestReleaseInfo;

  @override
  bool get isAvailable {
    if (kIsWeb) return false;
    if (defaultTargetPlatform == TargetPlatform.android) return true;
    try {
      return _updater.isAvailable;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<int?> readCurrentPatchNumber() async {
    try {
      if (_updater.isAvailable) {
        final patch = await _updater.readCurrentPatch();
        return patch?.number;
      }
    } catch (_) {}
    return null;
  }

  @override
  Future<int?> readNextPatchNumber() async {
    try {
      if (_updater.isAvailable) {
        final patch = await _updater.readNextPatch();
        return patch?.number;
      }
    } catch (_) {}
    return null;
  }

  @override
  Future<UpdateStatus> checkForUpdate() async {
    if (!isAvailable) return UpdateStatus.unavailable;

    // 1. Cek Firestore remote version config (Pilihan 1 In-App Auto-Downloader)
    try {
      FirebaseFirestore? db = firestore;
      if (db == null) {
        try {
          db = FirebaseFirestore.instance;
        } catch (_) {
          db = null;
        }
      }
      if (db != null) {
        final doc = await db.collection('app_config').doc('version').get();
        if (doc.exists && doc.data() != null) {
          final release = AppReleaseInfo.fromMap(doc.data()!);
          if (release.versionCode > kAppVersionCode && release.downloadUrl.isNotEmpty) {
            _latestReleaseInfo = release;
            return UpdateStatus.outdated;
          }
        }
      }
    } catch (e) {
      debugPrint('Firestore update check error: $e');
    }

    // 2. Cek Shorebird jika engine tersedia
    try {
      if (_updater.isAvailable) {
        return await _updater.checkForUpdate();
      }
    } catch (_) {}

    return UpdateStatus.upToDate;
  }

  @override
  Future<void> downloadUpdate({void Function(int progress)? onProgress}) async {
    if (!isAvailable) return;

    // Jika ada rilis APK langsung via Firestore
    if (_latestReleaseInfo != null && _latestReleaseInfo!.downloadUrl.isNotEmpty) {
      final completer = Completer<void>();
      try {
        OtaUpdate()
            .execute(
              _latestReleaseInfo!.downloadUrl,
              destinationFilename: 'siklus-release.apk',
            )
            .listen(
              (OtaEvent event) {
                if (event.status == OtaStatus.DOWNLOADING) {
                  final progress = int.tryParse(event.value ?? '0') ?? 0;
                  onProgress?.call(progress);
                } else if (event.status == OtaStatus.INSTALLING) {
                  onProgress?.call(100);
                  if (!completer.isCompleted) completer.complete();
                } else if (event.status == OtaStatus.ALREADY_RUNNING_ERROR ||
                    event.status == OtaStatus.PERMISSION_NOT_GRANTED_ERROR ||
                    event.status == OtaStatus.INTERNAL_ERROR ||
                    event.status == OtaStatus.DOWNLOAD_ERROR) {
                  if (!completer.isCompleted) {
                    completer.completeError(
                      Exception('Gagal mengunduh pembaruan (${event.status}): ${event.value}'),
                    );
                  }
                }
              },
              onError: (Object err) {
                if (!completer.isCompleted) completer.completeError(err);
              },
            );
        await completer.future;
      } catch (e) {
        debugPrint('In-app OTA download error: $e');
        rethrow;
      }
      return;
    }

    // Fallback Shorebird updater
    try {
      if (_updater.isAvailable) {
        await _updater.update();
      }
    } catch (_) {}
  }
}
