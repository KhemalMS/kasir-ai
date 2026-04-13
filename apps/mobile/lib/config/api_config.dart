import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  // Auto-configured by start.bat
  static String _baseUrl = 'http://192.168.1.152:3001/api';
  static const int connectTimeout = 10;
  static const int receiveTimeout = 30;

  static String get baseUrl => _baseUrl;
  static set baseUrl(String url) => _baseUrl = url;

  static Future<void> loadSavedUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('api_base_url');
    if (saved != null && saved.isNotEmpty) {
      if (saved.contains(':3001/api')) {
        _baseUrl = saved;
      } else {
        await prefs.remove('api_base_url');
      }
    }
  }

  static Future<void> setBaseUrl(String url) async {
    _baseUrl = url;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_base_url', url);
  }
}
