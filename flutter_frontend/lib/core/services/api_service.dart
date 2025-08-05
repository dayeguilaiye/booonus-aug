import 'package:dio/dio.dart';
import 'storage_service.dart';

class ApiService {
  // static const String defaultBaseUrl = 'http://192.168.31.248:8080';
  static const String defaultBaseUrl = 'https://booonus.hitnrun.cn';
  late Dio _dio;
  
  ApiService() {
    _dio = Dio();
    _initializeInterceptors();
    _updateBaseUrl();
  }
  
  void _initializeInterceptors() {
    // Request interceptor - add token
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = StorageService.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        options.headers['Content-Type'] = 'application/json';
        handler.next(options);
      },
      onError: (error, handler) {
        if (error.response?.statusCode == 401) {
          // Token expired or invalid
          StorageService.removeToken();
          StorageService.removeUserInfo();
          // TODO: Navigate to login screen
        }
        handler.next(error);
      },
    ));
  }
  
  void _updateBaseUrl() {
    final savedBaseUrl = StorageService.getApiBaseUrl();
    final baseUrl = savedBaseUrl ?? defaultBaseUrl;
    _dio.options.baseUrl = '$baseUrl/api/v1';
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);
  }
  
  Future<void> updateBaseUrl(String newBaseUrl) async {
    await StorageService.saveApiBaseUrl(newBaseUrl);
    _dio.options.baseUrl = '$newBaseUrl/api/v1';
  }
  
  String getCurrentBaseUrl() {
    return StorageService.getApiBaseUrl() ?? defaultBaseUrl;
  }
  
  // Generic HTTP methods
  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    return await _dio.get(path, queryParameters: queryParameters);
  }
  
  Future<Response> post(String path, {dynamic data}) async {
    return await _dio.post(path, data: data);
  }
  
  Future<Response> put(String path, {dynamic data}) async {
    return await _dio.put(path, data: data);
  }
  
  Future<Response> delete(String path) async {
    return await _dio.delete(path);
  }
}

// Singleton instance
final apiService = ApiService();
