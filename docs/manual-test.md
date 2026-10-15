# Uji manual Siklus MVP — 2026-10-15

File APK Release telah selesai dibangun di:
`build/app/outputs/flutter-apk/app-release.apk` (51.1 MB)

Panduan pengujian end-to-end pada 2 HP (HP A & HP B):

| # | Skenario | Langkah | Hasil yang diharapkan | Status |
|---|---|---|---|---|
| 1 | Daftar & buat profil | HP A: Daftar akun baru → Buat profil "Sari" | Masuk ke Kalender, teks "Catat haid pertama untuk melihat prediksi." | Siap Diuji |
| 2 | Catat haid | HP A: Klik "Catat hari ini" → Aliran "Sedang" → Simpan | Tanggal berwarna merah di kalender, ringkasan menampilkan perkiraan haid berikutnya | Siap Diuji |
| 3 | Undang pasangan | HP A: Tab Pengaturan → "Undang pasangan" | Muncul dialog dengan kode 6 karakter (berlaku 24 jam) dan tombol "Salin" | Siap Diuji |
| 4 | Gabung profil | HP B: Daftar akun baru → di layar Mulai masukkan kode undangan → Klik "Gabung" | HP B langsung melihat kalender siklus yang sama; HP A menampilkan "2 anggota" | Siap Diuji |
| 5 | Edit bersama | HP B: Buka tanggal yang sama → tambah gejala "Kram" → Simpan | Dalam beberapa detik HP A melihat pembaruan data secara real-time | Siap Diuji |
| 6 | Operasi offline | HP A aktifkan mode pesawat → catat hari berikutnya "Ringan" → Simpan → online kembali | Catatan tersimpan di cache lokal saat offline dan otomatis terunggah ke cloud saat online | Siap Diuji |
| 7 | Konflik last-write-wins | Kedua HP offline, mengedit tanggal yang sama dengan catatan berbeda → online | Versi terakhir yang tersinkron diterapkan secara konsisten tanpa kehilangan data | Siap Diuji |
| 8 | Ganti device / Reinstall | Hapus aplikasi di HP A → pasang ulang → Masuk dengan email & password lama | Seluruh riwayat siklus, gejala, dan profil langsung termuat kembali dari Firestore | Siap Diuji |
| 9 | Kode kedaluwarsa | Masukkan kode yang telah melewati 24 jam atau acak | Muncul pesan ramah "Kode undangan tidak ditemukan" atau "Kode undangan sudah kedaluwarsa." | Siap Diuji |
