import 'package:dio/dio.dart';
import 'api_service.dart';

class RulesApiService {
  // 获取规则列表
  static Future<Map<String, dynamic>> getRules() async {
    try {
      final response = await apiService.get('/rules');
      return response.data;
    } on DioException catch (e) {
      print('Get Rules API Error: ${e.response?.data}');
      print('Status Code: ${e.response?.statusCode}');

      final String userFriendlyMessage = _parseRulesError(e, '获取规则列表失败');
      throw Exception(userFriendlyMessage);
    }
  }

  // 创建规则
  static Future<Map<String, dynamic>> createRule({
    required String name,
    required String description,
    required int points,
    required String targetType,
  }) async {
    try {
      final response = await apiService.post('/rules', data: {
        'name': name,
        'description': description,
        'points': points,
        'target_type': targetType,
      });
      return response.data;
    } on DioException catch (e) {
      print('Create Rule API Error: ${e.response?.data}');
      print('Status Code: ${e.response?.statusCode}');

      final String userFriendlyMessage = _parseRulesError(e, '创建规则失败');
      throw Exception(userFriendlyMessage);
    }
  }

  // 更新规则
  static Future<Map<String, dynamic>> updateRule(int ruleId, {
    required String name,
    required String description,
    required int points,
    required String targetType,
  }) async {
    try {
      final response = await apiService.put('/rules/$ruleId', data: {
        'name': name,
        'description': description,
        'points': points,
        'target_type': targetType,
      });
      return response.data;
    } on DioException catch (e) {
      print('Update Rule API Error: ${e.response?.data}');
      print('Status Code: ${e.response?.statusCode}');

      final String userFriendlyMessage = _parseRulesError(e, '更新规则失败');
      throw Exception(userFriendlyMessage);
    }
  }

  // 删除规则
  static Future<Map<String, dynamic>> deleteRule(int ruleId) async {
    try {
      final response = await apiService.delete('/rules/$ruleId');
      return response.data;
    } on DioException catch (e) {
      print('Delete Rule API Error: ${e.response?.data}');
      print('Status Code: ${e.response?.statusCode}');

      final String userFriendlyMessage = _parseRulesError(e, '删除规则失败');
      throw Exception(userFriendlyMessage);
    }
  }

  // 执行规则
  static Future<Map<String, dynamic>> executeRule(int ruleId, {int? targetUserId}) async {
    try {
      final Map<String, dynamic> data = {};
      if (targetUserId != null) {
        data['target_user_id'] = targetUserId;
      }

      final response = await apiService.post('/rules/$ruleId/execute', data: data);
      return response.data;
    } on DioException catch (e) {
      print('Execute Rule API Error: ${e.response?.data}');
      print('Status Code: ${e.response?.statusCode}');

      final String userFriendlyMessage = _parseRulesError(e, '执行规则失败');
      throw Exception(userFriendlyMessage);
    }
  }

  // 解析规则相关API错误并返回用户友好的错误信息
  static String _parseRulesError(DioException e, String defaultMessage) {
    if (e.response?.data != null && e.response?.data['error'] != null) {
      final String apiError = e.response!.data['error'];

      // 根据后端返回的错误信息映射为用户友好的中文提示
      switch (apiError) {
        case 'No couple relationship found':
          return '需要先添加情侣才能使用规则功能';
        case 'Rule not found':
          return '规则不存在';
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
