# 📋 Kasir-AI — Features & Roadmap Tracker

> **Catatan untuk Agen AI:** Baca file ini sebelum memulai pengerjaan. Perbarui status fitur setiap ada penyelesaian, perubahan, atau pembatalan. Jangan kerjakan fitur yang belum ada di dokumen ini tanpa persetujuan user.

---

## 📖 Legenda Status
| Simbol | Arti |
|--------|------|
| ✅ | Selesai & berjalan |
| ⚠️ | Sebagian / Ada kekurangan |
| 🔨 | Sedang dikerjakan (WIP) |
| 📋 | Direncanakan, belum dikerjakan |
| 💡 | Ide masa depan / Backlog |
| ❌ | Dibatalkan / Dihapus |

---

## 📝 Changelog & Riwayat (History)
- **[24 Jun 2026]** Modul 15 (Analitik Lanjutan) — Backend selesai: 5 endpoint baru, cron job Market Basket (Lift/Confidence/Support), tabel `market_basket_cache`, migration Drizzle dihasilkan.
- **[24 Jun 2026]** Reorganisasi file fitur; semua nomor urut diperbaiki, fitur yang ditunda dipindahkan ke Backlog.
- **[24 Jun 2026]** Modul 14 (Visualisasi Data & Dashboard) selesai diimplementasikan dengan `fl_chart`.
- **[24 Jun 2026]** Inisialisasi `AGENTS.md` dengan aturan C.8 (Dilarang hardcode angka).
- **[23 Jun 2026]** Refaktor modul Laporan: `admin_dashboard_screen.dart` dipecah menjadi 7 layar mandiri.
- **[23 Jun 2026]** Migrasi error handling API: semua route menggunakan `asyncHandler` + `AppError`.

---

## 🚀 MODUL 1: Autentikasi & Sesi

**Deskripsi:** Sistem login, manajemen sesi pengguna, dan kontrol akses berdasarkan peran (role-based).

| # | Fitur | Status | Keterangan |
|---|-------|--------|------------|
| 1.1 | Login dengan Email & Password | ✅ | Menggunakan `better-auth` sebagai auth engine. |
| 1.2 | Manajemen Sesi (Token / Cookie) | ✅ | Sesi disimpan di cookie httpOnly, di-refresh otomatis. |
| 1.3 | Kontrol Akses Berbasis Peran (RBAC) | ✅ | Peran: `owner`, `admin`, `kasir`, `dapur`. |
| 1.4 | Logout & Invalidasi Sesi | ✅ | Endpoint `/auth/sign-out` menghapus sesi dari DB. |
| 1.5 | Halaman Login (Flutter & Admin Web) | ✅ | `login_screen.dart` + `Login.jsx`. |

---

## 🚀 MODUL 2: Manajemen Produk & Kategori

**Deskripsi:** CRUD untuk produk yang dijual (menu), varian produk, dan kategori menu.

| # | Fitur | Status | Keterangan |
|---|-------|--------|------------|
| 2.1 | Daftar & Pencarian Produk | ✅ | Filter berdasarkan kategori dan kata kunci. |
| 2.2 | Tambah / Edit / Hapus Produk | ✅ | Termasuk upload foto produk. |
| 2.3 | Manajemen Varian Produk | ✅ | Misal: Kopi Latte → ukuran S/M/L dengan harga berbeda. |
| 2.4 | Manajemen Kategori | ✅ | CRUD kategori menu (Minuman, Makanan, Snack, dll). |
| 2.5 | Resep Produk (Bahan Baku) | ✅ | Mendefinisikan bahan baku yang dipakai per produk untuk deduction otomatis. `product_recipe_screen.dart` |
| 2.6 | Produk Aktif / Nonaktif | ✅ | Toggle produk agar tidak tampil di kasir tanpa dihapus. |

---

## 🚀 MODUL 3: Kasir & Transaksi

**Deskripsi:** Antarmuka utama kasir untuk memproses pesanan pelanggan secara real-time.

| # | Fitur | Status | Keterangan |
|---|-------|--------|------------|
| 3.1 | Pembuatan Pesanan (Dine-in & Takeaway) | ✅ | Mencatat tipe pesanan + nomor meja. |
| 3.2 | Manajemen Keranjang (Cart) | ✅ | Tambah, ubah kuantitas, dan hapus item. |
| 3.3 | Pencarian Produk di Kasir | ✅ | Filter cepat produk berdasarkan nama/kategori. |
| 3.4 | Perhitungan Pajak (PB1) & Diskon | ✅ | Persentase pajak & diskon dikonfigurasi di Pengaturan. |
| 3.5 | Multi-Metode Pembayaran | ✅ | Cash, Transfer, QRIS, Kartu Kredit, dll. dapat dikombinasikan. |
| 3.6 | Cetak Struk / Bukti Pembayaran | ✅ | `receipt_screen.dart` — mendukung cetak via browser print. |
| 3.7 | Simpan Pesanan (Hold Order) | ✅ | Menyimpan pesanan sementara sebelum dibayar. |
| 3.8 | Deduction Stok Otomatis | ✅ | Bahan baku berkurang otomatis saat order selesai berdasarkan resep. |
| 3.9 | Loyalty Points Pelanggan | ✅ | Poin diberikan otomatis saat transaksi jika pelanggan terdaftar. |

