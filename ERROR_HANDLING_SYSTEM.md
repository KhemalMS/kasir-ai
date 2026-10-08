# 🛡️ Sistem Error Handling Kasir-AI — Dokumen Rancangan

> Dokumen ini mendefinisikan arsitektur error handling menyeluruh untuk aplikasi Kasir-AI (Flutter + Express). Tujuannya: **setiap error dapat dilacak sumbernya** (file, function, endpoint, requestId) dengan cepat.

---

## 1. Arsitektur Error Handling (Layered)

```
┌─────────────────────────────────────────────────────────────────┐
│  LAYER 1: FLUTTER ERROR BOUNDARY (main.dart)                   │
│  • Menangkap widget build errors (FlutterError.onError)        │
│  • Menangkap async zone errors (runZonedGuarded)               │
│  • Menangkap platform errors (PlatformDispatcher)              │
│  → Log ke console + file, tampilkan UI fallback               │
└──────────────────────────┬────────────────────────────────────┘
                           │
┌──────────────────────────▼────────────────────────────────────┐
│  LAYER 2: API ERROR (ApiService)                             │
│  • Semua HTTP errors → ApiException (dengan requestId)     │
│  • TimeoutException → ApiException 408                      │
│  • SocketException → ditangkap di ErrorMapper               │
│  → Setiap request memiliki requestId unik                  │
└──────────────────────────┬────────────────────────────────────┘
                           │
┌──────────────────────────▼────────────────────────────────────┐
│  LAYER 3: ERROR MAPPER (ErrorMapper.from)                     │
│  • Konversi error → AppError (standarisasi)                 │
│  • Parse KSR error contract (code, requestId, details)       │
│  • Capture stack trace                                       │
│  → Log ke AppErrorLogger                                   │
└──────────────────────────┬────────────────────────────────────┘
                           │
┌──────────────────────────▼────────────────────────────────────┐
│  LAYER 4: ERROR NOTIFIER (ErrorNotifier.show)               │
│  • Tampilkan Snackbar / Dialog ke user                       │
│  • Handle 401 dengan debounce (navigate to login)            │
│  • Rate-limit: max 1 error per 3 detik                       │
│  → Prevent spam, user-friendly messages                      │
└──────────────────────────────────────────────────────────────┘
```

---

## 2. Request ID Tracing System

Setiap request HTTP dari Flutter ke API harus memiliki **requestId unik** yang dikirim di header `X-Request-ID`. Backend juga log requestId ini. Ini memungkinkan tracing penuh:

```
Flutter Request → X-Request-ID: abc123 → API Log: abc123 → Error Response: abc123
     ↓
Flutter Error Snackbar: "Request ID: abc123" → User laporkan → Developer cek API log
```

### Implementasi ApiService
```dart
static String _generateRequestId() {
  return '${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}-${math.Random().nextInt(9999).toString().padLeft(4, '0')}';
}

static Future<Map<String, dynamic>> get(String path) async {
  final requestId = _generateRequestId();
  debugPrint('📤 [$requestId] GET $path');
  final response = await _timedGet(
    Uri.parse('${ApiConfig.baseUrl}$path'),
    {..._headers, 'X-Request-ID': requestId},
  );
  return _handleResponse(response, method: 'GET', path: path, requestId: requestId);
}
```

---

## 3. AppErrorLogger (Central Logging)

Utility untuk logging error dengan format JSON yang bisa diparse:

```dart
class AppErrorLogger {
  static void log(AppError error, {StackTrace? stack, String? requestId}) {
    final logEntry = {
      'timestamp': DateTime.now().toIso8601String(),
      'requestId': requestId ?? error.requestId ?? 'N/A',
      'category': error.category.name,
      'severity': error.severity.name,
      'statusCode': error.statusCode,
      'module': error.module,
      'action': error.action,
      'endpoint': error.endpoint,
      'userMessage': error.userMessage,
      'technicalMessage': error.technicalMessage,
      'stackTrace': stack?.toString().split('\n').take(10).join('\n'),
    };
    
    // Console log (structured)
    debugPrint('🔴 ERROR [${error.categoryLabel}] ${error.action}');
    debugPrint('   RequestId: $requestId');
    debugPrint('   Status: ${error.statusCode}');
    debugPrint('   Message: ${error.technicalMessage}');
    
    // File log (async, tidak blocking)
    _writeToLogFile(jsonEncode(logEntry));
  }
  
  static void _writeToLogFile(String line) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/kasir_error_log.jsonl');
      await file.writeAsString('$line\n', mode: FileMode.append);
    } catch (_) {}
  }
}
```

---

## 4. Global Error Boundary (Flutter)

Menangkap error yang tidak tertangkap catch block:

```dart
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    _logUnhandledError(details.exception, details.stack);
  };
  
  PlatformDispatcher.instance.onError = (error, stack) {
    _logUnhandledError(error, stack);
    return true;
  };
  
  runZonedGuarded(
    () => runApp(const MyApp()),
    (error, stack) => _logUnhandledError(error, stack),
  );
}
```

---

## 5. Error Reporting Dialog (User-Friendly)

Ketika error terjadi, dialog menampilkan:
- **User message**: Pesan yang bisa dimengerti user
- **Request ID**: ID untuk dilaporkan ke support
- **Technical details**: Collapsible, untuk developer
- **Copy button**: Copy semua info + stack trace
- **Retry button**: Coba ulang jika network error

---

## 6. Rate Limiting Snackbar (Anti-Spam)

```dart
class ErrorNotifier {
  static DateTime? _lastErrorTime;
  static AppError? _pendingError;
  
  static void show(AppError error) {
    final now = DateTime.now();
    if (_lastErrorTime != null && 
        now.difference(_lastErrorTime!) < const Duration(seconds: 3)) {
      // Error terlalu cepat — skip atau queue
      _pendingError = error;
      return;
    }
    _lastErrorTime = now;
    _showSnackbar(error);
  }
}
```

---

## 7. Stack Trace Capture

Setiap error harus menyimpan stack trace asli:

```dart
catch (e, stack) {
  final appError = ErrorMapper.from(
    e, stack,
    module: 'kasir',
    action: 'loadData',
    endpoint: '/api/data',
  );
  AppErrorLogger.log(appError, stack: stack);
  ErrorNotifier.show(appError);
}
```

---

## 8. Checklist Implementasi

- [ ] ApiService: Generate dan kirim X-Request-ID
- [ ] ApiException: Simpan requestId
- [ ] ErrorMapper: Log ke AppErrorLogger
- [ ] ErrorNotifier: Rate limiting (3 detik)
- [ ] main.dart: Global error boundary
- [ ] AppErrorLogger: File logging (JSONL)
- [ ] Error dialog: Copy + Request ID display
- [ ] 401 handler: Debounce + navigate to login

---

*Dokumen ini akan diimplementasikan secara bertahap. Mulai dari ApiService (requestId) → ErrorMapper (logging) → Global boundary.*
