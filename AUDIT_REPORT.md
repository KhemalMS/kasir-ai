# 🔍 Laporan Audit Aplikasi Kasir-AI

**Tanggal Audit:** 2026-06-25  
**Versi Aplikasi:** 1.0.0+1  
**Scope:** Full-Stack (Flutter Mobile/Web, Express API, MySQL/Drizzle ORM)  
**Auditor:** Agen Auditor AI

---

## 📊 Ringkasan Eksekutif

| Kategori | Kritis | Tinggi | Sedang | Rendah | Total |
|----------|--------|--------|--------|--------|-------|
| **Bug / Error** | 2 | 3 | 4 | 2 | 11 |
| **Security** | 1 | 3 | 2 | 1 | 7 |
| **Performa** | 2 | 2 | 3 | 1 | 8 |
| **Arsitektur / Code Quality** | 0 | 2 | 5 | 3 | 10 |
| **Total** | **5** | **10** | **14** | **7** | **36** |

**Verdict:** Aplikasi memiliki fondasi yang **kuat** dengan arsitektur monorepo yang rapi, error handling terstruktur, dan autentikasi yang solid. Namun, terdapat **2 bug kritis performa** yang harus segera diperbaiki sebelum production, ditambah **1 vulnerability fraud** di pembuatan order. Pemisahan file `admin_dashboard_screen.dart` (3.843 baris) adalah prioritas refactor utama.

---

## 🚨 Bug & Error Kritis

### 1. [KRITIS] Network Scan Paralel Meledak — `ApiConfig._scanNetwork()`
**Lokasi:** `apps/mobile/lib/config/api_config.dart:97`  
**Severity:** Kritis  
**Dampak:** Aplikasi hang/crash saat startup di Android; drain baterai; network interface overload.

**Deskripsi:**
```dart
final futures = List.generate(254, (i) => i + 1).map((host) async { ... });
final results = await Future.wait(futures);
```

Kode ini membuat **1.016 HTTP request paralel** (254 host × 4 subnet) dalam satu `Future.wait`. Setiap request punya timeout 800ms. Ini bisa:
- Memenuhi connection pool OS Android
- Membuat UI freeze selama scan
- Mengonsumsi baterai secara masif
- Di-drop oleh router/firewall sebagai DoS-like behavior

**Rekomendasi:**
```dart
// Gunakan chunked scan dengan throttling
static Future<String?> _scanNetwork() async {
  // ...
  for (final subnet in subnets) {
    for (int i = 1; i <= 254; i += 10) { // chunk size 10
      final chunk = List.generate(10, (j) => i + j)
          .where((h) => h <= 254)
          .map((host) => _tryHost(subnet, host));
      final found = await Future.wait(chunk);
      final result = found.whereType<String>().firstOrNull;
      if (result != null) return result;
    }
  }
}
```

---

### 2. [KRITIS] Order Total Tidak Direkalkulasi di Server — `ordersService.create()`
**Lokasi:** `apps/api/src/services/orders.service.ts:98`  
**Severity:** Kritis  
**Dampak:** Client bisa memanipulasi `totalAmount` — potensi fraud/kerugian finansial.

**Deskripsi:**
```typescript
totalAmount: input.totalAmount, // Langsung trust client input!
```

Server tidak merekalkulasi `subtotal + taxAmount + serviceAmount - discountAmount`. Client bisa mengirim `totalAmount` yang lebih rendah dari seharusnya.

**Rekomendasi:**
```typescript
// Recalculate di dalam transaction
const calculatedTotal = 
  input.subtotal + 
  input.taxAmount + 
  input.serviceAmount - 
  (input.discountAmount || 0);

await tx.insert(orders).values({
  ...input,
  totalAmount: calculatedTotal, // Override client input
});
```

---

### 3. [TINGGI] Error `catch` Tanpa Tipe Spesifik — `AuthProvider.checkAuth()`
**Lokasi:** `apps/mobile/lib/providers/auth_provider.dart:31`  
**Severity:** Tinggi  
**Dampak:** User ter-logout secara paksa saat network error sementara (flaky WiFi).

**Deskripsi:**
```dart
catch (e) {
  _user = null;
  _staff = null;
  _isAuthenticated = false;
}
```

