import 'package:dio/dio.dart';
import 'api_service.dart';

class AuthApiService {
  // 注册
  static Future<Map<String, dynamic>> register(String username, String password) async {
    try {
      final response = await apiService.post('/register', data: {
        'username': username,
        'password': password,
      });
      return response.data;
    } on DioException catch (e) {
      print('Register API Error: ${e.response?.data}');
      print('Status Code: ${e.response?.statusCode}');

      final String userFriendlyMessage = _parseAuthError(e, '注册失败');
      throw Exception(userFriendlyMessage);
    }
  }

  // 登录
  static Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await apiService.post('/login', data: {
        'username': username,
        'password': password,
      });
      return response.data;
    } on DioException catch (e) {
      print('Login API Error: ${e.response?.data}');
      print('Status Code: ${e.response?.statusCode}');

      final String userFriendlyMessage = _parseAuthError(e, '登录失败');
      throw Exception(userFriendlyMessage);
    }
  }

  // 获取用户资料
  static Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await apiService.get('/profile');
      return response.data;
    } on DioException catch (e) {
      print('Get Profile API Error: ${e.response?.data}');
      print('Status Code: ${e.response?.statusCode}');

      final String userFriendlyMessage = _parseAuthError(e, '获取用户信息失败');
      throw Exception(userFriendlyMessage);
    }
  }

  // 更新用户资料
  static Future<Map<String, dynamic>> updateProfile(String username) async {
    try {
      final response = await apiService.put('/profile', data: {
        'username': username,
      });
      return response.data;
    } on DioException catch (e) {
      print('Update Profile API Error: ${e.response?.data}');
      print('Status Code: ${e.response?.statusCode}');

      final String userFriendlyMessage = _parseAuthError(e, '更新用户信息失败');
      throw Exception(userFriendlyMessage);
    }
  }

  // 解析认证相关API错误并返回用户友好的错误信息
  static String _parseAuthError(DioException e, String defaultMessage) {
    if (e.response?.data != null && e.response?.data['error'] != null) {
      final String apiError = e.response!.data['error'];

      // 根据后端返回的错误信息映射为用户友好的中文提示
      switch (apiError) {
        case 'Username already exists':
          return '用户名已存在，请选择其他用户名';
        case 'Invalid credentials':
          return '用户名或密码错误';
        case 'User not found':
          return '用户不存在';
        case 'Invalid token':
          return '登录已过期，请重新登录';
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
