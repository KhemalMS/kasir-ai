import 'api_service.dart';

class ProductsService {
  static Future<List<dynamic>> getAll({String? categoryId, String? search}) async {
    final params = <String>[];
    if (categoryId != null) params.add('categoryId=$categoryId');
    if (search != null && search.isNotEmpty) params.add('search=$search');
    final query = params.isNotEmpty ? '?${params.join('&')}' : '';
    return ApiService.getList('/products$query');
  }

  static Future<Map<String, dynamic>> getById(String id) async {
    return ApiService.get('/products/$id');
  }
}
