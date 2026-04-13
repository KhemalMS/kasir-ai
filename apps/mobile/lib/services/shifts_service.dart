import 'api_service.dart';

class ShiftsService {
  static Future<Map<String, dynamic>> startShift({
    required String staffId,
    required String branchId,
    required int startingCash,
  }) async {
    return ApiService.post('/shifts/start', {
      'staffId': staffId,
      'branchId': branchId,
      'startingCash': startingCash,
    });
  }

  static Future<Map<String, dynamic>> closeShift({
    required String id,
    required int endingCash,
  }) async {
    return ApiService.post('/shifts/$id/close', {
      'endingCash': endingCash,
    });
  }

  static Future<Map<String, dynamic>?> getCurrentShift(String staffId) async {
    try {
      final result = await ApiService.get('/shifts/current?staffId=$staffId');
      return result;
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, dynamic>> getShiftSummary(String shiftId) async {
    return ApiService.get('/shifts/$shiftId/summary');
  }

  static Future<List<dynamic>> getAll({String? branchId, String? staffId}) async {
    final params = <String>[];
    if (branchId != null) params.add('branchId=$branchId');
    if (staffId != null) params.add('staffId=$staffId');
    final query = params.isNotEmpty ? '?${params.join('&')}' : '';
    return ApiService.getList('/shifts$query');
  }
}