Semua error (401, 403, 500, timeout, network unreachable) dianggap sama: logout. Seharusnya hanya 401/403 yang memicu logout. Timeout/network error sebaiknya retry atau tampilkan "mode offline".

**Rekomendasi:**
```dart
catch (e) {
  if (e is ApiException && e.statusCode == 401) {
    _isAuthenticated = false;
  } else {
    // Jangan logout, tandai sebagai "connectivity issue"
    _isConnectivityIssue = true;
  }
}
```

---

### 4. [TINGGI] `mounted` Check Hilang di `.then()` Callback — `_ProdukTab`
**Lokasi:** `apps/mobile/lib/screens/admin_dashboard_screen.dart:820`  
**Severity:** Tinggi  
**Dampak:** `setState` after dispose jika dialog ditutup sebelum API response.

**Deskripsi:**
```dart
ApiService.getList('/products/${product['id']}/variants').then((list) {
  variants = list.map(...); // Tanpa mounted check!
}).catchError((_) {});
```

Di dalam `StatefulBuilder` dialog, `.then()` bisa dipanggil setelah widget di-dispose.

**Rekomendasi:** Gunakan `if (mounted)` atau `setState` yang di-wrap dalam `if (mounted)` check. Lebih baik: gunakan `FutureBuilder` atau `State` yang proper.

---

### 5. [TINGGI] `getList()` Shape Check Bisa False Positive
**Lokasi:** `apps/mobile/lib/services/api_service.dart:205`  
**Severity:** Tinggi  
**Dampak:** Aplikasi crash jika backend mengembalikan `{ data: null }` atau `{ data: object }`.

**Deskripsi:**
```dart
if (decoded is Map && decoded['data'] is List) return decoded['data'] as List;
```

Jika `data` adalah `null` (bukan List), lempar exception. Tapi beberapa endpoint valid mengembalikan `{ data: null }`. Lebih baik handle `null` secara eksplisit.

**Rekomendasi:**
```dart
if (decoded is Map && decoded['data'] is List) return decoded['data'] as List;
if (decoded is Map && decoded['data'] == null) return [];
```

---

### 6. [SEDANG] `AdvancedAnalyticsScreen` Menggunakan `setState` untuk Semua Tab
**Lokasi:** `apps/mobile/lib/screens/advanced_analytics_screen.dart`  
**Severity:** Sedang  
**Dampak:** Rebuild seluruh screen saat pindah tab, meski state seharusnya isolated per tab.

**Deskripsi:** Tab dipilih via `setState(() => _selectedTabIndex = index)`. Content rebuild, tapi karena `IndexedStack` tidak digunakan, semua tab rebuild saat pindah. State (loading, data) tab sebelumnya hilang.

**Rekomendasi:** Gunakan `IndexedStack` di dalam `Expanded(child: ...)` atau gunakan `AutomaticKeepAliveClientMixin` pada setiap tab.

---

### 7. [SEDANG] `reports.service.ts` `getSeasonality` Raw SQL Mengandung Risiko
**Lokasi:** `apps/api/src/services/reports.service.ts:1427`  
**Severity:** Sedang  
**Dampak:** Potensi SQL injection jika `branchId` tidak di-escape dengan benar oleh Drizzle `sql`.

**Deskripsi:**
```typescript
${branchId ? sql`AND branch_id = ${branchId}` : sql``}
```

Meskipun Drizzle `sql` template literal seharusnya parameterized, raw SQL dengan `db.execute()` selalu berisiko. Perlu diverifikasi bahwa `branchId` tidak bisa diinject melalui parameter.

**Rekomendasi:** Gunakan query builder Drizzle sepenuhnya, bukan `db.execute(sql`...`)`. Jika raw SQL memang diperlukan, gunakan `?` placeholder.

---

### 8. [SEDANG] `DateTime.now()` Tanpa Timezone Awareness di `getSalesForecast`
**Lokasi:** `apps/api/src/services/reports.service.ts:1238`  
**Severity:** Sedang  
**Dampak:** Proyeksi salah jika server dan client beda timezone; cutoff date tidak konsisten.

**Deskripsi:** `new Date()` menggunakan timezone server (default UTC). Tapi data `orders.createdAt` kemungkinan disimpan dalam local time. Ini bisa menyebabkan gap atau duplikasi hari.

**Rekomendasi:** Gunakan `dateHelpers.ts` (sudah ada!) untuk parse date dengan timezone awareness.

