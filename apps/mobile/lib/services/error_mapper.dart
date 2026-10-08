
import '../services/error_notifier.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../models/app_error.dart';
import '../services/api_service.dart';
import '../services/app_error_logger.dart';

/// [ErrorMapper] mengkonversi semua jenis exception/error menjadi [AppError]
/// yang terstandar. Gunakan ini di setiap catch block.
///
/// Penggunaan:
/// ```dart
/// try {
///   await ApiService.get('/produk');
/// } catch (e, stack) {
///   final appError = ErrorMapper.from(e, stack,
///     module: 'kasir', action: 'loadProduk', endpoint: '/produk');
///   ErrorNotifier.show(appError);
/// }
/// ```
class ErrorMapper {
  ErrorMapper._();

  /// Konversi error apapun menjadi [AppError] terstandar.
  ///
  /// Setiap error yang di-konversi akan otomatis dilog ke [AppErrorLogger].
  static AppError from(
    dynamic error,
    StackTrace? stack, {
    required String module,
    required String action,
    String? endpoint,
    String? method,
    bool canRetry = false,
  }) {
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final now = DateTime.now();

    AppError result;

    // ── ApiException (dari ApiService) ─────────────────────────
    if (error is ApiException) {
      result = _fromApiException(error, id, now,
          module: module, action: action, endpoint: endpoint, method: method);
    }
    // ── TimeoutException (network timeout) ──────────────────────
    else if (error is TimeoutException) {
      result = AppError(
        id: id,
        timestamp: now,
        category: ErrorCategory.network,
        severity: ErrorSeverity.warning,
        module: module,
        action: action,
        userMessage: 'Koneksi ke server terlalu lama. Periksa jaringan dan coba lagi.',
        technicalMessage: 'TimeoutException: ${error.message}',
        endpoint: endpoint,
        method: method,
        canRetry: true,
        raw: error,
      );
    }
    // ── SocketException (tidak ada koneksi) ────────────────────
    else if (error is SocketException) {
      result = AppError(
        id: id,
        timestamp: now,
        category: ErrorCategory.network,
        severity: ErrorSeverity.error,
        module: module,
        action: action,
        userMessage: 'Tidak dapat terhubung ke server. Pastikan API aktif dan jaringan tersedia.',
        technicalMessage: 'SocketException: ${error.message}',
        endpoint: endpoint,
        method: method,
        canRetry: true,
        raw: error,
      );
    }
    // ── FormatException (JSON parsing gagal) ───────────────────
    else if (error is FormatException) {
      result = AppError(
        id: id,
        timestamp: now,
        category: ErrorCategory.api,
        severity: ErrorSeverity.error,
        module: module,
        action: action,
        userMessage: 'Respons server tidak dapat dibaca. Hubungi administrator.',
        technicalMessage: 'FormatException: ${error.message}',
        endpoint: endpoint,
        method: method,
        canRetry: false,
        raw: error,
      );
    }
    // ── Generic / Unknown ──────────────────────────────────────
    else {
      result = AppError(
        id: id,
        timestamp: now,
        category: ErrorCategory.unknown,
        severity: ErrorSeverity.error,
        module: module,
        action: action,
        userMessage: 'Terjadi kesalahan yang tidak terduga.',
        technicalMessage: error.toString(),
        endpoint: endpoint,
        method: method,
        canRetry: canRetry,
        raw: error,
      );
    }

    // Log setiap error yang terkonversi (dengan requestId dari API jika ada)
    final requestId = error is ApiException ? error.requestIdHeader : null;
    AppErrorLogger.log(result, stack: stack, requestId: requestId);

    return result;
  }

  static AppError _fromApiException(
    ApiException e,
    String id,
    DateTime now, {
    required String module,
    required String action,
    String? endpoint,
    String? method,
  }) {
    final status = e.statusCode;

    // Coba parse body JSON dari ApiException jika ada
    Map<String, dynamic>? body;
    try {
      if (e.responseBody != null) body = jsonDecode(e.responseBody!) as Map<String, dynamic>;
    } catch (_) {}

    final apiCode    = body?['code']      as String?;
    final requestId  = body?['requestId'] as String? ?? e.requestIdHeader;
    final apiMessage = body?['message']   as String?;
    final details    = body?['details']   as Map<String, dynamic>?;

    // Field-level validation errors
    Map<String, String>? fieldErrors;
    if (status == 400 && details != null) {
      final fields = details['fields'];
      if (fields is List) {
        fieldErrors = {
          for (final f in fields)
            if (f is Map && f['field'] != null && f['message'] != null)
              f['field'].toString(): f['message'].toString()
        };
      }
    }

    ErrorCategory category;
    ErrorSeverity severity;
    String userMessage;
    bool canRetry = false;

    switch (status) {
      case 400:
        category = ErrorCategory.validation;
        severity = ErrorSeverity.info;
        userMessage = apiMessage ?? 'Data yang dikirim tidak valid. Periksa kembali isian form.';
        break;
      case 401:
        category = ErrorCategory.auth;
        severity = ErrorSeverity.warning;
        userMessage = 'Sesi telah berakhir. Silakan login kembali.';
        break;
      case 403:
        category = ErrorCategory.auth;
        severity = ErrorSeverity.warning;
        userMessage = apiMessage ?? 'Anda tidak memiliki akses ke fitur ini.';
        break;
      case 404:
        category = ErrorCategory.api;
        severity = ErrorSeverity.info;
        userMessage = apiMessage ?? 'Data tidak ditemukan.';
        break;
      case 408:
        category = ErrorCategory.network;
        severity = ErrorSeverity.warning;
        userMessage = 'Permintaan ke server timeout. Periksa jaringan dan coba lagi.';
        canRetry = true;
        break;
      case 409:
        category = ErrorCategory.businessRule;
        severity = ErrorSeverity.warning;
        userMessage = apiMessage ?? 'Data sudah ada atau terjadi konflik.';
        break;
      case 422:
        category = ErrorCategory.businessRule;
        severity = ErrorSeverity.warning;
        userMessage = apiMessage ?? 'Permintaan tidak dapat diproses karena aturan bisnis.';
        break;
      default:
        if (status >= 500) {
          category = ErrorCategory.database;
          severity = ErrorSeverity.critical;
          userMessage = 'Terjadi kesalahan pada server. Hubungi administrator jika berlanjut.';
          canRetry = true;
        } else {
          category = ErrorCategory.unknown;
          severity = ErrorSeverity.error;
          userMessage = apiMessage ?? 'Terjadi kesalahan (kode $status).';
        }
    }

    return AppError(
      id: id,
      timestamp: now,
      category: category,
      severity: severity,
      module: module,
      action: action,
      code: apiCode,
      userMessage: userMessage,
      technicalMessage: e.message,
      statusCode: status,
      method: method,
      endpoint: endpoint,
      requestId: requestId,
      canRetry: canRetry,
      fieldErrors: fieldErrors,
      raw: e,
    );
  }
}
