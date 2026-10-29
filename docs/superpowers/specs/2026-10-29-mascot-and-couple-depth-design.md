# Spec Desain: Fase 3.5 — Karakter Maskot Dinamis, Care Streak & Anniversary, serta Penyempurnaan UX Ruang Pasangan

**Date:** 2026-10-29  
**Project:** CycleApps (`siklus`)  
**Approach:** Pendekatan A (Pure Domain + CustomPainter Vector Mascot + Zero-Cost Firestore Sync)

---

## 1. Tujuan & Visi Produk

Menyelesaikan *roadmap* pengalaman emosional dan kedekatan pasangan pada aplikasi **CycleApps (`siklus`)** dengan menghadirkan:
1. **Karakter Maskot Pendamping Dinamis** (4 karakter menggemaskan berbasis *CustomPainter* & animasi partikel) yang berubah ekspresi serta dialognya mengikuti fase siklus (`CyclePhase`), suasana hati harian (`Mood`), dan peran pengguna (`isOwner` vs `isPartner`).
2. **Kedalaman Hubungan Pasangan (`LoveHeaderBadge` 2.0)**: menampilkan nama asli kedua pasangan, penghitung **Hari Bersama (`Anniversary Counter`)**, dan **Care Streak (`🔥 X Hari Berturut-turut`)** yang dihitung otomatis dari interaksi harian pasangan.
3. **Penyempurnaan UX Ruang Pasangan**: penandaan baca otomatis (`markInteractionsAsRead`), penghapusan stiker kustom via *long-press*, dan tombol kirim mandiri pada kolom pesan manis (`quickLoveNoteInput`).

---

## 2. Pilar 1: Karakter Maskot Pendamping Dinamis (`CycleMascot`)

### A. 4 Pilihan Karakter Maskot (`MascotCharacter`)
1. `mochiKitten` — **Mochi Kitten 🐱**: Kucing putih-pink berpipi gembul yang manja dan hangat.
2. `fluffyBunny` — **Fluffy Bunny 🐰**: Kelinci pastel bertelinga panjang yang lembut dan perhatian.
3. `babyDino` — **Baby Dino 🦕**: Dinosaurus kecil hijau mint yang ceria dan siap menjaga.
4. `chibiGirl` — **Chibi Girl 👧**: Karakter gadis imut ekspresif yang menggambarkan kondisi tubuh & hati.

### B. State Ekspresi & Visual Otomatis (`MascotMoodState`)
Berdasarkan `CyclePhase` saat ini dan catatan `DayEntry` hari ini (`todayEntry`):
- `comfyRest` (Fase **Menstruasi** atau gejala kram/lemas): Mata terpejam nyaman/manja, memakai kompres hangat/selimut kecil, dengan partikel hati lembut.
- `sparklingHappy` (Fase **Folikuler** atau mood `happy`/`calm`): Mata berbinar cerah, senyum lebar, dengan partikel bintang berkilau (*sparkles*).
- `glowingLove` (Fase **Ovulasi**): Pipi merona hangat, mata berbinar penuh cinta, dikelilingi gelembung hati melayang.
- `cravingPouty` (Fase **Luteal** atau mood `sensitive`/`anxious`/`irritable`/`sad`): Pipi gembul minta dimanja (*pouty/pleading*), membawa ikon camilan manis/pelukan.

### C. Interaksi di `HomeScreen` (`MascotCompanionCard`)
- Ditempatkan di `HomeScreen` tepat di atas `CycleDial`.
- Menampilkan:
  - **Avatar Ilustrasi Vector/Canvas Animasi** (`MascotIllustration`) yang bergerak naik-turun lembut (*floating animation*) dan memantul (*bounce*) saat diketuk.
  - **Speech Bubble Kontekstual**: Kalimat sapaan lucu dari sudut pandang maskot (berbeda untuk Pemilik Siklus vs Pasangan). Saat maskot diketuk (*tap*), kalimat berganti secara siklik dari daftar kutipan penyemangat/manja sesuai fase.
  - **Tombol "Ganti Maskot ✨"**: Membuka modal *bottom sheet* (`MascotPickerSheet`) untuk memilih 1 dari 4 karakter. Pilihan disimpan di field `selectedMascot` pada dokumen `profiles/{profileId}` sehingga HP pasangan ikut melihat karakter yang sama.