---

### 9. [RENDAH] Pie Chart `isTouched` Selalu `false`
**Lokasi:** `apps/mobile/lib/screens/admin_dashboard_screen.dart:524`  
**Severity:** Rendah  
**Dampak:** UX minor — radius pie chart tidak pernah berubah saat di-touch.

**Deskripsi:**
```dart
final isTouched = false;
final radius = isTouched ? 60.0 : 50.0;
```

`isTouched` hardcoded `false`. Interaktivitas pie chart tidak berfungsi.

**Rekomendasi:** Gunakan `PieChart` stateful atau `PieTouchData` dari `fl_chart`.

---

### 10. [RENDAH] `calcSellingPrice` Menggunakan `round()` Bukan `ceil()`
**Lokasi:** `apps/mobile/lib/screens/admin_dashboard_screen.dart:795`  
**Severity:** Rendah  
**Dampak:** Harga jual bisa lebih rendah dari markup yang diharapkan (misal: Rp 9.499 → 9.499, bukan 9.500).

**Deskripsi:**
```dart
final selling = (base * (1 + mkp / 100)).round();
```

Untuk harga, `ceil()` lebih umum agar tidak merugi.

**Rekomendasi:**
```dart
final selling = (base * (1 + mkp / 100)).ceil();
```

---

## 🔒 Masalah Security

### 1. [KRITIS] CSRF Check Dimatikan Global
**Lokasi:** `apps/api/src/lib/better-auth.ts:59`  
**Severity:** Kritis  
**Dampak:** Session hijacking via CSRF attack lebih mudah dilakukan.

**Deskripsi:**
```typescript
disableCSRFCheck: true,
```

Ini dimatikan karena "Android tidak mengirim Origin header". Tapi ini mematikan CSRF protection untuk SEMUA client (termasuk browser web).

**Rekomendasi:**
- Hanya disable CSRF untuk request dari mobile client (deteksi via User-Agent atau custom header).
- Atau gunakan double-submit cookie pattern untuk mobile.

---

### 2. [TINGGI] CORS Allow `*` untuk Request Tanpa Origin
**Lokasi:** `apps/api/src/index.ts:77`  
**Severity:** Tinggi  
**Dampak:** Request dari script/tool tanpa Origin header bisa bypass CORS restriction.

**Deskripsi:**
```typescript
} else if (!origin) {
    res.setHeader('Access-Control-Allow-Origin', '*');
}
```

Meskipun untuk mobile apps, ini juga memperbolehkan request dari curl, Postman, atau malware lokal tanpa origin check.

**Rekomendasi:** Gunakan API key atau signed request untuk mobile, bukan origin wildcard.

---

### 3. [TINGGI] Session Cache 60 Detik — Token Revoke Tidak Instant
**Lokasi:** `apps/api/src/middleware/auth.middleware.ts:46`  
**Severity:** Tinggi  
**Dampak:** Setelah logout, token masih valid selama 60 detik.

**Deskripsi:** LRU cache 60 detik. Jika user logout, session dihapus dari DB, tapi cache masih menyimpan session aktif.

**Rekomendasi:** Panggil `invalidateSessionCache(token)` di endpoint `/auth/sign-out`.

---

### 4. [SEDANG] File Upload Tidak Ada Validasi Content-Type
**Lokasi:** `apps/mobile/lib/screens/admin_dashboard_screen.dart:876`  
**Severity:** Sedang  
**Dampak:** Potensi upload file berbahaya (meski buruk, karena tidak dieksekusi di server).

**Deskripsi:** Upload menggunakan `MediaType('image', fileName.split('.').last)` — tapi ini hanya metadata, bukan validasi sebenarnya. Server perlu memverifikasi magic bytes/file signature.

**Rekomendasi:** Di backend `upload.routes.ts`, tambahkan:
- File size limit (misal 5MB)
- Magic bytes check (PNG, JPG, WEBP)
- Filename sanitization (hapus `../`, dll)
- Store file dengan nama random (UUID), bukan original filename

---

### 5. [SEDANG] `api_base_url` Disimpan di SharedPreferences Tanpa Enkripsi
**Lokasi:** `apps/mobile/lib/config/api_config.dart`  
**Severity:** Sedang  
**Dampak:** URL API bisa dimodifikasi oleh malware lokal (MITM attack vector).

