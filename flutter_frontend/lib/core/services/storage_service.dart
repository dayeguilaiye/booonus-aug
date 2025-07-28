import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static SharedPreferences? _prefs;
  
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }
  
  static SharedPreferences get prefs {
    if (_prefs == null) {
      throw Exception('StorageService not initialized. Call StorageService.init() first.');
    }
    return _prefs!;
  }
  
  // Token management
  static Future<void> saveToken(String token) async {
    await prefs.setString('userToken', token);
  }
  
  static String? getToken() {
    return prefs.getString('userToken');
  }
  
  static Future<void> removeToken() async {
    await prefs.remove('userToken');
  }
  
  // User info management
  static Future<void> saveUserInfo(Map<String, dynamic> userInfo) async {
    await prefs.setString('userInfo', jsonEncode(userInfo));
  }

  static Map<String, dynamic>? getUserInfo() {
    final userInfoStr = prefs.getString('userInfo');
    if (userInfoStr == null) return null;
    try {
      return jsonDecode(userInfoStr) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }
  
  static Future<void> removeUserInfo() async {
    await prefs.remove('userInfo');
  }
  
  // API base URL management
  static Future<void> saveApiBaseUrl(String baseUrl) async {
    await prefs.setString('api_base_url', baseUrl);
  }
  
  static String? getApiBaseUrl() {
    return prefs.getString('api_base_url');
  }
  
  static Future<void> removeApiBaseUrl() async {
    await prefs.remove('api_base_url');
  }
  
  // Clear all data
  static Future<void> clearAll() async {
    await prefs.clear();
  }
}
