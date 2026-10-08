import 'package:flutter/foundation.dart';

import '../models/app_error.dart';
import '../services/error_mapper.dart';

/// Kategori error — sesuai API Error Contract (KSR)
enum ErrorCategory {
  network,
  auth,
  validation,
  api,
  database,
  businessRule,
  report,
  upload,
  print,
  unknown,
}

/// Severity level error
enum ErrorSeverity { info, warning, error, critical }

/// Model error terpusat untuk semua error di Kasir-AI Flutter.
/// Dihasilkan oleh [ErrorMapper] dan dikonsumsi oleh UI components.
@immutable
class AppError {
  final String id;
  final DateTime timestamp;
  final ErrorCategory category;
  final ErrorSeverity severity;

  /// Nama modul yang mengalami error (kasir, laporan, auth, dll)
  final String module;

  /// Nama aksi yang sedang dilakukan saat error (loadProduk, buatOrder, dll)
  final String action;

  /// Kode error dari API (misal: KSR-400, KSR-500)
  final String? code;

  /// Pesan yang aman dan ramah user
  final String userMessage;

  /// Pesan teknis untuk developer/debugging
  final String? technicalMessage;

  /// HTTP status code (null jika network error)
  final int? statusCode;

  /// HTTP method (GET/POST/PUT/DELETE)
  final String? method;

  /// API endpoint yang dipanggil
  final String? endpoint;

  /// X-Request-Id dari response header backend
  final String? requestId;

  /// Apakah error ini bisa di-retry oleh user
  final bool canRetry;

  /// Field-level validation errors: { fieldName: pesan }
  final Map<String, String>? fieldErrors;

  /// Raw error object untuk debugging
  final dynamic raw;

  const AppError({
    required this.id,
    required this.timestamp,
    required this.category,
    required this.severity,
    required this.module,
    required this.action,
    required this.userMessage,
    this.code,
    this.technicalMessage,
    this.statusCode,
    this.method,
    this.endpoint,
    this.requestId,
    this.canRetry = false,
    this.fieldErrors,
    this.raw,
  });

  /// Apakah error ini punya detail teknis yang bisa ditampilkan
  bool get hasDetails =>
      requestId != null || endpoint != null || code != null || technicalMessage != null;

  /// Label kategori dalam Bahasa Indonesia
  String get categoryLabel {
    switch (category) {
      case ErrorCategory.network:    return 'Jaringan';
      case ErrorCategory.auth:       return 'Autentikasi';
      case ErrorCategory.validation: return 'Validasi';
      case ErrorCategory.api:        return 'API';
      case ErrorCategory.database:   return 'Database';
      case ErrorCategory.businessRule: return 'Bisnis';
      case ErrorCategory.report:     return 'Laporan';
      case ErrorCategory.upload:     return 'Upload';
      case ErrorCategory.print:      return 'Print';
      case ErrorCategory.unknown:    return 'Tidak Diketahui';
    }
  }

  /// Warna untuk ikon/border berdasarkan severity (hex string)
  String get severityColor {
    switch (severity) {
      case ErrorSeverity.info:     return '#3B82F6'; // primary blue
      case ErrorSeverity.warning:  return '#F59E0B'; // warning yellow
      case ErrorSeverity.error:    return '#EF4444'; // danger red
      case ErrorSeverity.critical: return '#DC2626'; // deep red
    }
  }

  /// Format ringkas untuk copy-paste: kode + requestId + waktu + technical details
  String get copyableDetails {
    final parts = <String>[
      if (code != null) 'Kode: $code',
      if (requestId != null) 'Request ID: $requestId',
      if (endpoint != null) 'Endpoint: ${method ?? 'GET'} $endpoint',
      'Waktu: ${timestamp.toLocal().toString().substring(0, 19)}',
      'Pesan: $userMessage',
      if (technicalMessage != null && technicalMessage!.isNotEmpty) 'Technical: $technicalMessage',
    ];
    return parts.join('\n');
  }

  AppError copyWith({
    String? userMessage,
    bool? canRetry,
    Map<String, String>? fieldErrors,
  }) {
    return AppError(
      id: id,
      timestamp: timestamp,
      category: category,
      severity: severity,
      module: module,
      action: action,
      code: code,
      userMessage: userMessage ?? this.userMessage,
      technicalMessage: technicalMessage,
      statusCode: statusCode,
      method: method,
      endpoint: endpoint,
      requestId: requestId,
      canRetry: canRetry ?? this.canRetry,
      fieldErrors: fieldErrors ?? this.fieldErrors,
      raw: raw,
    );
  }

  @override
  String toString() => 'AppError(${code ?? category.name}: $userMessage)';
}
