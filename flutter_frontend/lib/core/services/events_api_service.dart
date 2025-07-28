import 'package:dio/dio.dart';
import 'api_service.dart';

class EventsApiService {
  // 获取事件列表
  static Future<Map<String, dynamic>> getEvents({int limit = 50, int offset = 0}) async {
    try {
      print('EventsApiService.getEvents - 开始请求，limit: $limit, offset: $offset');
      final response = await apiService.get('/events', queryParameters: {
        'limit': limit,
        'offset': offset,
      });
      print('EventsApiService.getEvents - 响应状态码: ${response.statusCode}');
      print('EventsApiService.getEvents - 响应数据: ${response.data}');
      return response.data;
    } on DioException catch (e) {
      print('Get Events API Error: ${e.response?.data}');
      print('Status Code: ${e.response?.statusCode}');
      print('Error Type: ${e.type}');
      print('Error Message: ${e.message}');

      final String userFriendlyMessage = _parseEventsError(e, '获取事件列表失败');
      throw Exception(userFriendlyMessage);
    }
  }

  // 创建事件
  static Future<Map<String, dynamic>> createEvent({
    required int targetId,
    required String name,
    required String description,
    required int points,
  }) async {
    try {
      final response = await apiService.post('/events', data: {
        'target_id': targetId,
        'name': name,
        'description': description,
        'points': points,
      });
      return response.data;
    } on DioException catch (e) {
      print('Create Event API Error: ${e.response?.data}');
      print('Status Code: ${e.response?.statusCode}');

      final String userFriendlyMessage = _parseEventsError(e, '创建事件失败');
      throw Exception(userFriendlyMessage);
    }
  }

  // 解析事件相关API错误并返回用户友好的错误信息
  static String _parseEventsError(DioException e, String defaultMessage) {
    if (e.response?.data != null && e.response?.data['error'] != null) {
      final String apiError = e.response!.data['error'];

      // 根据后端返回的错误信息映射为用户友好的中文提示
      switch (apiError) {
        case 'No couple relationship found':
          return '需要先添加情侣才能使用事件功能';
        case 'Target user must be yourself or your couple':
          return '只能为自己或情侣创建事件';
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
