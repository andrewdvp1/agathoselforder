# GlassPOS QR — Aplikasi Pemesanan & Kasir Berbasis QR Code

Aplikasi pemesanan mandiri (*self-order*) dan kasir POS berbasis QR Code untuk **Android** dan **Web**. Seluruh layanan backend dan pembayaran sudah aktif sehingga aplikasi dapat langsung dijalankan di perangkat Anda.

---

## Prasyarat

Pastikan di komputer Anda sudah terpasang:
1. **Flutter SDK** (`flutter --version`)
2. **Perangkat tujuan:**
   * **Browser Chrome** (untuk menjalankan versi Web), atau
   * **Smartphone Android** (dengan *USB Debugging* aktif) / **Android Emulator**
3. Koneksi internet aktif

---

## Cara Menjalankan Aplikasi

### 1. Pasang Dependensi
Buka terminal di folder proyek ini lalu jalankan:
```bash
flutter pub get
```

### 2. Jalankan Aplikasi

* **Di Smartphone Android / Emulator:**
  1. Hubungkan HP Android via kabel USB (aktifkan **Developer Options → USB Debugging**) atau buka Android Emulator.
  2. Cek apakah perangkat terdeteksi:
     ```bash
     flutter devices
     ```
  3. Jalankan aplikasi:
     ```bash
     flutter run
     ```
  4. Saat membuka fitur **Scan QR** sebagai Kasir, pilih **Izinkan (Allow)** untuk akses kamera.

* **Di Browser Web (Chrome):**
  ```bash
  flutter run -d chrome --web-port 8080
  ```
  > Jika perangkat tidak memiliki kamera, gunakan tombol **Input Kode Manual** di layar Scanner Kasir.

* **Build APK Android (Untuk Instal Langsung di HP):**
  ```bash
  flutter build apk --release
  ```
  Hasil APK berada di `build/app/outputs/flutter-apk/app-release.apk`.

---

## Akun Uji Coba

Semua akun berikut sudah siap digunakan dengan password **`Password123!`**:

| Peran | Email | Password |
| :--- | :--- | :--- |
| **User (Pengunjung)** | `user1@app.test` / `user2@app.test` | `Password123!` |
| **Kasir** | `kasir1@app.test` / `kasir2@app.test` | `Password123!` |
| **Admin** | `admin@app.test` | `Password123!` |

### Registrasi Akun Baru
* **User:** Langsung daftar dari tab **Daftar Akun**.
* **Kasir:** Gunakan kode registrasi **`KASIR-DEV-2026`**.
* **Admin:** Gunakan kode registrasi **`ADMIN-DEV-2026`**.

---

## Alur Singkat Penggunaan

1. **User:** Pilih menu → klik **Checkout** → pilih metode bayar (**QRIS** disarankan) → tampil **QR Code Pesanan**.
2. **Kasir:** Buka tab **Scan QR** → pindai QR pesanan User (atau gunakan **Input Kode Manual**) → klik **Setujui Pesanan & Pembayaran**.
3. **Pembayaran:** Klik **Simulasi Bayar** untuk menyelesaikan transaksi uji coba secara real-time hingga muncul status **Pembayaran Berhasil**.
4. **Admin:** Kelola menu pada tab **Manajemen Menu**, pantau histori seluruh kasir, dan unduh laporan harian (`.xlsx`, `.csv`, `.pdf`) pada tab **Laporan & Histori**.

---

## Troubleshooting Ringkas

* **HP Android tidak terbaca di `flutter devices`:** Pastikan kabel USB mendukung data, aktifkan *USB Debugging*, dan setujui pop-up izin debugging di layar HP.
* **Cek lingkungan Flutter:** Jalankan `flutter doctor` untuk memastikan Android SDK atau Chrome sudah terdeteksi.