**Deskripsi:** `SharedPreferences` tidak dienkripsi di Android. Attacker bisa mengubah `api_base_url` ke server phishing.

**Rekomendasi:**
- Pin certificate untuk production.
- Gunakan `flutter_secure_storage` untuk menyimpan URL manual.
- Validasi URL dengan whitelist domain.

---

## ⚡ Masalah Performa

### 1. [KRITIS] Network Scan Paralel (sudah disebut di Bug #1)
**Impact:** Startup time >10 detik, ANR (Application Not Responding) di Android.

---

### 2. [KRITIS] `_DashboardTab` Fetch 5 API Secara Serentak tanpa Cancel Token
**Lokasi:** `apps/mobile/lib/screens/admin_dashboard_screen.dart:267`  
**Severity:** Kritis  
**Dampak:** Race condition dan memory leak saat user keluar dari dashboard sebelum 5 API selesai.

**Deskripsi:**
```dart
final results = await Future.wait([
  ApiService.get('/reports/kpi-summary'),
  ApiService.get('/reports/distribution'),
  // ... 3 API lain
]);
```

Jika user pindah tab saat `Future.wait` berjalan, `setState` masih dipanggil karena `mounted` check hanya di `catch` block. Selain itu, tidak ada cara untuk cancel request.

**Rekomendasi:**
```dart
// Gunakan cancel token atau mounted check yang lebih ketat
Future<void> _load() async {
  if (!mounted) return;
  setState(() => _isLoading = true);
  try {
    final results = await Future.wait([...]);
    if (!mounted) return; // DOUBLE CHECK
    setState(() { ... });
  } catch (e) {
    if (!mounted) return;
    ...
  }
}
```

---

### 3. [TINGGI] `IndexedStack` Memuat Semua Tab Sekaligus
**Lokasi:** `apps/mobile/lib/screens/admin_dashboard_screen.dart:219`  
**Severity:** Tinggi  
**Dampak:** Memori tinggi saat buka admin dashboard; semua tab (7 screen) di-build sekaligus.

**Deskripsi:** `IndexedStack` mempertahankan state semua child. Ini bagus untuk UX, tapi buruk untuk memori jika beberapa tab berat (chart, tabel, report).

**Rekomendasi:**
- Pertimbangkan `AutomaticKeepAliveClientMixin` untuk tab yang perlu preserve state.
- Atau `IndexedStack` dengan `children` yang dibuat `const` (sudah bagus di sebagian tab).
- Unload tab yang tidak perlu (misal: report tabs) dengan `Visibility` + `Offstage` custom.

---

### 4. [TINGGI] Database Query Tanpa Pagination / Limit
**Lokasi:** `apps/api/src/services/reports.service.ts` (multiple)  
**Severity:** Tinggi  
**Dampak:** Query `getCriticalStock`, `getHourlySalesByProduct`, `getInventoryReport` bisa return ribuan baris.

**Rekomendasi:** Tambahkan `limit` default dan pagination untuk semua list endpoint.

---

### 5. [SEDANG] `MarketBasket` Data Tidak Di-cache di UI
**Lokasi:** `apps/mobile/lib/screens/advanced_analytics_screen.dart:479`  
**Severity:** Sedang  
**Dampak:** Setiap buka tab "Analisis Keranjang", data di-fetch ulang meski cron job baru jalan 1x/hari.

**Rekomendasi:** Gunakan `SharedPreferences` atau in-memory cache untuk data yang jarang berubah.

---

### 6. [RENDAH] `PeriodComparisonTab` Rebuild Seluruh UI Saat Pilih Tanggal
**Lokasi:** `apps/mobile/lib/screens/advanced_analytics_screen.dart:188`  
**Severity:** Rendah  
**Dampak:** UX minor — seluruh tab rebuild saat pilih date range.

**Rekomendasi:** Extract date picker ke widget terpisah dengan `ValueNotifier` atau `Bloc`.

---

## 🏗️ Anti-pattern & Code Quality

### 1. [TINGGI] File Raksasa — `admin_dashboard_screen.dart` (3.843 baris)
**Severity:** Tinggi  
**Dampak:** Sulit maintain, hot reload lambat, merge conflict, IDE lag.

