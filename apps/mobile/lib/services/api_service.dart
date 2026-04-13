import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

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



  static Future<http.Response> _timedGet(Uri uri, Map<String, String> headers) {
    return http.get(uri, headers: headers).timeout(
      Duration(seconds: ApiConfig.receiveTimeout),
      onTimeout: () => http.Response('{"error":"Request timeout"}', 408),
    );
  }

  static Future<http.Response> _timedPost(Uri uri, Map<String, String> headers, String body) {
    return http.post(uri, headers: headers, body: body).timeout(
      Duration(seconds: ApiConfig.receiveTimeout),
      onTimeout: () => http.Response('{"error":"Request timeout"}', 408),
    );
  }

  static Future<http.Response> _timedPut(Uri uri, Map<String, String> headers, String body) {
    return http.put(uri, headers: headers, body: body).timeout(
      Duration(seconds: ApiConfig.receiveTimeout),
      onTimeout: () => http.Response('{"error":"Request timeout"}', 408),
    );
  }

  static Future<http.Response> _timedDelete(Uri uri, Map<String, String> headers) {
    return http.delete(uri, headers: headers).timeout(
      Duration(seconds: ApiConfig.receiveTimeout),
      onTimeout: () => http.Response('{"error":"Request timeout"}', 408),
    );
  }

  static Future<Map<String, dynamic>> get(String path) async {
    final response = await _timedGet(
      Uri.parse('${ApiConfig.baseUrl}$path'), _headers);
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) async {
    final response = await _timedPost(
      Uri.parse('${ApiConfig.baseUrl}$path'), _headers, jsonEncode(body));
    _extractCookie(response);
    final result = _handleResponse(response);
    _extractTokenFromBody(result);
    return result;
  }

  static Future<Map<String, dynamic>> put(String path, Map<String, dynamic> body) async {
    final response = await _timedPut(
      Uri.parse('${ApiConfig.baseUrl}$path'), _headers, jsonEncode(body));
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> delete(String path) async {
    final response = await _timedDelete(
      Uri.parse('${ApiConfig.baseUrl}$path'), _headers);
    return _handleResponse(response);
  }

  static Future<List<dynamic>> getList(String path) async {
    final response = await _timedGet(
      Uri.parse('${ApiConfig.baseUrl}$path'), _headers);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(response.body);
      if (decoded is List) return decoded;
      // If server returns an object with a data array, try extracting it
      if (decoded is Map && decoded['data'] is List) return decoded['data'];
      return [];
    }
    throw ApiException('Request failed: ${response.statusCode}', response.statusCode);
  }

  static Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return {};
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic>) return body;
      return {'data': body};
    }
    String message = 'Error ${response.statusCode}';
    try {
      final body = jsonDecode(response.body);
      message = body['message']?.toString() ?? body['error']?.toString() ?? message;
    } catch (_) {}
    throw ApiException(message, response.statusCode);
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException(this.message, this.statusCode);

  @override
  String toString() => message;
}
