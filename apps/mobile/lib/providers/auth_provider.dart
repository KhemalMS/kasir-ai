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

  Future<void> checkAuth() async {
    // Don't call notifyListeners here — we're already loading by default
    await ApiService.loadToken();
    final session = await AuthService.getSession();
    
    if (session != null && session['user'] != null) {
      _user = session['user'] as Map<String, dynamic>;
      _isAuthenticated = true;
      await _fetchStaff();
    } else {
      _user = null;
      _isAuthenticated = false;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>> signIn(String email, String password) async {
    final result = await AuthService.signIn(email, password);
    _user = result['user'] as Map<String, dynamic>?;
    _isAuthenticated = _user != null;
    debugPrint('🔑 SignIn result user: $_user');
    debugPrint('🔑 User role from auth: ${_user?['role']}');
    if (_isAuthenticated) {
      await _fetchStaff();
    }
    debugPrint('🔑 Final userRole: $userRole (staff: ${_staff?['role']}, user: ${_user?['role']})');
    notifyListeners();
    return result;
  }

  Future<void> _fetchStaff() async {
    if (_user == null) return;
    try {
      final userId = _user!['id'];
      debugPrint('👤 Fetching staff for userId: $userId');
      final staffData = await ApiService.get('/staff/by-user/$userId');
      _staff = staffData;
      debugPrint('✅ Staff loaded: ${_staff?['name']} role: ${_staff?['role']} (branch: ${_staff?['branchId']})');
    } catch (e) {
      debugPrint('⚠️ Staff not found: $e');
      _staff = null;
    }
  }

  Future<void> signOut() async {
    await AuthService.signOut();
    _user = null;
    _staff = null;
    _isAuthenticated = false;
    notifyListeners();
  }
}
