import 'package:dio/dio.dart';
import 'api_service.dart';

class ShopApiService {
  // 获取商品列表
  static Future<Map<String, dynamic>> getItems({int? ownerId}) async {
    try {
      final queryParams = ownerId != null ? {'owner_id': ownerId} : null;
      final response = await apiService.get('/shop', queryParameters: queryParams);
      return response.data;
    } on DioException catch (e) {
      print('Get Shop Items API Error: ${e.response?.data}');
      print('Status Code: ${e.response?.statusCode}');

      final String userFriendlyMessage = _parseShopError(e, '获取商品列表失败');
      throw Exception(userFriendlyMessage);
    }
  }

  // 创建商品
  static Future<Map<String, dynamic>> createItem({
    required String name,
    required String description,
    required int price,
  }) async {
    try {
      final response = await apiService.post('/shop', data: {
        'name': name,
        'description': description,
        'price': price,
      });
      return response.data;
    } on DioException catch (e) {
      print('Create Shop Item API Error: ${e.response?.data}');
      print('Status Code: ${e.response?.statusCode}');

      final String userFriendlyMessage = _parseShopError(e, '创建商品失败');
      throw Exception(userFriendlyMessage);
    }
  }

  // 更新商品
  static Future<Map<String, dynamic>> updateItem(int itemId, Map<String, dynamic> data) async {
    try {
      final response = await apiService.put('/shop/$itemId', data: data);
      return response.data;
    } on DioException catch (e) {
      print('Update Shop Item API Error: ${e.response?.data}');
      print('Status Code: ${e.response?.statusCode}');

      final String userFriendlyMessage = _parseShopError(e, '更新商品失败');
      throw Exception(userFriendlyMessage);
    }
  }

  // 删除商品
  static Future<Map<String, dynamic>> deleteItem(int itemId) async {
    try {
      final response = await apiService.delete('/shop/$itemId');
      return response.data;
    } on DioException catch (e) {
      print('Delete Shop Item API Error: ${e.response?.data}');
      print('Status Code: ${e.response?.statusCode}');

      final String userFriendlyMessage = _parseShopError(e, '删除商品失败');
      throw Exception(userFriendlyMessage);
    }
  }

  // 购买商品
  static Future<Map<String, dynamic>> buyItem(int itemId) async {
    try {
      final response = await apiService.post('/shop/$itemId/buy');
      return response.data;
    } on DioException catch (e) {
      print('Buy Shop Item API Error: ${e.response?.data}');
      print('Status Code: ${e.response?.statusCode}');

      final String userFriendlyMessage = _parseShopError(e, '购买商品失败');
      throw Exception(userFriendlyMessage);
    }
  }

  // 解析商店相关API错误并返回用户友好的错误信息
  static String _parseShopError(DioException e, String defaultMessage) {
    if (e.response?.data != null && e.response?.data['error'] != null) {
      final String apiError = e.response!.data['error'];

      // 根据后端返回的错误信息映射为用户友好的中文提示
      switch (apiError) {
        case 'No couple relationship found':
          return '需要先添加情侣才能使用商店功能';
        case 'Item not found':
          return '商品不存在';
        case 'Insufficient points':
          return '积分不足，无法购买该商品';
        case 'Internal server error':
          return '服务器内部错误，请稍后重试';
        default:
          return defaultMessage;
      }
    }

    // 处理网络错误等其他情况
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return '网络连接超时，请检查网络连接';
      case DioExceptionType.connectionError:
        return '网络连接失败，请检查网络设置';
      default:
        return defaultMessage;
    }
  }
}
