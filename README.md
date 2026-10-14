# 🍽️ POS Kuliner - Aplikasi Kasir Point of Sale (POS) Modern

![Flutter](https://img.shields.io/badge/Flutter-3.38.6-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.10.7-0175C2?logo=dart&logoColor=white)
![Riverpod](https://img.shields.io/badge/State-Riverpod%203.x-blueviolet)
![Backend](https://img.shields.io/badge/Backend-Supabase-3ECF8E?logo=supabase&logoColor=white)
![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20Web%20%7C%20Tablet-orange)
![Tests](https://img.shields.io/badge/Tests-100%25%20Passing-brightgreen)

Aplikasi **Point of Sale (POS) Kuliner** adalah sistem kasir modern berbasis **Flutter** yang dirancang khusus untuk usaha kuliner makanan dan minuman (F&B) di Indonesia—mulai dari warung makan, kafe, restoran, depot, hingga kedai cepat saji.

Aplikasi mengusung prinsip **Offline-First**, sehingga transaksi kasir tetap dapat berlangsung lancar tanpa internet, dan akan otomatis tersinkronisasi ke cloud **Supabase** begitu koneksi internet kembali pulih.

---

## 📑 Daftar Isi

- [Fitur Utama](#-fitur-utama)
- [Teknologi & Dependensi](#-teknologi--dependensi)
- [Arsitektur Proyek](#-arsitektur-proyek)
- [Panduan Memulai (Getting Started)](#-panduan-memulai-getting-started)
- [Integrasi Backend Supabase](#-integrasi-backend-supabase)
- [Pengujian & Analisis Kode](#-pengujian--analisis-kode)
- [Catatan Teknis Lingkungan Windows](#-catatan-teknis-lingkungan-windows)
- [Penulis & Hak Cipta](#-penulis--hak-cipta)

---

## 🌟 Fitur Utama

### 1. 🛒 Layar Kasir POS & Transaksi Fleksibel (FR-POS & FR-PAY)
- **Katalog Cepat & Responsif**: Pencarian instan (<100ms) berdasarkan nama menu atau bahan, serta filter chip kategori (*Makanan Utama, Minuman Segar, Camilan, Paket Hemat*).
- **Opsi Varian & Modifiers**: Pemilihan varian porsi (Reguler/Jumbo) dengan selisih harga dan pilihan topping tambahan (keju, telur, sosis) serta catatan khusus per menu (*"tanpa bawang", "sedikit gula"*).
- **Tipe Pesanan**: Mendukung **Dine-In** (dengan nomor meja), **Takeaway** (nama pemesan), dan **Delivery** (alamat tujuan).
- **Diskon Transaksi**: Diskon persentase (%) atau nominal (Rp) dengan kewajiban input alasan untuk audit keamanan.
- **Hold / Park Orders**: Tahan transaksi sementara saat pelanggan ingin menambah menu, lalu buka kembali dari laci pesanan tertahan (*Held Orders*).
- **Kalkulasi Pajak & Layanan**: Otomatis menghitung subtotal, diskon, PPN 11%, dan Service Charge 5%.
- **Multi-Metode Pembayaran**:
  - **Tunai (Cash)**: Hitung otomatis kembalian dengan tombol preset uang pas, 50rb, 100rb, dan 200rb.
  - **QRIS**: Tampilan kode QR statis toko langsung di layar kasir dengan konfirmasi kasir.
  - **Debit / EDC**: Pencatatan nama bank (BCA, Mandiri, BRI, BNI) dan nomor referensi struk mesin EDC.
  - **Split Bill**: Pembayaran terbagi (sebagian tunai dan sisanya non-tunai).
- **Pembatalan Transaksi**: Fitur void/cancel pesanan yang sudah selesai disertai alasan wajib untuk rekam jejak audit (*audit trail*).

### 2. 🍽️ Kelola Menu & Produk Baru (FR-MENU)
- **Tambah Produk Baru**: Form modal interaktif untuk menambahkan menu baru lengkap dengan nama, kategori, harga dasar, deskripsi, varian ukuran, dan topping.
- **Halaman Manajemen Menu Khusus**: Tab khusus untuk mengelola seluruh katalog menu toko.
- **Hapus Menu**: Fitur hapus menu aman dengan dialog konfirmasi yang dapat diakses langsung dari:
  1. Halaman Kelola Menu.
  2. Layar Kasir POS (via tombol titik tiga `⋮` atau tekan lama pada kartu menu).
  3. Modal Edit Menu.
- **Sakelar Ketersediaan (Tersedia / Stok Habis)**: Menonaktifkan menu yang habis tanpa menghapusnya dari database.
- **Desain Responsif Mode Ponsel**: Tampilan kartu menu bertingkat yang rapi dan bebas *overflow* pada semua ukuran layar HP.

### 3. 💼 Manajemen Shift & Rekonsiliasi Kas (FR-SHIFT)
- **Buka Shift**: Catat modal kas awal di laci kasir saat kasir memulai operasional.
- **Arus Kas Masuk & Keluar**: Catat pengeluaran tunai toko (beli es batu, gas, bumbu darurat) atau penambahan uang kembalian.
- **Estimasi Kas di Laci (*Expected Cash*)**: Dihitung otomatis secara *real-time*:
  $$\text{Expected Cash} = \text{Kas Awal} + \text{Penjualan Tunai} + \text{Kas Masuk} - \text{Kas Keluar}$$
- **Tutup Shift & Selisih Kas**: Input hitungan fisik uang laci untuk verifikasi otomatis selisih kas (*Pas*, *Lebih*, atau *Kurang*).
- **Proteksi Tutup Shift**: Mencegah penutupan shift jika masih terdapat pesanan yang sedang tertahan (*Hold*).

### 4. 🧾 Cetak Struk Thermal & Tiket Dapur (FR-PRINT)
- **Format ESC/POS**: Generator struk thermal monospace untuk printer Bluetooth 58 mm (32 kolom) dan 80 mm (42 kolom).
- **Tiket Dapur (Kitchen Ticket)**: Cetak ringkasan pesanan khusus divisi dapur dengan format jelas tanpa nominal harga.
- **Cetak Ulang Struk**: Cetak ulang struk dari riwayat transaksi kapan saja.
- **Simulasi Struk Visual**: Dialog preview struk berformat kertas kasir fisik.

### 5. 📊 Laporan & Ringkasan Penjualan (FR-REPORT)
- Ringkasan harian: **Total Omzet**, **Total Transaksi**, dan **Average Order Value (AOV)**.
- **Top 5 Menu Terlaris**: Pemeringkatan menu paling laku berdasarkan kuantitas pesanan.
- **Rekap Metode Pembayaran**: Analisis proporsi transaksi tunai, QRIS, dan debit.

### 6. 🔐 Autentikasi Staf & Ganti Kasir Cepat (FR-AUTH)
- Tombol avatar di bilah atas (*App Bar*) untuk **ganti kasir cepat via Numpad PIN 4-digit** tanpa perlu logout penuh.
- Role pengguna: **Owner**, **Manager**, **Cashier**, dan **Kitchen**.

### 7. ☁️ Arsitektur Offline-First & Cloud Sync (FR-SYNC)
- Transaksi tetap berjalan normal tanpa internet berkat penyimpanan lokal dan antrean *Outbox Pattern*.
- Begitu online, data transaksi, produk baru, dan pembaruan menu otomatis dikirim (*upsert*) ke server **Supabase**.
- Indikator status koneksi interaktif (*Online / Offline / Tertunda*).

---

## 🛠️ Teknologi & Dependensi

| Kategori | Teknologi | Deskripsi |
| :--- | :--- | :--- |
| **Framework** | Flutter 3.38+ / Dart 3.10+ | Multi-platform UI toolkit |
| **State Management** | `flutter_riverpod: ^3.3.2` | State management modern menggunakan `Notifier` & `NotifierProvider` |
| **Backend & Database** | `supabase_flutter: ^2.18.3` | Cloud PostgreSQL, Auth, dan Real-time API |
| **Tipografi** | `google_fonts: ^8.2.1` | Font Plus Jakarta Sans |
| **Format Mata Uang & Tanggal** | `intl: ^0.20.3` | Format Rupiah tanpa desimal (`Rp 25.000`) & Tanggal Indonesia |
| **Identitas Unik** | `uuid: ^4.6.0` | Generator UUID v4 untuk transaksi dan entitas lokal |
| **Kode QR** | `qr_flutter: ^4.1.0` | Generator QR code dinamis untuk pembayaran QRIS |

---

## 📂 Arsitektur Proyek

Sistem dibangun menggunakan pendekatan **Feature-First Architecture** agar kode rapi, mudah dirawat, dan terisolasi per fitur:

```
lib/
├── core/
│   ├── services/
│   │   └── supabase_service.dart     # Inisialisasi & instance Supabase Client
│   ├── theme/
│   │   ├── app_colors.dart           # Palet warna kuliner hangat, dark/light mode
│   │   └── app_theme.dart            # ThemeData & konfigurasi Google Fonts
│   └── utils/
│       ├── currency_formatter.dart   # Formatter Rupiah (Rp 25.000, Rp 25rb)
│       └── date_formatter.dart       # Formatter waktu Indonesia (dd/MM/yyyy HH:mm)
├── features/
│   ├── auth/                         # Manajemen staf, role & PIN numpad
│   ├── menu/                         # Model produk, varian, modifier, AddProductDialog & MenuManagementScreen
│   ├── navigation/                   # MainLayout, NavigationRail (desktop) & NavigationBar (mobile)
│   ├── pos/                          # Layar Kasir, CartPanel, ModifierSelector, PaymentModal, HeldOrders
│   ├── printing/                     # Formatter ESC/POS struk kasir & tiket dapur
│   ├── reports/                      # Dashboard omzet, AOV, Top 5 menu & riwayat transaksi
│   ├── settings/                     # Pengaturan toko, PPN, service charge, ukuran struk
│   ├── shift/                        # Buka shift, arus kas masuk/keluar, tutup shift & selisih
│   └── sync/                         # Outbox pattern queue & sinkronisasi Supabase
└── main.dart                         # Entry point aplikasi dengan ProviderScope
```

---

## 🚀 Panduan Memulai (Getting Started)

### 1. Prasyarat
- [Flutter SDK](https://docs.flutter.dev/get-started/install) versi 3.24 atau yang lebih baru.
- Web Browser (Google Chrome) atau Emulator Android (API 26+).
- Editor kode seperti [Visual Studio Code](https://code.visualstudio.com/) dengan ekstensi Flutter.

### 2. Instalasi Dependensi
Clone atau buka direktori proyek, lalu unduh seluruh dependensi:
```bash
flutter pub get
```

### 3. Menjalankan Aplikasi

#### 🌐 Menjalankan di Web Browser (Port 3000)
Aplikasi telah dikonfigurasi untuk berjalan di `http://localhost:3000`:
```bash
flutter run -d chrome --web-port 3000
```
*Atau di VS Code: cukup tekan tombol **F5** (konfigurasi sudah tersedia di `.vscode/launch.json`).*

#### 📱 Menjalankan di Android
Sambungkan ponsel Android atau jalankan emulator Android, lalu jalankan:
```bash
flutter run
```

---

## ☁️ Integrasi Backend Supabase

Aplikasi terhubung ke backend **Supabase**:
- **Project URL**: `https://dkweuntrmwlgykbgojsi.supabase.co`

### Skema Database PostgreSQL
File migrasi skema lengkap tersedia di:
[`supabase/migrations/20261014_init_pos_schema.sql`](file:///c:/Users/Djafar/Documents/Project/Web%20Project/Kuliner/supabase/migrations/20261014_init_pos_schema.sql)

Skema mencakup tabel:
1. `stores` & `outlets` - Manajemen toko & cabang gerai.
2. `users` - Staf kasir, PIN hash, dan role hak akses.
3. `categories` & `products` - Menu, varian porsi, grup modifier, dan opsi topping.
4. `shifts` & `cash_movements` - Rekonsiliasi modal kas awal, kas masuk, kas keluar, dan penutupan shift.
5. `orders` & `order_items` - Transaksi selesai dengan snapshot permanen harga dan nama menu.
6. `outbox_entries` - Antrean sinkronisasi *Offline-First*.
7. `audit_logs` - Catatan pembatalan pesanan dan pergantian data penting.
8. Kebijakan keamanan **Row Level Security (RLS)** aktif.

---

## 🧪 Pengujian & Analisis Kode

Aplikasi telah diuji secara menyeluruh dengan hasil **100% lulus tanpa kendala**:

### Menjalankan Static Code Analysis:
```bash
flutter analyze
```
> **Hasil:** `No issues found!` (0 error, 0 warning, 0 lint issue).

### Menjalankan Unit & Widget Test:
```bash
flutter test
```
> **Hasil:** `All tests passed! (7 of 7 passed)`
> - Unit kalkulasi harga pesanan dengan varian & modifiers
> - Snapshot harga produk permanen pada pesanan
> - Perhitungan rekonsiliasi kas shift (Expected vs Actual Cash)
> - Formatter mata uang Rupiah
> - Operasi CRUD produk menu (tambah, perbarui, ubah status, hapus)
> - Sinkronisasi filter menu setelah penghapusan
> - Smoke test antarmuka dan navigasi aplikasi

---

## 💻 Catatan Teknis Lingkungan Windows

Pada beberapa lingkungan Windows di mana Flutter SDK berada di dalam direktori dengan spasi (misalnya `Documents/Semester 5/...`), pustaka transitif hook `objective_c: 9.5.0` dapat mengalami kendala quoting path. Proyek ini telah mengatasinya secara elegan melalui `pubspec.yaml`:
```yaml
dependency_overrides:
  path_provider_foundation: 2.4.0
```
Konfigurasi ini memastikan seluruh proses kompilasi, pengujian unit, serta eksekusi Web & Android berjalan mulus 100%.

---

## 👤 Penulis & Lisensi

- **Penulis**: Djaff
- **Versi**: 1.0.0
- **Tahun**: 2026
- **Status**: Siap Digunakan / Production-Ready MVP
