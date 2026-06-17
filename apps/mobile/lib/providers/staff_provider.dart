import 'package:flutter/material.dart';
import '../services/api_service.dart';

class StaffProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _staffList = [];
  bool _isLoading = false;
  String? _error;

  String _searchQuery = '';
  String? _roleFilter;
  String? _statusFilter;
  String? _branchFilter;

  int _currentPage = 1;
  int _totalPages = 1;
  int _totalItems = 0;
  int _limit = 6;

  // Getters
  List<Map<String, dynamic>> get staffList => _staffList;
  bool get isLoading => _isLoading;
  String? get error => _error;

  String get searchQuery => _searchQuery;
  String? get roleFilter => _roleFilter;
  String? get statusFilter => _statusFilter;
  String? get branchFilter => _branchFilter;
  
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  int get totalItems => _totalItems;
  int get limit => _limit;

  // For compatibility with older code, return all fetched staff
  List<Map<String, dynamic>> get filteredStaff => _staffList;

  // Setters for filters
  void setSearchQuery(String query) {
    _searchQuery = query;
    _currentPage = 1;
    notifyListeners();
    loadStaff();
  }

  void setRoleFilter(String? role) {
    _roleFilter = role;
    _currentPage = 1;
    notifyListeners();
    loadStaff();
  }

  void setStatusFilter(String? status) {
    _statusFilter = status;
    _currentPage = 1;
    notifyListeners();
    loadStaff();
  }

  void setBranchFilter(String? branchId) {
    _branchFilter = branchId;
    _currentPage = 1;
    notifyListeners();
    loadStaff();
  }
  
  void setPage(int page) {
    if (page < 1 || page > _totalPages) return;
    _currentPage = page;
    notifyListeners();
    loadStaff();
  }

  void clearFilters() {
    _searchQuery = '';
    _roleFilter = null;
    _statusFilter = null;
    _branchFilter = null;
    _currentPage = 1;
    notifyListeners();
    loadStaff();
  }

  // Load Staff
  Future<void> loadStaff() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final queryParams = <String>[];
      queryParams.add('page=$_currentPage');
      queryParams.add('limit=$_limit');
      
      if (_searchQuery.isNotEmpty) queryParams.add('search=${Uri.encodeComponent(_searchQuery)}');
      if (_roleFilter != null) queryParams.add('role=${Uri.encodeComponent(_roleFilter!)}');
      if (_statusFilter != null) queryParams.add('status=${Uri.encodeComponent(_statusFilter!)}');
      if (_branchFilter != null) queryParams.add('branchId=${Uri.encodeComponent(_branchFilter!)}');
      
      final queryString = queryParams.join('&');
      final response = await ApiService.get('/staff?$queryString');
      
      if (response.containsKey('data')) {
        final List<dynamic> data = response['data'];
        _staffList = data.map((e) => e as Map<String, dynamic>).toList();
        
        if (response.containsKey('meta')) {
          final meta = response['meta'];
          _totalPages = meta['totalPages'] ?? 1;
          _totalItems = meta['total'] ?? 0;
        }
      } else {
        _staffList = [];
        _totalPages = 1;
        _totalItems = 0;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create Staff
  Future<Map<String, dynamic>> createStaff(Map<String, dynamic> data) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.post('/staff', data);
      await loadStaff(); // Reload after create
      return response; // returns { staff: {...}, tempPassword?: "..." }
    } catch (e) {
      _error = e.toString();
      throw e;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update Staff
  Future<void> updateStaff(String id, Map<String, dynamic> data) async {
    _isLoading = true;
    notifyListeners();

    try {
      await ApiService.put('/staff/$id', data);
      await loadStaff(); // Reload after update
    } catch (e) {
      _error = e.toString();
      throw e;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete Staff
  Future<void> deleteStaff(String id) async {
    _isLoading = true;
    notifyListeners();

    try {
      await ApiService.delete('/staff/$id');
      _staffList.removeWhere((s) => s['id'] == id);
    } catch (e) {
      _error = e.toString();
      throw e;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Reset PIN
  Future<void> resetPin(String id, String pin) async {
    _isLoading = true;
    notifyListeners();

    try {
      await ApiService.post('/staff/$id/reset-pin', {'pin': pin});
      await loadStaff();
    } catch (e) {
      _error = e.toString();
      throw e;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Reset Password (Admin only)
  Future<void> resetPassword(String userId, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      await ApiService.post('/auth/admin/change-password', {
        'userId': userId,
        'password': password,
      });
    } catch (e) {
      _error = e.toString();
      throw e;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
