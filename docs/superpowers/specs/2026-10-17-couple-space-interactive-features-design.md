# Spec Desain: Ruang Pasangan & Fitur Interaktif Saling Balas (Couple Space)

## 1. Latar Belakang & Masalah yang Diselesaikan
Berdasarkan pengujian nyata di perangkat, terdapat beberapa kendala mendasar pada pengalaman pengguna:
1. **Tampilan Beranda belum membedakan peran**: Di HP cowok, tombol utama yang muncul masih *"Catat Hari Ini"* (pencatatan haid), padahal cowok membutuhkan tombol aksi pendampingan nyata seperti *"Kirim Perhatian ke Pacar"*.
2. **Belum ada ruang intim yang interaktif**: Sinyal perhatian sebelumnya hanya berupa pilihan chip kecil di Beranda yang tersembunyi jika sinyal belum aktif.
3. **Akun yang belum memasukkan kode**: Pengguna yang login dengan email berbeda otomatis memiliki profil sendiri sehingga tidak melihat data pasangan sampai mereka memasukkan kode undangan.
4. **Bahasa interaksi perlu lebih lucu dan personal**: Pasangan menginginkan stiker perhatian dan reaksi yang lebih manja, menggemaskan, serta dapat dikustomisasi sendiri (bahasa cinta / *inside jokes* mereka).

---

