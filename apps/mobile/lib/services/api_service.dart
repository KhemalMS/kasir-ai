import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/app_error.dart';
import '../services/error_mapper.dart';
import '../services/app_error_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

/// HTTP client singleton untuk semua request ke Kasir-AI API.
///
/// Semua method throws [ApiException] saat error.
/// Gunakan [ErrorMapper] di catch block untuk mengkonversi ke [AppError].
///
/// Catatan arsitektur (AGENTS.md):
///   ApiService.get(path)     → Future<Map<String, dynamic>>
///   ApiService.getList(path) → Future<List<dynamic>>
class ApiService {
  static String? _sessionCookie;
  static SharedPreferences? _prefs;

  static Future<SharedPreferences> get _sharedPrefs async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  static Future<void> loadToken() async {
    final prefs = await _sharedPrefs;
    _sessionCookie = prefs.getString('session_cookie');
  }

  static Future<void> _saveCookie(String cookie) async {
    _sessionCookie = cookie;
    final prefs = await _sharedPrefs;
    await prefs.setString('session_cookie', cookie);
  }

  static Future<void> clearAuth() async {
    _sessionCookie = null;
    final prefs = await _sharedPrefs;
    await prefs.remove('session_cookie');
  }

  /// Public getter for session cookie (used by upload requests)
  static Future<String?> getSessionCookie() async {
    if (_sessionCookie != null) return _sessionCookie;
    final prefs = await _sharedPrefs;
    return prefs.getString('session_cookie');
  }

  /// Synchronous getter for Bearer token (used by dart:html XHR on web)
  static String? get sessionBearerToken {
    if (_sessionCookie == null) return null;
    return _sessionCookie!.contains('=')
        ? _sessionCookie!.split('=').sublist(1).join('=')
        : _sessionCookie;
  }

  static Map<String, String> get _headers {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (_sessionCookie != null) {
      final token = _sessionCookie!.contains('=')
          ? _sessionCookie!.split('=').sublist(1).join('=')
          : _sessionCookie!;
      headers['Authorization'] = 'Bearer $token';
      headers['Cookie'] = _sessionCookie!;
    }
    return headers;
  }

  /// Extract and save session cookie from Set-Cookie header
  static void _extractCookie(http.Response response) {
    final setCookie = response.headers['set-cookie'];
    if (setCookie != null && setCookie.contains('better-auth.session_token')) {
      final parts = setCookie.split(';');
      for (final part in parts) {
        if (part.trim().startsWith('better-auth.session_token=')) {
          _saveCookie(part.trim());
          break;
        }
      }
    }
  }

  /// Extract token from response body (for web where Set-Cookie is hidden)
  static void _extractTokenFromBody(Map<String, dynamic> body) {
    final token = body['token'];
    if (token != null && token is String && token.isNotEmpty) {
      _saveCookie('better-auth.session_token=$token');
    }
  }

  // ── Timed HTTP methods ──────────────────────────────────────────
  // Timeout yang sesungguhnya (bukan fake 408 response) agar
  // ErrorMapper bisa membedakan TimeoutException vs API error.

  static Future<http.Response> _timedGet(Uri uri, Map<String, String> headers) async {
    try {
      return await http
          .get(uri, headers: headers)
          .timeout(Duration(seconds: ApiConfig.receiveTimeout));
    } on TimeoutException {
      throw ApiException('Request timeout setelah ${ApiConfig.receiveTimeout}s', 408,
          endpoint: uri.path);
    }
  }

  static Future<http.Response> _timedPost(
      Uri uri, Map<String, String> headers, String body) async {
    try {
      return await http
          .post(uri, headers: headers, body: body)
          .timeout(Duration(seconds: ApiConfig.receiveTimeout));
    } on TimeoutException {
      throw ApiException('Request timeout setelah ${ApiConfig.receiveTimeout}s', 408,
          endpoint: uri.path);
    }
  }

  static Future<http.Response> _timedPut(
      Uri uri, Map<String, String> headers, String body) async {
    try {
      return await http
          .put(uri, headers: headers, body: body)
          .timeout(Duration(seconds: ApiConfig.receiveTimeout));
    } on TimeoutException {
      throw ApiException('Request timeout setelah ${ApiConfig.receiveTimeout}s', 408,
          endpoint: uri.path);
    }
  }

  static Future<http.Response> _timedDelete(Uri uri, Map<String, String> headers) async {
    try {
      return await http
          .delete(uri, headers: headers)
          .timeout(Duration(seconds: ApiConfig.receiveTimeout));
    } on TimeoutException {
      throw ApiException('Request timeout setelah ${ApiConfig.receiveTimeout}s', 408,
          endpoint: uri.path);
    }
  }

  // ── Upload multipart ──────────────────────────────────────────
  static Future<Map<String, dynamic>> uploadMultipart(
      String path, String fieldName, List<int> bytes, String filename) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    final request = http.MultipartRequest('POST', uri);