---

## 🚀 MODUL 4: Shift Kasir

**Deskripsi:** Manajemen giliran kerja kasir, termasuk modal awal dan rekonsiliasi akhir shift.

| # | Fitur | Status | Keterangan |
|---|-------|--------|------------|
| 4.1 | Mulai Shift (Input Modal Awal) | ✅ | `mulai_shift_screen.dart` — mencatat uang di laci sebelum buka. |
| 4.2 | Tutup Shift (Rekap & Setoran) | ✅ | `tutup_shift_screen.dart` — menghitung selisih antara modal+pendapatan vs uang fisik. |
| 4.3 | Riwayat Shift | ✅ | Data shift tersimpan dan dapat dilihat di laporan. |

---

## 🚀 MODUL 5: Dapur (Kitchen Display System)

**Deskripsi:** Antarmuka untuk staf dapur melihat dan memproses pesanan yang masuk.

| # | Fitur | Status | Keterangan |
|---|-------|--------|------------|
| 5.1 | Tampilan Antrian Pesanan Dapur | ✅ | `kitchen_display_screen.dart` — menampilkan pesanan aktif dengan status. |
| 5.2 | Update Status Pesanan (Preparing → Ready) | ✅ | Staf dapur menandai pesanan siap. |
| 5.3 | Filter Status Pesanan | ✅ | Tampilkan hanya pesanan dengan status tertentu. |

---

## 🚀 MODUL 6: Inventori & Bahan Baku

**Deskripsi:** Manajemen stok bahan baku yang digunakan untuk membuat produk.

| # | Fitur | Status | Keterangan |
|---|-------|--------|------------|
| 6.1 | Daftar Stok Inventori | ✅ | CRUD item inventori dengan satuan dan harga beli. |
| 6.2 | Pencarian & Filter Inventori | ✅ | Filter berdasarkan kategori bahan dan nama. |
| 6.3 | Notifikasi Stok Kritis | ✅ | Peringatan otomatis jika stok di bawah batas minimum. |
| 6.4 | Riwayat Mutasi Stok Detail | 💡 | Lihat Backlog B.4 — ditunda untuk iterasi mendatang. |

---

## 🚀 MODUL 7: Staf & Absensi

**Deskripsi:** Manajemen data karyawan dan pencatatan kehadiran.

| # | Fitur | Status | Keterangan |
|---|-------|--------|------------|
| 7.1 | Daftar, Tambah & Edit Data Staf | ✅ | `staff_management_screen.dart`, `staff_form_screen.dart`. |
| 7.2 | Detail Profil & Foto Staf | ✅ | `staff_detail_screen.dart` — termasuk upload foto profil. |
| 7.3 | Absensi (Clock-in / Clock-out) | ✅ | `attendance_screen.dart` — dicatat dengan timestamp. |
| 7.4 | Riwayat Absensi per Staf | ✅ | Tersedia di laporan staf. |

---

## 🚀 MODUL 8: Pelanggan & Loyalty

**Deskripsi:** Database pelanggan dan sistem poin loyalitas.

| # | Fitur | Status | Keterangan |
|---|-------|--------|------------|
| 8.1 | Database Pelanggan (CRUD) | ✅ | API `customers.routes.ts` — nama, kontak, poin. |
| 8.2 | Pencarian Pelanggan | ✅ | Filter berdasarkan nama/nomor di halaman kasir. |
| 8.3 | Sistem Loyalty Points | ✅ | Poin diberikan otomatis proporsional dengan nilai transaksi. |
| 8.4 | Laporan Pelanggan | ✅ | `customer_report_screen.dart` — analitik segmentasi pelanggan. |

---

## 🚀 MODUL 9: Pengeluaran (Expenses)

**Deskripsi:** Pencatatan pengeluaran operasional bisnis di luar pembelian bahan baku.

| # | Fitur | Status | Keterangan |
|---|-------|--------|------------|
| 9.1 | Catat Pengeluaran | ✅ | `Pengeluaran.jsx` (Admin Web) — kategori, jumlah, deskripsi. |
| 9.2 | Daftar & Filter Pengeluaran | ✅ | Filter berdasarkan tanggal dan kategori. |
| 9.3 | Pengeluaran dalam Laporan Keuangan | ✅ | Data pengeluaran termasuk dalam kalkulasi Laba/Rugi. |