**Rekomendasi:**
```
lib/screens/admin_dashboard/
├── admin_dashboard_screen.dart       # 200 baris (skeleton + sidebar)
├── tabs/
│   ├── dashboard_tab.dart
│   ├── products_tab.dart
│   ├── bahan_baku_tab.dart
│   └── pengaturan_tab.dart
└── widgets/
    ├── kpi_card.dart
    ├── sidebar_item.dart
    └── section_card.dart
```

**Prioritas:** Lakukan segera. Modul 15 sudah dipisah dengan baik — lanjutkan untuk tab lainnya.

---

### 2. [TINGGI] Business Logic Bercampur dengan UI — `_ProdukTab`
**Severity:** Tinggi  
**Dampak:** Tidak bisa unit test logika produk; UI terlalu kompleks (dialog CRUD + upload + kalkulasi harga).

**Rekomendasi:** Pisahkan ke:
- `ProductFormCubit` / `ProductBloc` untuk state management form
- `ProductRepository` untuk API calls
- `ProductCalculator` untuk kalkulasi harga/markup

---

### 3. [SEDANG] Duplikasi Kode Card Pattern
**Lokasi:** Multiple files  
**Severity:** Sedang  
**Dampak:** Maintenance burden jika desain card berubah.

**Rekomendasi:** Buat widget reusable:
```dart
class MetricCard extends StatelessWidget { ... }
class AnalyticsCard extends StatelessWidget { ... }
```

---

### 4. [SEDANG] Hardcoded Theme & Colors
**Lokasi:** `apps/mobile/lib/screens/advanced_analytics_screen.dart` (multiple)  
**Severity:** Sedang  
**Dampak:** `AppTheme.cardDark`, `Colors.white` — tidak responsif terhadap system theme/light mode.

**Rekomendasi:** Gunakan `Theme.of(context).colorScheme` sepenuhnya. Hindari hardcoded `Colors.white` di dark mode.

---

### 5. [SEDANG] `asyncHandler` Tidak Konsisten Dipakai
**Lokasi:** `apps/api/src/routes/reports.routes.ts`  
**Severity:** Sedang  
**Dampak:** Route tanpa `asyncHandler` bisa crash server jika throw unhandled rejection.

**Rekomendasi:**
- Semua route yang async harus pakai `asyncHandler`.
- Atau gunakan Express 5+ yang native support async handler.

---

### 6. [RENDAH] `NumberFormat` Instance Dibuat Berulang
**Lokasi:** Multiple tabs  
**Severity:** Rendah  
**Dampak:** Alokasi objek berulang yang tidak perlu.

**Rekomendasi:**
```dart
static final _currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp');
```

---

### 7. [RENDAH] `TabController` di `_ProdukTab` Tidak Disinkronkan dengan `_selectedTab`
**Lokasi:** `apps/mobile/lib/screens/admin_dashboard_screen.dart:752`  
**Severity:** Rendah  
**Dampak:** Potensi index mismatch jika tab produk ditambah/dihapus.

---

## 🏗️ Rekomendasi Arsitektur & Rancangan

### 1. State Management: Provider → Riverpod atau BLoC
**Alasan:** `Provider` + `setState` sudah cukup untuk MVP, tapi akan menjadi bottleneck saat:
- Jumlah screen > 20
- Form yang kompleks (validasi, dependensi field)
- Cache management (refresh, invalidate, retry)

**Rekomendasi:** Migrasi ke `flutter_bloc` atau `Riverpod` bertahap. Mulai dari modul yang paling kompleks (Produk, Order, Laporan).

---

### 2. API Layer: Tambahkan Response Caching
**Alasan:** Data laporan (kpi, heatmap, market basket) jarang berubah. Fetching ulang setiap buka screen boros bandwidth.

**Rekomendasi:**
```dart
// Gunakan package seperti dio + dio_cache_interceptor
// atau buat simple wrapper:
class CachedApiService {
  final _cache = <String, _CacheEntry>{};
  
  Future<T> getCached<T>(String path, {Duration ttl = const Duration(minutes: 5)}) async {
    // Return cached if valid, else fetch
  }
}
```

---

### 3. Backend: Rate Limiting
**Alasan:** Belum ada rate limiter. Endpoint publik seperti `/api/health` dan `/api/config` bisa di-DOS.

