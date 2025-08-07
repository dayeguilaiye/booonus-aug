import 'api_service.dart';

class PointsApiService {
  // 获取积分
  static Future<Map<String, dynamic>> getPoints() async {
    final response = await apiService.get('/points');
    return response.data;
  }
  
  // 获取积分历史
  static Future<Map<String, dynamic>> getHistory({int limit = 50, int offset = 0}) async {
    final response = await apiService.get('/points/history', queryParameters: {
      'limit': limit,
      'offset': offset,
    });
    return response.data;
  }

  // 获取指定用户的积分历史（用于查看对方的积分记录）
  static Future<Map<String, dynamic>> getUserHistory(int userId, {int limit = 50, int offset = 0}) async {
    final response = await apiService.get('/points/history/$userId', queryParameters: {
      'limit': limit,
      'offset': offset,
    });
    return response.data;
  }
  
  // 撤销操作
  static Future<Map<String, dynamic>> revert(int historyId) async {
    final response = await apiService.post('/revert/$historyId');
    return response.data;
  }

  // 取消撤销操作
  static Future<Map<String, dynamic>> cancelRevert(int historyId) async {
    final response = await apiService.post('/cancel-revert/$historyId');
    return response.data;
  }
}