---

## 🚀 MODUL 10: Purchasing (Pembelian Bahan Baku)

**Deskripsi:** Manajemen Purchase Order (PO) ke supplier untuk pengadaan bahan baku.

| # | Fitur | Status | Keterangan |
|---|-------|--------|------------|
| 10.1 | Laporan PO (Purchase Order) | ✅ | `purchasing_report_screen.dart` — daftar dan status PO. |
| 10.2 | Pembelian per Supplier | ✅ | Agregasi total pembelian per supplier. |
| 10.3 | Laporan Retur Pembelian | ✅ | Mencatat pengembalian barang ke supplier. |
| 10.4 | Performa Supplier | ✅ | Analitik ketepatan waktu dan kualitas supplier. |

---

## 🚀 MODUL 11: Cabang (Multi-Outlet)

**Deskripsi:** Manajemen beberapa cabang/outlet dalam satu sistem.

| # | Fitur | Status | Keterangan |
|---|-------|--------|------------|
| 11.1 | CRUD Data Cabang | ✅ | `Cabang.jsx` (Admin Web) — nama, alamat, kontak cabang. |
| 11.2 | Filter Laporan per Cabang | ✅ | Filter dropdown cabang sudah tersedia di UI dan diproses oleh Backend API. |

---

## 🚀 MODUL 12: Laporan & Analitik

**Deskripsi:** Seluruh modul laporan untuk memberikan wawasan bisnis kepada pemilik/admin.

| # | Fitur | Status | Keterangan |
|---|-------|--------|------------|
| 12.1 | Laporan Penjualan (Harian, Per Jam, Per Kasir, Per Shift) | ✅ | `sales_report_screen.dart` |
| 12.2 | Laporan Keuangan (Laba/Rugi, Arus Kas) | ✅ | `finance_report_screen.dart` |
| 12.3 | Laporan Inventori & Stok | ✅ | `inventory_report_screen.dart` |
| 12.4 | Laporan Pajak | ✅ | `tax_report_screen.dart` |
| 12.5 | Laporan Pelanggan | ✅ | `customer_report_screen.dart` |
| 12.6 | Laporan Pembelian (Purchasing) | ✅ | `purchasing_report_screen.dart` |
| 12.7 | Laporan Staf & Absensi | ✅ | `staff_report_screen.dart` |
| 12.8 | Filter Rentang Tanggal & Preset Cepat | ✅ | Sudah ada di `ReportFilterDrawer` (Hari Ini, Kemarin, 7 Hari, dll). |
| 12.9 | Filter per Kasir (staffId) | ✅ | UI state dan Backend sudah tersinkronisasi. |
| 12.10 | Filter per Cabang (branchId) | ✅ | Backend mengirim list branches, UI menampilkan dropdown Cabang. |
| 12.11 | Filter per Metode Pembayaran | ✅ | Filter dropdown metode pembayaran sudah aktif dari UI ke Backend. |
| 12.12 | Pencarian Transaksi | ✅ | Pencarian menggunakan ilike berdasarkan `orderNumber`. |
| 12.13 | Kolom Sortir | ✅ | Bisa diurutkan berdasarkan Tanggal, Nilai, atau Nomor Invoice (ASC/DESC). |
| 12.14 | Paginasi / Infinite Scroll | ✅ | Backend membalas dengan info pagination, UI menangani limit & offset melalui `page`. |
| 12.15 | Filter per Kategori / Produk | 💡 | Lihat Backlog B.3 — ditunda untuk iterasi mendatang. |
| 12.16 | Export Excel & PDF | ✅ | `ExportService` sudah ada untuk beberapa layar laporan. |

---

## 🚀 MODUL 13: Pengaturan Sistem

**Deskripsi:** Konfigurasi aplikasi oleh owner/admin, termasuk pajak, bahasa, dan profil bisnis.

| # | Fitur | Status | Keterangan |
|---|-------|--------|------------|
| 13.1 | Pengaturan Pajak (PB1%) | ✅ | Dikonfigurasi di halaman Pengaturan, berlaku global. |
| 13.2 | Pengaturan Bahasa (ID/EN) | ✅ | `SettingsProvider` mendukung i18n dasar. |
| 13.3 | Pengaturan Tema (Dark Mode) | ✅ | Toggle dark/light mode tersimpan di SharedPreferences. |
| 13.4 | Backup & Restore Database | 💡 | Lihat Backlog B.2 — ditunda untuk iterasi mendatang. |
| 13.5 | Profil Bisnis (Nama Toko, Logo) | ✅ | Dikonfigurasi di Pengaturan, dipakai di struk cetak. |
| 13.6 | Target Penjualan Bulanan | ✅ | Dapat dikonfigurasi di Pengaturan > Umum, digunakan oleh Dashboard dan Backend API `/reports/sales-target`. |

