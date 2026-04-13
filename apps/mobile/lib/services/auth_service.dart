import '../services/api_service.dart';

class AuthService {
  static Future<Map<String, dynamic>> signIn(String email, String password) async {
    // better-auth sets session cookie automatically via Set-Cookie header
    // ApiService._extractCookie() handles saving it
    final result = await ApiService.post('/auth/sign-in/email', {
      'email': email,
      'password': password,
    });
    return result;
  }

  static Future<Map<String, dynamic>> signUp(String email, String password, String name) async {
    final result = await ApiService.post('/auth/sign-up/email', {
      'email': email,
      'password': password,
      'name': name,
    });
    return result;
  }

  static Future<void> signOut() async {
    try {
      await ApiService.post('/auth/sign-out', {});
    } catch (_) {}
    await ApiService.clearAuth();
  }

  static Future<Map<String, dynamic>?> getSession() async {
    try {
      final result = await ApiService.get('/auth/get-session');
      if (result.containsKey('user') && result['user'] != null) {
        return result;
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