## 2. Arsitektur Navigasi Aplikasi (4 Tab Terfokus)
Menu navigasi bawah (*Bottom Navigation Bar*) di [`HomeShell`](file:///C:/Menza/CycleApps/lib/features/home/home_shell.dart) diatur menjadi 4 tab fokus:
1. **Tab 0: Beranda (Home)** — Pusat informasi harian siklus wanita & pendampingan pasangan.
2. **Tab 1: Kalender (Calendar)** — Prediksi fase bulanan & riwayat pencatatan.
3. **Tab 2: Ruang Pasangan 💑 (Couple Space - Baru)** — Tab interaktif saling kirim stiker perhatian, balasan reaksi cepat, dan catatan manis secara *real-time*. Dilengkapi **Badge Titik Hati Merah (🔴💖)** saat ada pesan/stiker baru dari pasangan yang belum dibaca.
4. **Tab 3: Pengaturan & Profil (Settings)** — Tema, undang/gabung kode pasangan, versi aplikasi, dan akun.
*(Catatan: Halaman analisis Wawasan / Insights tetap dapat diakses melalui kartu ringkasan atau tombol "Lihat Analisis Siklus Lengkap" di Beranda/Kalender).*

---

## 3. Diferensiasi Tampilan Beranda: Pemilik vs Pasangan
### A. Tampilan Pemilik Siklus (Cewek)
- Sapaan kontekstual cerdas (*"Halo, [Nama] 🌸"* atau sapaan hangat yang mengingat catatan gejala/mood kemarin).
- Hero Cycle Dial (fase siklus, hari ke-X).
- Tombol Utama: **"Catat Hari Ini"** (gejala, mood, aliran menstruasi).
- Penjelas Tubuh Hormonal (*"Kenapa Tubuhmu Merasa Begini?"*).
- Checklist 3 Misi *Self-Care* Harian sesuai fase.
- Kartu Sinyal Pasangan (*"Sinyal aktif & balasan dari pacar"*).
- **Banner Notifikasi Perhatian:** Jika pacar baru saja mengirim perhatian/stiker dari Ruang Pasangan, muncul banner manis di bagian atas Beranda: *"💌 [Nama Pacar] baru saja mengirim perhatian! Ketuk untuk melihat & membalas"*.

### B. Tampilan Pasangan Pendamping (Cowok)
- Sapaan pendamping siaga (*"Mendampingi [Nama Pacar] 💑"*).
- Hero Cycle Dial yang disesuaikan (*"Fase [Nama Fase] • [Nama Pacar] sedang berada di hari ke-X"*).
- **TIDAK ADA tombol "Catat Haid Hari Ini"**, diganti dengan tombol aksi utama:
  **"Kirim Perhatian ke [Nama Pacar] 💖"** (langsung membuka modal stiker perhatian & love note).
- Kartu **"Panduan Pasangan Hari Ini"** (penjelasan kondisi fisik pacar, rekomendasi hal yang harus dilakukan & hal yang sebaiknya dihindari).
- Kartu Sinyal Aktif dari pacar (kebutuhan fisik/emosional yang dikirim pacar hari ini).
- **Banner Notifikasi Perhatian:** Muncul saat cewek membalas atau mengirimkan sinyal perhatian.

---

## 4. Desain Tab "Ruang Pasangan 💑" (Interactive Love Space)

### A. Header Koneksi Pasangan
- Menampilkan foto/inisial kedua pasangan yang saling terhubung dengan badge hati cinta berdenyut (*pulsing love connection*).
- Status koneksi: *"Terhubung & Saling Menjaga"* atau jumlah hari bersama.

### B. Koleksi Stiker Perhatian Bawaan (Default Preset - Super Lucu & Menggemaskan)
- 🧸 *"Puk-puk kepala & peluk eratt 🤗"*
- 🧋 *"Boba / jajan favorit meluncuurr! 🛵💨"*
- 💆‍♂️ *"Sesi pijat punggung & bahu siap! ✨"*
- 👂 *"Aku pasang telinga, mau curhat apa sayaang? 🥺"*
- 🍫 *"Camilan manis anti-badmood buat kamu 🍫💖"*
- 🧸 *"Kompres hangat udah siap di kasur 🛋️"*
- 💤 *"Tidur yuk, jangan begadang cantikk 😴"*
- 🥺 *"Cepat pulang yaa, kangeen bangett 🥺"*

### C. Preset Balasan Reaksi Manja (1-Klik)
- 🧋 *"Benerannn mawuuuu 🧋✨"*
- 🥺 *"Aaaaa mauu ditemenin 🥺👉👈"*
- 💖 *"Loveee youu soo muchh 💖🥹"*
- 🥰 *"Makasih banyaakk sayangkuuu 🥰"*
- 🛌 *"Mode mager parah, usap-usap duluu 🦥"*
- 🌸 *"Hatiku langsung adem denger ini 🌸"*

### D. Fitur Kustomisasi Stiker Pribadi (Custom Quick Stickers & Reactions)
- Terdapat tombol **"+ Tambah Stiker"** di samping deretan stiker.
- Membuka modal bottom sheet cepat:
  - Pilihan Emoji lucu (grid emoji ramah: 🍜, 🍦, 🐶, 🐱, 🥐, 🍓, 💌, dll).
  - Kolom teks pendek (maks 35 karakter, misal: *"Mau seblak level 3"*, *"Cium jauh duluu"*).
  - Tipe stiker: *Kirim Perhatian* atau *Balasan Cepat*.
- Data tersimpan di Firestore pada profil pasangan dan otomatis tersinkronisasi di kedua HP.

### E. Interactive Love Timeline (Feed Riwayat Saling Balas Real-Time)
- Format kartu/gelembung waktu (*timeline cards*):
  - Emoji stiker besar dengan animasi lembut.
  - Teks perhatian / pesan manis.
  - Nama pengirim & waktu kirim (*"5 menit lalu"*).
  - **Tombol Balasan Cepat Langsung di Kartu:** Jika pengguna adalah penerima, muncul deretan tombol chip reaksi (*"Benerann mawuuuu 🧋"*, *"Loveee youu 💖"*) yang dapat diketuk dalam 1 klik untuk langsung membalas.
  - Balasan yang terkirim langsung tersemat di kartu interaksi tersebut.

### F. State Belum Terhubung (Unlinked State)
- Jika akun belum terhubung dengan pasangan (`memberUids.length < 2`), tab Ruang Pasangan menampilkan kartu ramah:
  - *"Ruang Pasangan Belum Terhubung"*
  - Penjelasan manfaat saling terhubung.
  - Tombol **"Buat & Salin Kode Undangan"**
  - Tombol **"Gabung dengan Kode Pasangan"**

---

## 5. Model Data & Arsitektur Firestore

### A. Model `CoupleInteraction`
```dart
class CoupleInteraction {
  final String id;
  final String senderUid;
  final String senderName;
  final String emoji;
  final String text;
  final String? customNote;
  final String? replyEmoji;
  final String? replyText;
  final DateTime? repliedAt;
  final DateTime createdAt;
  final bool isRead;
}
```

### B. Model `CustomCoupleSticker`
```dart
class CustomCoupleSticker {
  final String id;
  final String emoji;
  final String text;
  final bool isReply; // true jika balasan, false jika stiker kirim perhatian
}
```

### C. Firestore Path & Security Rules
- Subkoleksi: `/profiles/{profileId}/interactions/{interactionId}`
- List stiker kustom disimpan di dokumen profil:
  - `/profiles/{profileId}` field `customStickers` (List of Map).
- Rules: Mengizinkan anggota profil (`profile.memberUids.hasAny([request.auth.uid])`) untuk `read`, `create`, dan `update` interaksi.

---

## 6. Roadmap Masa Depan: Karakter Maskot Imut Pemilik Siklus
Untuk memperkaya tampilan pemilik siklus (cewek) di fase berikutnya, disiapkan arsitektur maskot imut dengan 4 pilihan karakter:
1. 🐱 **Mochi Kitten** (Kucing Lucu)
2. 🐰 **Fluffy Bunny** (Kelinci Lucu)
3. 🦕 **Baby Dino** (Dino Lucu)
4. 👧 **Chibi Girl** (Karakter Wanita Lucu)

Setiap karakter akan memiliki ekspresi dinamis yang berganti secara otomatis sesuai fase siklus dan log mood harian cewek:
- **Fase Haid:** Berselimut & kompres hangat (*comfy/sleepy/pouty*).
- **Fase Folikuler:** Melompat riang membawa bunga (*sparkling/energetic*).
- **Fase Ovulasi:** Penuh cinta & berbinar (*radiant love/glowing*).
- **Fase Luteal:** Sedang makan camilan cokelat dengan pipi gembul (*hungry/manja*).

---

## 7. Rencana Pengujian
1. **Unit Test:**
   - Serialisasi `CoupleInteraction` dan `CustomCoupleSticker`.
   - Metode `sendInteraction`, `replyInteraction`, dan `addCustomSticker` di `ProfileRepository`.
2. **Widget Test:**
   - `HomeScreen` membedakan tombol "Catat Hari Ini" untuk cewek vs "Kirim Perhatian" untuk cowok.
   - `HomeShell` menampilkan 4 tab (termasuk tab Ruang Pasangan dengan badge).
   - `CoupleSpaceScreen` merender timeline interaksi, stiker preset, dialog kustom stiker, dan balasan 1-klik.
