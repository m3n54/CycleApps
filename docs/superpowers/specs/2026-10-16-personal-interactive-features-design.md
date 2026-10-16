# CycleApp Phase 2: Personal & Interactive Features Design Spec

**Date:** 2026-10-16  
**Project:** CycleApp (`siklus`)  
**Approach:** Pendekatan A (Clean Domain + Lightweight Real-Time Sync di Firestore)

---

## 1. Tujuan & Visi Produk

Mengubah **CycleApp** dari sekadar aplikasi pencatat kalender siklus biasa menjadi **teman harian yang hangat, empatik, dan interaktif** bagi pemilik siklus (*Owner*) maupun pasangannya (*Partner*), tanpa menambah beban input manual yang rumit.

---

## 2. Tiga Pilar Fitur Utama

### Pilar 1: Couple Care 2 Arah ("Kode ke Pasangan" & Tampilan Khusus Pasangan)

1. **Deteksi Peran Otomatis (`isOwner` vs `isPartner`):**
   - Berdasarkan `CycleProfile.ownerUid` dan `user.uid` yang sedang aktif:
     - **Pemilik Siklus (`user.uid == profile.ownerUid`):** Melihat kontrol pengiriman *Kode Cepat / Craving* ke pasangan.
     - **Pasangan (`user.uid != profile.ownerUid`):** Melihat kartu **Panduan Pasangan Hari Ini** (saran sikap praktis sesuai fase siklus pasangan) serta kartu notifikasi sinyal aktif dari pasangan lengkap dengan tombol **Reaksi Balasan 1-Klik**.

2. **Pilihan Sinyal Cepat (*Owner* -> *Partner*):**
   - `cravingSweet`: *"Pengen yang manis 🍫"*
   - `needHug`: *"Butuh pelukan hangat 🫂"*
   - `Resting`: *"Lagi kram, butuh istirahat 🛌"*
   - `sensitiveMood`: *"Mood lagi sensitif 🥺"*
   - `qualityTime`: *"Pengen ditemenin ngobrol 💬"*

3. **Pilihan Reaksi Balasan 1-Klik (*Partner* -> *Owner*):**
   - `hugSent`: *"Peluk hangat dikirim! ❤️"*
   - `onTheWay`: *"Siap, meluncur bawain! 🛵🍫"*
   - `takeRest`: *"Istirahat yang nyaman ya sayang 🤍"*
   - `hereForYou`: *"Aku siap nemenin kamu kapan aja ✨"*

4. **Penyimpanan Firestore (`profiles/{profileId}`):**
   - Menyimpan field ringan pada dokumen profil:
     - `activeSignal`: `String?` (nama enum `CoupleSignal`)
     - `signalUpdatedAt`: `Timestamp?` (atau ISO string/timestamp)
     - `signalReaction`: `String?` (nama enum `PartnerReaction`)
   - Sinyal otomatis dianggap kedaluwarsa setelah 24 jam atau dapat dihapus oleh *Owner*.

---

### Pilar 2: Sapaan Kontekstual & Penjelas Tubuh ("Kenapa Aku Merasa Begini?")

1. **Sapaan Kontekstual (*Contextual Greeting*):**
   - Mengingat catatan hari kemarin (`today - 1 hari`) dan hari ini dari `dayEntriesProvider`:
     - Jika kemarin mencatat gejala (mis. kram/sakit kepala): *"Halo, [Nama] 🌸 Kemarin kamu sempat merasa [gejala]. Semoga hari ini tubuhmu terasa lebih nyaman ya!"*
     - Jika kemarin mencatat mood sensitif/sedih/cemas: *"Halo, [Nama] 🤍 Kemarin hari yang cukup berat ya. Tarik napas dalam, hari ini kita jalani pelan-pelan."*
     - Jika hari ini sudah mencatat mood bahagia/tenang: *"Halo, [Nama] ✨ Senang melihat mood kamu cerah hari ini!"*
     - Default hangat sesuai fase siklus jika belum ada catatan kemarin.

2. **Kartu "Kenapa Aku Merasa Begini?" (*Body Explainer Card*):**
   - Muncul di `HomeScreen` ketika pengguna memilih minimal 1 gejala (`Symptom`) atau suasana hati (`Mood`) pada catatan hari ini (`todayEntry`).
   - Memberikan penjelasan ilmiah singkat yang menenangkan (mengaitkan gejala/mood tersebut dengan fase hormon saat ini: `Menstrual`, `Follicular`, `Ovulation`, atau `Luteal`) beserta **1 Tips Cepat (*Quick Relief*)**.

---

### Pilar 3: Checklist Self-Care Harian Otomatis (3 Misi Mikro)

1. **3 Misi Harian Otomatis Berdasarkan Fase Siklus (`CyclePhase`):**
   - Setiap fase siklus memiliki 3 misi mikro spesifik (contoh Fase Menstruasi: *Minum air hangat / teh jahe*, *Kompres hangat perut 15 menit*, *Tidur 30 menit lebih awal*).
2. **Interaksi & Penyimpanan (`DayEntry.selfCareCompleted`):**
   - Pengguna cukup mencentang misi langsung dari kartu di `HomeScreen` (menampilkan progress bar `0/3` hingga `3/3` selesai).
   - Disimpan sebagai `Set<String> selfCareCompleted` di `DayEntry` (`profiles/{profileId}/days/{date}`), sehingga tersinkronisasi lintas perangkat dan tetap mengikuti pola *offline-first* (`unawaited(dayRepository.saveDay(...))`).

---

## 3. Keamanan & Kompatibilitas

- `firestore.rules` telah mengizinkan field `'activeSignal'`, `'signalUpdatedAt'`, `'signalReaction'` pada `profiles/{profileId}` dan `'selfCareCompleted'` pada `profiles/{profileId}/days/{date}`.
- Semua komponen UI wajib mendukung *Light Mode* dan *Dark Mode* (`CycleColors`), serta aman pada layar sempit (`ResponsiveBounds`).
