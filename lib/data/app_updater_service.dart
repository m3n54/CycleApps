import 'package:flutter/foundation.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';

/// Versi aplikasi saat ini (sesuai `pubspec.yaml`).
const String kAppVersion = '1.0.0+1';

/// Abstraksi layanan OTA Update (Shorebird Code Push) agar aman di semua
/// platform (Android, Web, Debug) dan mudah diuji pada widget/unit test.
abstract class AppUpdaterService {
  /// Apakah engine Shorebird aktif pada build saat ini.
  bool get isAvailable;

  /// Membaca nomor patch aktif saat ini (null jika belum ada patch / rilis dasar).
  Future<int?> readCurrentPatchNumber();

  /// Membaca nomor patch berikutnya yang sudah terunduh dan menunggu restart.
  Future<int?> readNextPatchNumber();

  /// Mengecek apakah ada patch baru di server Shorebird.
  Future<UpdateStatus> checkForUpdate();

  /// Mengunduh patch terbaru di latar belakang.
  Future<void> downloadUpdate();
}

class ShorebirdAppUpdaterService implements AppUpdaterService {
  ShorebirdAppUpdaterService({ShorebirdUpdater? updater})
      : _updater = updater ?? ShorebirdUpdater();

  final ShorebirdUpdater _updater;

  @override
  bool get isAvailable {
    if (kIsWeb) return false;
    try {
      return _updater.isAvailable;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<int?> readCurrentPatchNumber() async {
    if (!isAvailable) return null;
    try {
      final patch = await _updater.readCurrentPatch();
      return patch?.number;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<int?> readNextPatchNumber() async {
    if (!isAvailable) return null;
    try {
      final patch = await _updater.readNextPatch();
      return patch?.number;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<UpdateStatus> checkForUpdate() async {
    if (!isAvailable) return UpdateStatus.unavailable;
    return _updater.checkForUpdate();
  }

  @override
  Future<void> downloadUpdate() async {
    if (!isAvailable) return;
    await _updater.update();
  }
}