---

## 📊 MODUL 14: Visualisasi Data & Eksekutif Dashboard

**Deskripsi:** Grafik dan visualisasi data tingkat lanjut untuk memberikan *insight* bisnis instan di halaman Dashboard utama.

| # | Fitur | Status | Keterangan |
|---|-------|--------|------------|
| 14.1 | KPI Cards (Kartu Ringkasan) | ✅ | Total Pendapatan, Transaksi, Rata-rata, dan Estimasi Laba. `GET /reports/kpi-summary` |
| 14.2 | Line Chart (Tren Penjualan) | ✅ | Tren 14 hari menggunakan `fl_chart`. `GET /reports/revenue-chart` |
| 14.3 | Bar Chart (Perbandingan) | ✅ | Membandingkan performa metode pembayaran. `GET /reports/distribution` |
| 14.4 | Pie / Donut Chart (Distribusi) | ✅ | Proporsi kontribusi kategori produk. `GET /reports/distribution` |
| 14.5 | Heatmap (Jam & Hari Sibuk) | ✅ | Peta intensitas matriks 7 hari x 24 jam. `GET /reports/heatmap` |
| 14.6 | Sparkline di Tabel | 💡 | Lihat Backlog B.1 — ditunda untuk iterasi mendatang. |
| 14.7 | Progress Bar Target Penjualan | ✅ | Dinamis, mengacu target dari SettingsProvider. `GET /reports/sales-target` |

---

## 📈 MODUL 15: Analitik Lanjutan

**Deskripsi:** Alat bantu pengambilan keputusan berbasis data historis: komparasi periode, prediksi penjualan, analisis keranjang belanja, pertumbuhan produk, dan musiman.

| # | Fitur | Status | Keterangan |
|---|-------|--------|------------|
| 15.1 | Perbandingan Periode (Period Comparison) | ✅ | Membandingkan revenue, transaksi, avg. transaksi, dan laba antara dua periode. `GET /reports/period-comparison` |
| 15.2 | Proyeksi / Forecast Penjualan | ✅ | WMA + koefisien musiman hari-dalam-minggu. Flag `isEstimate:true` untuk transparansi. `GET /reports/sales-forecast` |
| 15.3 | Analisis Basket (Market Basket Analysis) | ✅ | Precomputed via cron job. Lift, Support, Confidence. Filter lift > 1. `GET /reports/market-basket` |
| 15.4 | Produk dengan Pertumbuhan Tertinggi | ✅ | Bandingkan qty penjualan 2 periode. Output `trending_up` & `trending_down`. `GET /reports/product-growth` |
| 15.5 | Analisis Musiman (Seasonality) | ✅ | Rata-rata revenue per hari-dalam-minggu atau per bulan. `GET /reports/seasonality` |
| 15.6 | Analisis Churn Produk (Visualisasi) | 📋 | Data tersedia via `trending_down` di endpoint 15.4. Menunggu implementasi UI. |

---

## 💡 IDE & BACKLOG (Rencana Masa Depan)

Bagian ini berisi daftar ide dan fitur yang belum bisa diaplikasikan atau ditunda pengerjaannya pada rilis saat ini. Fitur-fitur di bawah ini dapat dijadikan referensi perancangan untuk iterasi di masa mendatang.

| # | Fitur | Modul Asal | Keterangan |
|---|-------|------------|------------|
| B.1 | Sparkline di Tabel | Modul 14 (14.6) | Grafik tren mini di dalam baris tabel (misal: tren performa per kasir/produk). Ditunda karena Dashboard saat ini difokuskan pada High-Level Chart. |
| B.2 | Backup & Restore Database | Modul 13 (13.4) | Ekstrak data MySQL ke `.sql` dan pulihkan melalui web admin. Memerlukan fungsionalitas penulisan file system di Backend. |
| B.3 | Filter Laporan per Kategori/Produk | Modul 12 (12.15) | Filter histori transaksi berdasarkan kategori/produk tertentu. Membutuhkan query SQL JOIN Transaksi → Item → Produk → Kategori. |
| B.4 | Riwayat Mutasi Stok Detail (Audit Trail) | Modul 6 (6.4) | Mencatat histori pergerakan setiap gram/item inventori secara mendalam untuk keperluan rekonsiliasi gudang. |
| B.5 | Analisis Churn Produk (Visualisasi) | Modul 15 (15.4) | UI visualisasi produk dengan tren menurun secara berkelanjutan, sebagai dasar keputusan discontinue. Backend sudah menyediakan data ini melalui `trending_down` dari endpoint `product-growth`. |
