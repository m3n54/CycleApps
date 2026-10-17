# Spec Desain: Ruang Pasangan & Fitur Interaktif Saling Balas (Couple Space)

## 1. Latar Belakang & Masalah yang Diselesaikan
Sebelumnya, ketika akun pasangan login:
1. **Tampilan Beranda belum cukup membedakan peran**: tombol utama di HP cowok masih *"Catat Hari Ini"* (pencatatan haid), padahal cowok membutuhkan tombol aksi kepedulian seperti *"Kirim Perhatian ke Pacar"*.
2. **Belum ada ruang/tab khusus yang intim**: fitur sinyal pasangan hanya berupa chip pilihan kecil di Beranda yang tersembunyi jika sinyal belum aktif.
3. **Akun yang belum memasukkan kode undangan**: akun baru otomatis menjadi pemilik profil kosong sendiri sehingga tidak melihat data pasangannya.

## 2. Arsitektur Navigasi Aplikasi (4 Tab Terfokus)
Menu navigasi bawah (*Bottom Navigation Bar*) di [`HomeShell`](file:///C:/Menza/CycleApps/lib/features/home/home_shell.dart) disederhanakan menjadi 4 tab fokus:
1. **Tab 0: Beranda (Home)** — Pusat informasi harian siklus wanita & pendampingan pasangan.
2. **Tab 1: Kalender (Calendar)** — Prediksi fase bulanan & riwayat pencatatan.
3. **Tab 2: Ruang Pasangan 💑 (Couple Space - Baru)** — Tab interaktif saling kirim stiker perhatian, balasan reaksi cepat, dan catatan manis secara *real-time*.
4. **Tab 3: Pengaturan & Profil (Settings)** — Tema, undang/gabung kode pasangan, versi aplikasi, dan akun.
*(Catatan: Halaman analisis Wawasan / Insights tetap dapat diakses melalui kartu ringkasan atau tombol "Lihat Analisis Siklus Lengkap" di Beranda/Kalender).*

## 3. Diferensiasi Tampilan Beranda: Pemilik vs Pasangan
### A. Tampilan Pemilik Siklus (Cewek)
- Sapaan kontekstual cerdas (*"Halo, [Nama] 🌸"* atau mengingat catatan gejala/mood kemarin).
- Hero Cycle Dial (fase siklus, hari ke-X).
- Tombol Utama: **"Catat Hari Ini"** (gejala, mood, aliran menstruasi).
- Penjelas Tubuh Hormonal (*"Kenapa Tubuhmu Merasa Begini?"*).
- Checklist 3 Misi *Self-Care* Harian sesuai fase.
- Kartu Sinyal Pasangan (*"Sinyal aktif & balasan dari pacar"*).

### B. Tampilan Pasangan Pendamping (Cowok)
- Sapaan pendamping siaga (*"Mendampingi [Nama Pacar] 💑"*).
- Hero Cycle Dial yang disesuaikan (*"Fase [Nama Fase] • [Nama Pacar] sedang berada di hari ke-X"*).
- **TIDAK ADA tombol "Catat Haid Hari Ini"**, diganti dengan tombol aksi utama:
  **"Kirim Perhatian ke [Nama Pacar] 💖"** (langsung membuka modal stiker perhatian & love note).
- Kartu **"Panduan Pasangan Hari Ini"** (penjelasan kondisi fisik pacar, rekomendasi hal yang harus dilakukan & hal yang sebaiknya dihindari).
- Kartu Sinyal Aktif dari pacar (jika ada kode/kebutuhan yang dikirim pacar hari ini).

## 4. Desain Tab "Ruang Pasangan 💑" (Couple Space)
Jika akun sudah terhubung:
1. **Header Avatar Koneksi**:
   - Menampilkan inisial/nama kedua pasangan yang saling terhubung dengan ikon hati berdenyut (*pulsing heart connection badge*).
2. **Koleksi Stiker Perhatian 1-Ketuk (Care Stickers)**:
   - 🧸 *Kompres Hangat Siap*
   - 🧋 *Boba / Jajan Favorit*
   - 🤗 *Peluk Erat & Sayang*
   - 💆‍♂️ *Pijat Punggung / Bahu*
   - 👂 *Aku Siap Dengerin Curhat*
   - 🍫 *Camilan Cokelat Manis*
   - 💤 *Istirahat Cukup Sayang*
   - 🥺 *Cepat Pulang / Kangen*
3. **Kirim Catatan Manis (Love Note)**:
   - Form input teks manis singkat (maks 100 karakter) yang bisa dikirim bersamaan atau terpisah.
4. **Live Interaction Feed (Feed Saling Balas Real-time)**:
   - Menampilkan pesan/stiker terakhir yang dikirim lengkap dengan waktu kirim (*"10 menit lalu"*).
   - Tombol balasan reaksi 1-klik untuk pihak penerima:
     - 🥰 *"Makasih Sayang"*
     - 🤤 *"Beneran Mau Boba!"*
     - 🥺 *"Lagi Sensitif Banget"*
     - 💖 *"Kamu Terbaik"*
5. **State Belum Terhubung (Empty/Unlinked State)**:
   - Jika akun belum memiliki pasangan (`memberUids.length < 2`), Ruang Pasangan menampilkan kartu ramah:
     - *"Hubungkan dengan Pasangan"*
     - Tombol **"Buat & Salin Kode Undangan"**
     - Tombol **"Gabung dengan Kode Pasangan"**

## 5. Model Data & Firestore Security Rules
### Model Data `CoupleInteraction`
- `id`: String unik dokumen
- `senderUid`: String UID pengirim
- `senderName`: String nama pengirim
- `sticker`: String identifier stiker (misal `'hug'`, `'boba'`, `'massage'`)
- `message`: String? pesan teks singkat opsional
- `reaction`: String? balasan reaksi dari pasangan (misal `'thanks'`, `'love'`)
- `createdAt`: DateTime / Timestamp Firestore
- `reactedAt`: DateTime? / Timestamp Firestore

### Firestore Path
- Disimpan di subkoleksi: `/profiles/{profileId}/interactions/{interactionId}`
- Dan ringkasan status di dokumen profil `/profiles/{profileId}`:
  - `lastInteraction`: Map berisi data interaksi terakhir untuk tampilan cepat Beranda.

### Firestore Rules
Perluasan pada `firestore.rules`:
- Mengizinkan `read`, `create`, `update` pada `/profiles/{profileId}/interactions/{interactionId}` untuk pengguna yang termasuk dalam `profile.memberUids`.

## 6. Rencana Pengujian
- **Unit Test Domain & Repository:**
  - `CoupleInteraction` serialization/deserialization.
  - `ProfileRepository.sendInteraction()` dan `ProfileRepository.respondInteraction()`.
- **Widget Test:**
  - `HomeScreen` membedakan tombol "Catat Hari Ini" (Pemilik) vs "Kirim Perhatian" (Pasangan).
  - `HomeShell` menampilkan 4 tab termasuk tab "Ruang Pasangan".
  - `CoupleSpaceScreen` merender stiker perhatian, form catatan manis, dan feed balasan interaksi.
