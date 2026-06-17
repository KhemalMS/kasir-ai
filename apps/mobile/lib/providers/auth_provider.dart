import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  Map<String, dynamic>? _user;
  Map<String, dynamic>? _staff;
  String? _currentShiftId;
  bool _isLoading = true;
  bool _isAuthenticated = false;

  Map<String, dynamic>? get user => _user;
  Map<String, dynamic>? get staff => _staff;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  String get userRole => _staff?['role']?.toString().toLowerCase() ?? _user?['role'] ?? 'kasir';
  String get userName => _staff?['name'] ?? _user?['name'] ?? '-';
  String get staffId => _staff?['id'] ?? '';
  String get branchId => _staff?['branchId'] ?? '';
  String? get currentShiftId => _currentShiftId;

  void setShiftId(String? id) {
    _currentShiftId = id;
    notifyListeners();
  }

  /// Cold-start: load saved token then validate via /api/auth/me
  /// Single endpoint returns both user + staff — avoids 3-step sequential calls.
  Future<void> checkAuth() async {
    await ApiService.loadToken();
    try {
      final me = await ApiService.get('/auth/me');
      if (me['user'] != null) {
        _user = me['user'] as Map<String, dynamic>;
        _staff = me['staff'] as Map<String, dynamic>?;
        _isAuthenticated = true;
        debugPrint('✅ checkAuth via /me: ${_user?['email']} role=${userRole}');
      } else {
        _user = null;
        _staff = null;
        _isAuthenticated = false;
      }
    } catch (e) {
      debugPrint('⚠️ checkAuth failed: $e');
      _user = null;
      _staff = null;
      _isAuthenticated = false;
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Login: sign-in then fetch /api/auth/me in parallel after getting token.
  /// Two calls total (signIn + /me) instead of the old three (signIn + getSession + by-user).
  Future<Map<String, dynamic>> signIn(String email, String password) async {
    final result = await AuthService.signIn(email, password);

    // /auth/sign-in already returns user in result — set it optimistically
    _user = result['user'] as Map<String, dynamic>?;
    _isAuthenticated = _user != null;

    if (_isAuthenticated) {
      // Fetch /me to get the staff record (token is now saved by ApiService)
      try {
        final me = await ApiService.get('/auth/me');
        if (me['user'] != null) {
          _user = me['user'] as Map<String, dynamic>;
        }
        _staff = me['staff'] as Map<String, dynamic>?;
        debugPrint('✅ signIn /me: ${_user?['email']} staff=${_staff?['name']} role=${userRole}');
      } catch (e) {
        // Non-fatal: we still have _user from sign-in response
        debugPrint('⚠️ /me after signIn failed, falling back: $e');
        _staff = null;
      }
    }

    debugPrint('🔑 Final userRole: $userRole');
    notifyListeners();
    return result;
  }

  Future<void> signOut() async {
    await AuthService.signOut();
    _user = null;
    _staff = null;
    _isAuthenticated = false;
    notifyListeners();
  }

  Future<void> updateName(String name) async {
    await ApiService.post('/auth/update-user', {'name': name});
    // Refresh via /me instead of full checkAuth to stay fast
    try {
      final me = await ApiService.get('/auth/me');
      if (me['user'] != null) _user = me['user'] as Map<String, dynamic>;
      _staff = me['staff'] as Map<String, dynamic>?;
      notifyListeners();
    } catch (_) {
      await checkAuth();
    }
  }

  Future<void> changePassword(String currentPassword, String newPassword) async {
    await ApiService.post('/auth/change-password', {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
      'revokeOtherSessions': true,
    });
  }

  Future<void> adminChangePassword(String userId, String newPassword) async {
    await ApiService.post('/auth/admin/change-password', {
      'userId': userId,
      'password': newPassword,
    });
  }
}
