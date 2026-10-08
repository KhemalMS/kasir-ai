# Kasir-AI — Panduan Frontend & Build

## Dua Frontend Aktif

| Frontend | Path | Port | Status | Runner |
|---|---|---|---|---|
| **Flutter Web** (utama) | `apps/mobile/` | 8081 | ✅ Aktif | `start.bat` |
| **React Admin** (dev/legacy) | `apps/admin/` | 5173 | ⚠️ Manual | lihat di bawah |

### Flutter Web — UI Utama
Flutter Web adalah antarmuka utama yang digunakan oleh kasir dan admin.
Dijalankan otomatis oleh `start.bat`, tersedia di:
- `http://localhost:8081` (PC)
- `http://<LOCAL_IP>:8081` (HP / tablet)

### React Admin — Legacy / Dev Only
React Admin (`apps/admin/`) adalah dashboard admin berbasis React/Vite.
**Tidak dijalankan oleh `start.bat`**. Untuk menjalankannya secara manual:

```bash
cd apps/admin
npm.cmd run dev
# Buka http://localhost:5173
```

CORS untuk `localhost:5173` sudah dikonfigurasi di API.

---

## Build Scripts

### Cara Cepat: `start.bat`
```bat
start.bat              # Build Flutter + start API + start web server
start.bat --skip-build # Skip build Flutter (pakai build sebelumnya)
```

### Cara Manual: `build.bat`
Menu interaktif untuk build individual:
- `[1]` Flutter Web
- `[2]` Flutter APK
- `[3]` API TypeScript (dist/)
- `[4]` Semua

### npm Scripts (dari root)
```bash
npm.cmd run build:api    # tsc di apps/api
npm.cmd run check:api    # tsc --noEmit (type check saja)
npm.cmd run build:web    # flutter build web
npm.cmd run build:apk    # flutter build apk
npm.cmd run build:all    # build:api + build:web
npm.cmd run dev:api      # tsx watch (dev mode)
```

---

## Ports

| Service | Port | Notes |
|---|---|---|
| Flutter Web | 8081 | Served oleh `npx serve` |
| API (Express) | 3001 | `tsx watch src/index.ts` (dev) atau `node dist/index.js` (prod) |
| React Admin | 5173 | Vite dev server, manual |
| MySQL | 3306 | XAMPP |

---

## Verifikasi Build Terbaru

Setelah `start.bat`, buka browser console:
```js
fetch('/version.json').then(r=>r.json()).then(console.log)
// Cek field 'buildTime' sesuai waktu start.bat dijalankan
```

Hard Refresh: `Ctrl+Shift+R`  
Jika masih cache: DevTools → Application → Service Workers → Unregister All

---

## APK — Menghindari APK Lama di HP

Sebelum install APK baru:
1. **Uninstall APK lama** dari HP terlebih dahulu, ATAU
2. Bump `versionCode` di `apps/mobile/pubspec.yaml`:
   ```yaml
   version: 1.0.0+2  # increment +2 → +3
   ```

APK output: `apps/mobile/build/app/outputs/flutter-apk/app-release.apk`

---

## Database Migration Indexes

File migration indexes baru tersedia di `apps/api/drizzle/0001_add_indexes.sql`.
Untuk menerapkan ke database:

```bash
cd apps/api
npm.cmd run db:migrate
```

Atau jalankan SQL manual via phpMyAdmin/MySQL Workbench.

---

## Arsitektur API

```
apps/api/src/
├── index.ts          ← Entry point, CORS, semua route mount
├── lib/
│   └── better-auth.ts ← Auth config, trustedOrigins dinamis
├── middleware/        ← auth.middleware.ts, errorHandler.ts
├── routes/            ← 22 route files
├── services/          ← Business logic, 20 service files
├── db/
│   ├── index.ts       ← Drizzle DB connection
│   └── schema/        ← 26 schema files
└── utils/
    ├── dateHelpers.ts ← parseLocalDate, parseLocalDateRange (timezone-safe)
    └── queryBuilder.ts
```

### CORS Origins (selalu diizinkan tanpa env)
- `http://localhost:8081` — Flutter Web
- `http://127.0.0.1:8081` — Flutter Web (loopback)
- `http://localhost:5173` — React Admin dev
- `http://localhost:3001` — API self (dev testing)
- + semua origin dari `CORS_ORIGIN` env (LAN IP ditambahkan oleh `start.bat`)