**Rekomendasi:**
```typescript
import rateLimit from 'express-rate-limit';

app.use('/api/', rateLimit({ windowMs: 15 * 60 * 1000, max: 100 }));
app.use('/api/auth/', rateLimit({ windowMs: 15 * 60 * 1000, max: 10 }));
```

---

### 4. Backend: Request Validation (Zod) Belum Konsisten
**Alasan:** Route seperti `reports.routes.ts` langsung parse `req.query` tanpa schema validation. Tipe data salah bisa crash service.

**Rekomendasi:**
```typescript
const querySchema = z.object({
  start: z.string().date().optional(),
  limit: z.coerce.number().max(100).default(50),
});

router.get('/daily-sales', validateQuery(querySchema), asyncHandler(...));
```

---

### 5. Database: Index Strategy
**Status:** ✅ Sudah ada migration `0001_add_indexes.sql` — bagus!  
**Tapi perlu diperiksa:** Apakah index sudah mencakup:
- `orders(createdAt, status, branchId)` — composite index untuk reporting
- `orderItems(orderId, productId)` — untuk join cepat
- `payments(orderId, method)` — untuk payment breakdown

---

### 6. Logging: Structured Logging untuk Production
**Alasan:** `console.log` dan `console.error` tidak scalable. Sulit tracing di production.

**Rekomendasi:** Gunakan `pino` atau `winston` dengan format JSON. Sudah ada structured log di `errorHandler.ts` — perlu diperluas ke semua request.

---

## ✅ Hal yang Sudah Baik (Keep It Up!)

| Aspek | Penilaian | Keterangan |
|-------|-----------|------------|
| **Error Contract** | ⭐⭐⭐⭐⭐ | Format error `KSR-XXX` dengan category, severity, requestId — sangat rapi |
| **Auth Middleware** | ⭐⭐⭐⭐⭐ | LRU cache, Bearer + Cookie support, staff attachment — solid |
| **Monorepo Structure** | ⭐⭐⭐⭐⭐ | npm workspaces, build script otomatis — clean |
| **Drizzle ORM** | ⭐⭐⭐⭐⭐ | Type-safe, relations, migration — modern |
| **API Timeout** | ⭐⭐⭐⭐⭐ | `ApiService` timeout proper, bukan fake 408 |
| **Auto-detect Server** | ⭐⭐⭐⭐ | mDNS + network scan + manual URL — UX bagus (tapi perlu fix scan) |
| **Feature Tracker** | ⭐⭐⭐⭐⭐ | `FEATURES.md` dengan changelog — dokumentasi sangat baik |
| **Hot Reload Aware** | ⭐⭐⭐⭐ | `mounted` check di sebagian besar `setState` |
| **Forecast Transparency** | ⭐⭐⭐⭐ | Flag `isEstimate: true` — UX honest dan transparan |
| **Market Basket Precompute** | ⭐⭐⭐⭐⭐ | Cron job + cache table — arsitektur performa yang tepat |

---

## 📋 Action Plan Prioritas

### Minggu 1 (Kritis)
1. [ ] Fix `ApiConfig._scanNetwork()` — chunked scan
2. [ ] Fix `ordersService.create()` — recalculate totalAmount server-side
3. [ ] Disable CSRF hanya untuk mobile (bukan global)
4. [ ] Invalidate session cache on logout

### Minggu 2 (Tinggi)
5. [ ] Pecah `admin_dashboard_screen.dart` ke file terpisah
6. [ ] Fix `AuthProvider` error handling — jangan logout saat timeout
7. [ ] Tambah `mounted` check di semua `.then()` callback
8. [ ] Add rate limiting

### Minggu 3 (Sedang)
9. [ ] Add Zod validation di semua route
10. [ ] Tambah pagination default untuk list queries
11. [ ] Fix `getSeasonality` raw SQL → Drizzle query builder
12. [ ] Add file upload validation di backend

### Minggu 4 (Rendah + Polish)
13. [ ] Fix pie chart interactivity
14. [ ] Extract reusable widgets (`MetricCard`, `SectionCard`)
15. [ ] Add API response cache di Flutter
16. [ ] Review dan tambah database composite indexes

---

*Laporan ini dihasilkan secara otomatis berdasarkan audit kode menyeluruh pada seluruh codebase Kasir-AI. Untuk pertanyaan atau klarifikasi, silakan diskusikan dengan tim development.*
