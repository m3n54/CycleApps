import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';
import 'package:siklus/data/app_updater_service.dart';
import 'package:siklus/domain/cycle_profile.dart';
import 'package:siklus/domain/day_entry.dart';
import 'package:siklus/features/home/home_screen.dart';
import 'package:siklus/features/home/widgets/update_banner_card.dart';
import 'package:siklus/features/settings/settings_screen.dart';
import 'package:siklus/state/providers.dart';
import 'package:siklus/theme/cycle_theme.dart';

class FakeAppUpdaterService implements AppUpdaterService {
  FakeAppUpdaterService({
    this.available = true,
    this.currentPatch = 1,
    this.nextPatch,
    this.releaseInfo,
    this.status = UpdateStatus.upToDate,
  });

  bool available;
  int? currentPatch;
  int? nextPatch;
  AppReleaseInfo? releaseInfo;
  UpdateStatus status;
  int downloadCalls = 0;

  @override
  bool get isAvailable => available;

  @override
  AppReleaseInfo? get latestReleaseInfo => releaseInfo;

  @override
  Future<int?> readCurrentPatchNumber() async => currentPatch;

  @override
  Future<int?> readNextPatchNumber() async => nextPatch;

  @override
  Future<UpdateStatus> checkForUpdate() async => status;

  @override
  Future<void> downloadUpdate({void Function(int progress)? onProgress}) async {
    downloadCalls++;
    onProgress?.call(50);
    onProgress?.call(100);
    nextPatch = (currentPatch ?? 0) + 1;
    status = UpdateStatus.restartRequired;
  }
}

void main() {
  testWidgets(
    'HomeScreen menampilkan UpdateBannerCard saat ada patch baru dan mengunduh saat tombol diketuk',
    (tester) async {
      final fakeUpdater = FakeAppUpdaterService(
        available: true,
        currentPatch: 2,
        releaseInfo: const AppReleaseInfo(
          versionCode: 3,
          versionName: '1.0.2',
          releaseNotes: 'Fitur baru dan perbaikan stabilitas.',
          downloadUrl: 'https://example.com/app.apk',
        ),
        status: UpdateStatus.outdated,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appUpdaterServiceProvider.overrideWithValue(fakeUpdater),
            todayProvider.overrideWithValue(DateTime(2026, 4, 10)),
            activeProfileIdProvider.overrideWith((ref) => Stream.value('p1')),
            activeProfileProvider.overrideWith(
              (ref) => Stream.value(
                const CycleProfile(
                  id: 'p1',
                  name: 'Nata',
                  ownerUid: 'u1',
                  memberUids: ['u1'],
                ),
              ),
            ),
            dayEntriesProvider.overrideWith(
              (ref) => Stream.value(const <DayEntry>[]),
            ),
          ],
          child: MaterialApp(
            theme: CycleTheme.lightTheme,
            home: const HomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(UpdateBannerCard), findsOneWidget);
      expect(find.textContaining('Pembaruan Siklus v1.0.2 Tersedia'), findsWidgets);
      expect(find.text('Perbarui Sekarang'), findsWidgets);

      await tester.tap(find.text('Perbarui Sekarang').last);
      await tester.pumpAndSettle();

      expect(fakeUpdater.downloadCalls, 1);
      expect(find.textContaining('Pembaruan Siap Dipasang!'), findsOneWidget);
    },
  );

  testWidgets(
    'SettingsScreen menampilkan nomor patch Shorebird dan memeriksa update saat diketuk',
    (tester) async {
      final fakeUpdater = FakeAppUpdaterService(
        available: true,
        currentPatch: 3,
        status: UpdateStatus.upToDate,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appUpdaterServiceProvider.overrideWithValue(fakeUpdater),
            activeProfileIdProvider.overrideWith((ref) => Stream.value('p1')),
            activeProfileProvider.overrideWith(
              (ref) => Stream.value(
                const CycleProfile(
                  id: 'p1',
                  name: 'Nata',
                  ownerUid: 'u1',
                  memberUids: ['u1', 'u2'],
                ),
              ),
            ),
          ],
          child: MaterialApp(
            theme: CycleTheme.lightTheme,
            home: const SettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Versi Aplikasi Siklus'), findsOneWidget);
      expect(
        find.text('Versi 1.0.1 • Patch #3 (Auto-Update Aktif)'),
        findsOneWidget,
      );
      expect(find.text('Cek Pembaruan Aplikasi'), findsOneWidget);

      await tester.tap(find.text('Cek Pembaruan Aplikasi'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('sudah menggunakan versi terbaru'),
        findsOneWidget,
      );
    },
  );
}
