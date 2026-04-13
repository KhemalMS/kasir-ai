import 'api_service.dart';

class CategoriesService {
  static Future<List<dynamic>> getAll() async {
    return ApiService.getList('/categories');
  }
}