    if (_sessionCookie != null) {
      final token = _sessionCookie!.contains('=')
          ? _sessionCookie!.split('=').sublist(1).join('=')
          : _sessionCookie!;
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Cookie'] = _sessionCookie!;
    }

    request.files.add(
      http.MultipartFile.fromBytes(fieldName, bytes, filename: filename),
    );

    try {
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 60),
      );
      final response = await http.Response.fromStream(streamedResponse);
      return _handleResponse(response, method: 'POST', path: path);
    } on TimeoutException {
      throw ApiException('Upload timeout setelah 60 detik', 408, endpoint: path);
    }
  }

  // ── Public API methods ────────────────────────────────────────

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

  static Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) async {
    final requestId = _generateRequestId();
    debugPrint('📤 [$requestId] POST $path');
    final response = await _timedPost(
        Uri.parse('${ApiConfig.baseUrl}$path'), {..._headers, 'X-Request-ID': requestId}, jsonEncode(body));
    _extractCookie(response);
    final result = _handleResponse(response, method: 'POST', path: path, requestId: requestId);
    _extractTokenFromBody(result);
    return result;
  }

  static Future<Map<String, dynamic>> put(String path, Map<String, dynamic> body) async {
    final requestId = _generateRequestId();
    debugPrint('📤 [$requestId] PUT $path');
    final response = await _timedPut(
        Uri.parse('${ApiConfig.baseUrl}$path'), {..._headers, 'X-Request-ID': requestId}, jsonEncode(body));
    return _handleResponse(response, method: 'PUT', path: path, requestId: requestId);
  }

  static Future<Map<String, dynamic>> delete(String path) async {
    final requestId = _generateRequestId();
    debugPrint('📤 [$requestId] DELETE $path');
    final response = await _timedDelete(
        Uri.parse('${ApiConfig.baseUrl}$path'), {..._headers, 'X-Request-ID': requestId});
    return _handleResponse(response, method: 'DELETE', path: path, requestId: requestId);
  }

  /// GET yang mengharapkan response berupa array JSON.
  ///
  /// PENTING: Tidak lagi mengembalikan [] secara diam-diam jika shape respons
  /// tidak dikenali — sekarang throw ApiException agar bug terdeteksi.
  static Future<List<dynamic>> getList(String path) async {
    final response = await _timedGet(Uri.parse('${ApiConfig.baseUrl}$path'), _headers);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return [];
      final decoded = jsonDecode(response.body);
      if (decoded is List) return decoded;
      if (decoded is Map && decoded['data'] is List) return decoded['data'] as List;
      // Shape tidak dikenali — lempar exception agar bug tidak diam-diam jadi "data kosong"
      throw ApiException(
        'Response shape tidak dikenali untuk getList: expected array, got ${decoded.runtimeType}',
        200,
        endpoint: path,
        responseBody: response.body.length > 200 ? response.body.substring(0, 200) : response.body,
      );
    }

    _handleErrorResponse(response, method: 'GET', path: path);
  }

  // ── Internal response handler ─────────────────────────────────

  static Map<String, dynamic> _handleResponse(
    http.Response response, {
    required String method,
    required String path,
    String? requestId,
  }) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return {};
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic>) return body;
      return {'data': body};
    }

    _handleErrorResponse(response, method: method, path: path, requestId: requestId);
  }

  static Never _handleErrorResponse(
    http.Response response, {
    required String method,
    required String path,
    String? requestId,
  }) {
    // NOTE: Sengaja tidak memanggil clearAuth() di sini.
    // clearAuth() langsung men-null-kan _sessionCookie (synchronous),
    // yang akan merusak semua concurrent requests yang masih dalam antrian.
    // Auth state (redirect ke login, dll) dikelola oleh AuthProvider.

    // Simpan response body untuk ErrorMapper agar bisa parse requestId, details, dll
    final body = response.body;
    final requestIdHeader = response.headers['x-request-id'] ?? requestId;

    String message = 'Error ${response.statusCode}';
    try {
      final parsed = jsonDecode(body);
      message = parsed['message']?.toString() ??
          parsed['error']?.toString() ??
          message;
    } catch (_) {}

    throw ApiException(
      message,
      response.statusCode,
      endpoint: path,
      method: method,
      responseBody: body,
      requestIdHeader: requestIdHeader,
    );
  }
}

/// Exception dari API — selalu throws dari [ApiService], ditangkap oleh [ErrorMapper].
class ApiException implements Exception {
  final String message;
  final int statusCode;
  final String? endpoint;
  final String? method;

  /// Raw response body — dipakai oleh ErrorMapper untuk parse
  /// requestId, code, details dari KSR error contract.
  final String? responseBody;
  
  /// X-Request-Id dari header jika backend tidak mengirim dalam body
  final String? requestIdHeader;

  const ApiException(
    this.message,
    this.statusCode, {
    this.endpoint,
    this.method,
    this.responseBody,
    this.requestIdHeader,
  });

  @override
  String toString() => 'ApiException($statusCode): $message';
}