---

## 3. Pilar 2: `LoveHeaderBadge` 2.0 — Nama Pasangan, Anniversary, & Care Streak

### A. Model Data Profil (`CycleProfile`)
Menambahkan 3 field opsional dengan nilai *default* aman pada `CycleProfile`:
- `selectedMascot`: `MascotCharacter` (default: `MascotCharacter.mochiKitten`)
- `partnerName`: `String` (default: `''`)
- `anniversaryDate`: `DateTime?` (default: `null`)

### B. Kalkulator Care Streak & Anniversary (`CoupleStreakCalculator`)
- **`daysTogether(DateTime? anniversaryDate, DateTime today)`**:
  - Mengembalikan jumlah hari sejak `anniversaryDate` hingga `today` (minimal `1` hari jika tanggal sama/valid, atau `null` jika belum diatur).
- **`calculateStreak(List<CoupleInteraction> interactions, DateTime today)`**:
  - Mengekstrak himpunan tanggal unik (`yyyy-MM-dd`) dari `interactions.map((i) => dateKey(i.createdAt))`.
  - Menghitung jumlah hari berturut-turut mundur dari `today` (atau mulai dari `today - 1 hari` jika hari ini belum ada kiriman stiker tetapi kemarin ada, sehingga streak tidak langsung hangus di pagi hari).

### C. Tampilan & Dialog Edit di `LoveHeaderBadge`
- Menampilkan nama panggilan asli kedua pasangan (jika `partnerName` sudah diisi, menggantikan label generik `'Pasangan'`).
- Menampilkan baris *pill badges* di bawah indikator koneksi:
  - **Badge Anniversary:** `💕 X Hari Bersama` (atau `'Atur Tanggal Jadian 💕'` jika `anniversaryDate == null`).
  - **Badge Care Streak:** `🔥 X Hari Streak` (muncul aktif berwarna hangat jika streak > 0, atau `'Mulai Streak Hari Ini 🔥'` jika 0).
- Mengetuk `LoveHeaderBadge` atau tombol edit membuka `CoupleMetadataDialog` untuk menyimpan `partnerName` dan memilih `anniversaryDate`.

---

## 4. Pilar 3: Penyempurnaan UX Ruang Pasangan

1. **Auto-Read Interaksi Masuk (`markInteractionsAsRead`)**:
   - Di `ProfileRepository`, fungsi `markInteractionsAsRead({required String profileId, required String readerUid})` mencari dokumen di `profiles/{profileId}/interactions` yang `isRead == false` dan `senderUid != readerUid`, lalu melakukan batch update `isRead: true`.
   - Dipanggil otomatis oleh `CoupleSpaceScreen` ketika daftar interaksi memuat item yang belum dibaca oleh pengguna aktif.
2. **Hapus Stiker Kustom (`deleteCustomSticker` di UI)**:
   - Pada `CareStickerTray`, chip stiker kustom (bukan stiker *default*) mendukung aksi *long-press* / tombol hapus yang memunculkan dialog konfirmasi singkat lalu memanggil `ProfileRepository.deleteCustomSticker`.
3. **Kirim Catatan Manis Mandiri (`quickLoveNoteInput`)**:
   - Menambahkan `IconButton(icon: Icon(Icons.send_rounded))` sebagai `suffixIcon` pada `TextField` pesan manis di `CareStickerTray` (serta `onSubmitted`), sehingga pengguna dapat langsung mengirim pesan teks manis dengan emoji default `💌` tanpa harus mengetuk chip stiker.

---

## 5. Keamanan (`firestore.rules`) & Pengujian

- Memperbarui `firestore.rules` pada `match /profiles/{profileId}` agar daftar `affectedKeys().hasOnly([...])` menyertakan `'selectedMascot'`, `'partnerName'`, dan `'anniversaryDate'`.
- Seluruh fitur diuji dengan unit test (domain & repository) serta widget test tanpa merusak test yang sudah ada.
