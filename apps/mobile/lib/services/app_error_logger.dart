import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../models/app_error.dart';
import 'api_service.dart';

/// [AppErrorLogger] adalah central logging utility untuk error tracking.
/// Setiap error ditulis ke console (structured) dan file log (JSONL).
///
/// Format log file: `kasir_error_log.jsonl` (one JSON per line)
/// Lokasi: `getApplicationDocumentsDirectory()/kasir_error_log.jsonl`
///
/// Cara membaca log:
/// ```bash
/// adb shell run-as com.example.kasir_ai cat files/kasir_error_log.jsonl
/// ```
class AppErrorLogger {
  AppErrorLogger._();

  static bool _initialized = false;
  static File? _logFile;

  /// Inisialisasi logger (panggil sekali di main.dart)
  static Future<void> init() async {
    if (_initialized) return;
    try {
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        final dir = await getApplicationDocumentsDirectory();
        _logFile = File('${dir.path}/kasir_error_log.jsonl');
      }
    } catch (_) {}
    _initialized = true;
  }

  /// Log error dengan format terstruktur.
  ///
  /// [error] — AppError yang akan dilog
  /// [stack] — StackTrace (opsional, dari catch block)
  /// [requestId] — Request ID dari API (opsional)
  static void log(
    AppError error, {
    StackTrace? stack,
    String? requestId,
  }) {
    final now = DateTime.now();
    final rid = requestId ?? error.requestId ?? 'N/A';

    final logEntry = {
      'timestamp': now.toIso8601String(),
      'requestId': rid,
      'category': error.category.name,
      'severity': error.severity.name,
      'statusCode': error.statusCode,
      'module': error.module,
      'action': error.action,
      'endpoint': error.endpoint,
      'userMessage': error.userMessage,
      'technicalMessage': error.technicalMessage,
      'stackTrace': _formatStackTrace(stack),
    };

    // Console log (structured, developer-friendly)
    _logToConsole(error, requestId: rid);

    // File log (async, non-blocking, JSONL format)
    _logToFile(logEntry);
  }

  /// Log raw error (ApiException, generic Exception, etc.)
  static void logRaw(
    dynamic error, {
    StackTrace? stack,
    String? module,
    String? action,
    String? requestId,
  }) {
    final now = DateTime.now();
    final logEntry = {
      'timestamp': now.toIso8601String(),
      'requestId': requestId ?? 'N/A',
      'category': 'unknown',
      'severity': 'error',
      'statusCode': _extractStatusCode(error),
      'module': module ?? 'unknown',
      'action': action ?? 'unknown',
      'endpoint': _extractEndpoint(error),
      'userMessage': 'Terjadi kesalahan yang tidak terduga.',
      'technicalMessage': error.toString(),
      'stackTrace': _formatStackTrace(stack),
    };

    _logRawToConsole(error, requestId: requestId, module: module, action: action);
    _logToFile(logEntry);
  }

  /// Baca log file sebagai list of JSON maps.
  /// Gunakan untuk debugging atau export.
  static Future<List<Map<String, dynamic>>> readLogs() async {
    if (_logFile == null || !await _logFile!.exists()) return [];
    final lines = await _logFile!.readAsLines();
    return lines
        .where((line) => line.trim().isNotEmpty)
        .map((line) => jsonDecode(line) as Map<String, dynamic>)
        .toList();
  }

  /// Hapus log file (panggil setelah berhasil report / export)
  static Future<void> clearLogs() async {
    if (_logFile != null && await _logFile!.exists()) {
      await _logFile!.delete();
    }
  }

  // ── Private helpers ───────────────────────────────────────────

  static void _logToConsole(AppError error, {required String requestId}) {
    final emoji = _severityEmoji(error.severity);
    final sb = StringBuffer();
    sb.writeln('');
    sb.writeln('═' * 60);
    sb.writeln('$emoji ERROR [${error.categoryLabel}] ${error.action}');
    sb.writeln('   RequestId: $requestId');
    sb.writeln('   StatusCode: ${error.statusCode ?? 'N/A'}');
    sb.writeln('   Module: ${error.module}');
    sb.writeln('   Endpoint: ${error.endpoint ?? 'N/A'}');
    sb.writeln('   UserMessage: ${error.userMessage}');
    sb.writeln('   TechnicalMessage: ${error.technicalMessage}');
    if (error.requestId != null) {
      sb.writeln('   API-RequestId: ${error.requestId}');
    }
    sb.writeln('═' * 60);
    developer.log(sb.toString(), name: 'KasirError');
  }

  static void _logRawToConsole(
    dynamic error, {
    String? requestId,
    String? module,
    String? action,
  }) {
    final sb = StringBuffer();
    sb.writeln('');
    sb.writeln('═' * 60);
    sb.writeln('🔴 UNHANDLED ERROR');
    sb.writeln('   RequestId: ${requestId ?? 'N/A'}');
    sb.writeln('   Module: ${module ?? 'N/A'}');
    sb.writeln('   Action: ${action ?? 'N/A'}');
    sb.writeln('   Error: ${error.toString()}');
    sb.writeln('═' * 60);
    developer.log(sb.toString(), name: 'KasirError');
  }

  static void _logToFile(Map<String, dynamic> logEntry) {
    if (_logFile == null) return;
    final line = jsonEncode(logEntry);
    // Fire-and-forget: jangan await agar tidak blocking
    _logFile!.writeAsString('$line\n', mode: FileMode.append).catchError((_) {
      return _logFile!; // ignore write errors
    });
  }

  static String _formatStackTrace(StackTrace? stack) {
    if (stack == null) return 'N/A';
    final lines = stack.toString().split('\n');
    // Ambil 10 baris pertama yang relevan (skip flutter framework)
    final relevant = lines.where((line) {
      return line.contains('lib/') && 
             !line.contains('package:flutter') &&
             !line.contains('package:flutter_test');
    }).take(10);
    return relevant.join('\n');
  }

  static int? _extractStatusCode(dynamic error) {
    if (error is ApiException) return error.statusCode;
    return null;
  }

  static String? _extractEndpoint(dynamic error) {
    if (error is ApiException) return error.endpoint;
    return null;
  }

  static String _severityEmoji(ErrorSeverity s) {
    return switch (s) {
      ErrorSeverity.info => 'ℹ️',
      ErrorSeverity.warning => '⚠️',
      ErrorSeverity.error => '🔴',
      ErrorSeverity.critical => '💥',
    };
  }
}
