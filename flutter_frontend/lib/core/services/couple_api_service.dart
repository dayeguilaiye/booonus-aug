import 'package:dio/dio.dart';
import 'api_service.dart';

class CoupleApiService {
  // 邀请情侣
  static Future<Map<String, dynamic>> invite(String username) async {
    try {
      final response = await apiService.post('/couple/invite', data: {
        'username': username,
      });
      return response.data;
    } on DioException catch (e) {
      // 解析API错误并抛出用户友好的错误信息
      final String userFriendlyMessage = _parseApiError(e);

      // 记录详细错误到控制台（用于调试）
      print('API Error Details: ${e.response?.data}');
      print('Status Code: ${e.response?.statusCode}');
      print('Error Type: ${e.type}');

      throw Exception(userFriendlyMessage);
    }
  }

  // 解析API错误并返回用户友好的错误信息
  static String _parseApiError(DioException e) {
    if (e.response?.data != null && e.response?.data['error'] != null) {
      final String apiError = e.response!.data['error'];

      // 根据后端返回的错误信息映射为用户友好的中文提示
      switch (apiError) {
        case 'You already have a couple':
          return '您已经有情侣了，无法再次邀请';
        case 'Target user already has a couple':
          return '对方已经有情侣了，无法邀请';
        case 'Cannot invite yourself':
          return '不能邀请自己哦';
        case 'User not found':
          return '找不到该用户，请检查用户名是否正确';
        default:
          return '邀请失败，请稍后重试';
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
        return '邀请失败，请稍后重试';
    }
  }

  // 获取情侣信息
  static Future<Map<String, dynamic>> getCouple() async {
    try {
      print('CoupleApiService.getCouple - 开始请求');
      final response = await apiService.get('/couple');
      print('CoupleApiService.getCouple - 响应状态码: ${response.statusCode}');
      print('CoupleApiService.getCouple - 响应数据: ${response.data}');
      return response.data;
    } on DioException catch (e) {
      print('CoupleApiService.getCouple - DioException发生');
      print('Get Couple API Error: ${e.response?.data}');
      print('Status Code: ${e.response?.statusCode}');
      print('Error Type: ${e.type}');
      print('Error Message: ${e.message}');

      if (e.response?.statusCode == 404) {
        print('CoupleApiService.getCouple - 404错误，没有情侣关系');
        throw Exception('暂无情侣关系');
      }

      print('CoupleApiService.getCouple - 其他错误');
      throw Exception('获取情侣信息失败，请稍后重试');
    }
  }

  // 解除情侣关系
  static Future<Map<String, dynamic>> removeCouple() async {
    try {
      final response = await apiService.delete('/couple');
      return response.data;
    } on DioException catch (e) {
      print('Remove Couple API Error: ${e.response?.data}');
      print('Status Code: ${e.response?.statusCode}');

      String userFriendlyMessage = '解除情侣关系失败，请稍后重试';

      if (e.response?.data != null && e.response?.data['error'] != null) {
        final apiError = e.response!.data['error'];
        if (apiError == "You don't have a couple relationship") {
          userFriendlyMessage = '您当前没有情侣关系';
        }
      }

      throw Exception(userFriendlyMessage);
    }
  }
}
