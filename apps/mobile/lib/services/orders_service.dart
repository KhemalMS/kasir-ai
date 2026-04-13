import 'api_service.dart';

class OrdersService {
  static Future<Map<String, dynamic>> create({
    required String orderNumber,
    required String staffId,
    required String branchId,
    String? shiftId,
    required String orderType,
    String? tableNumber,
    required int subtotal,
    required int taxAmount,
    required int serviceAmount,
    int discountAmount = 0,
    required int totalAmount,
    String? notes,
    required List<Map<String, dynamic>> items,
    required List<Map<String, dynamic>> paymentMethods,
  }) async {
    return ApiService.post('/orders', {
      'orderNumber': orderNumber,
      'staffId': staffId,
      'branchId': branchId,
      'shiftId': shiftId,
      'orderType': orderType,
      'tableNumber': tableNumber,
      'subtotal': subtotal,
      'taxAmount': taxAmount,
      'serviceAmount': serviceAmount,
      'discountAmount': discountAmount,
      'totalAmount': totalAmount,
      'notes': notes,
      'items': items,
      'paymentMethods': paymentMethods,
    });
  }

  static Future<List<dynamic>> getAll({String? branchId, String? status, String? shiftId}) async {
    final params = <String>[];
    if (branchId != null) params.add('branchId=$branchId');
    if (status != null) params.add('status=$status');
    if (shiftId != null) params.add('shiftId=$shiftId');
    final query = params.isNotEmpty ? '?${params.join('&')}' : '';
    return ApiService.getList('/orders$query');
  }

  static Future<List<dynamic>> getByShift(String shiftId) async {
    return ApiService.getList('/orders?shiftId=$shiftId');
  }

  static Future<Map<String, dynamic>> getById(String id) async {
    return ApiService.get('/orders/$id');
  }
}
