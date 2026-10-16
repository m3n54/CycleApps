# Panduan Distribusi & Auto-Update Android (Shorebird OTA + Keystore Tetap)

Dokumen ini menjelaskan cara mem-build aplikasi **Siklus** untuk HP Android Anda dan pasangan, serta cara mengirim pembaruan (update) secara otomatis **tanpa perlu uninstall atau kirim file APK berulang-ulang**.

---

## 1. Mengapa Sebelumnya Update APK Harus Uninstall Dulu?

Android menolak menimpa (update) aplikasi jika:
1. **Kunci Tanda Tangan (Keystore) berbeda** (misalnya berpindah dari mode *debug* ke *release* atau berganti komputer).
2. **`versionCode` di `pubspec.yaml` lebih kecil** daripada versi yang sudah terinstal di HP.

### Solusi yang Sudah Dikonfigurasi di Proyek Ini:
- **Keystore Rilis Permanen**: File `android/app/siklus-release-key.jks` dan `android/key.properties` sudah dibuat dan dihubungkan ke [`android/app/build.gradle.kts`](../android/app/build.gradle.kts). Selama file `.jks` ini disimpan, Android **tidak akan pernah meminta uninstall** saat Anda menginstal APK versi baru.
  > **Penting:** Simpan cadangan (backup) file `android/app/siklus-release-key.jks` dan `android/key.properties` di tempat aman (misal Google Drive pribadi Anda) karena file tersebut sengaja diabaikan oleh Git (`.gitignore`) demi keamanan.
- **Shorebird Code Push (OTA Update)**: Sudah diintegrasikan melalui [`AppUpdaterService`](../lib/data/app_updater_service.dart), [`AppUpdateController`](../lib/state/update_controller.dart), [`UpdateBannerCard`](../lib/features/home/widgets/update_banner_card.dart) di Beranda, serta kartu **Versi Aplikasi Siklus** di [`SettingsScreen`](../lib/features/settings/settings_screen.dart).

---

## 2. Persiapan Awal Shorebird (Cukup Sekali Saja di Laptop Anda)

1. **Instal Shorebird CLI di PowerShell**:
   ```powershell
   Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
   irm https://raw.githubusercontent.com/shorebirdtech/install/main/install.ps1 | iex
   ```
2. **Login ke Akun Shorebird (Gratis untuk penggunaan pribadi/pasangan)**:
   ```powershell
   shorebird login
   ```
3. **Inisialisasi Shorebird di Proyek `CycleApps`**:
   ```powershell
   shorebird init
   ```
   *(Perintah ini akan membuat file `shorebird.yaml` berisi `app_id` unik aplikasi Anda).*

---

## 3. Langkah 1: Build & Kirim APK Pertama Kali ke Pasangan

Saat pertama kali ingin menginstal aplikasi di HP Anda dan pasangan, jalankan:

```powershell
shorebird release android --artifact=apk
```

- File APK hasil build akan berada di:
  `build/app/outputs/flutter-apk/app-release.apk`
- Kirimkan file `app-release.apk` tersebut lewat WhatsApp/Telegram ke pasangan Anda dan instal **satu kali saja**.

---

## 4. Langkah 2: Kirim Update Fitur & Tampilan Otomatis (Sehari-hari)

Setiap kali Anda selesai mengubah kode Dart/Flutter (misalnya menambah fitur, mengubah warna, memperbaiki teks, atau menambah kartu baru di Beranda):

1. **Cukup jalankan 1 perintah ini di terminal (TIDAK perlu kirim file APK lagi):**
   ```powershell
   shorebird patch android
   ```
2. **Apa yang terjadi di HP pasangan Anda?**
   - Saat pasangan membuka aplikasi **Siklus**, aplikasi otomatis mendeteksi patch baru dan menampilkan banner manis di Beranda:
     > **"✨ Pembaruan Siklus Tersedia — Ketuk Perbarui Sekarang"**
   - Atau pasangan bisa menekan **"Cek Pembaruan Aplikasi"** di menu **Pengaturan**.
   - Setelah tombol diketuk (hanya butuh beberapa detik), pembaruan langsung aktif saat aplikasi dibuka ulang — **tanpa download APK dan tanpa uninstall!**

---

## 5. Kapan Harus Kirim File APK Baru Lagi?

Anda hanya perlu membuat rilis APK baru (`shorebird release android --artifact=apk`) jika Anda:
- Menambah plugin/library Android native baru (misal izin kamera/sensor baru di `AndroidManifest.xml`), atau
- Meng-upgrade versi Flutter SDK.

Jika hal itu terjadi:
1. Naikkan angka versi di [`pubspec.yaml`](../pubspec.yaml), misalnya dari `version: 1.0.0+1` menjadi `version: 1.0.1+2` (dan sesuaikan `kAppVersion` di [`lib/data/app_updater_service.dart`](../lib/data/app_updater_service.dart)).
2. Jalankan:
   ```powershell
   shorebird release android --artifact=apk
   ```
3. Kirim APK tersebut ke pasangan. Karena sudah memakai **Keystore Tetap (`siklus-release-key.jks`)**, saat pasangan mengetuk file APK tersebut, Android hanya akan menampilkan tombol **"Update"** (menimpa otomatis tanpa menghapus data atau akun!).
