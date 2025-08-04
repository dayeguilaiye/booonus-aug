import 'auth_api_service.dart';

class UserApiService {
  // 更新用户资料（头像）
  static Future<Map<String, dynamic>> updateProfile({String? username, String? avatar}) async {
    return await AuthApiService.updateProfile(username: username, avatar: avatar);
  }
  
  // 获取用户资料
  static Future<Map<String, dynamic>> getProfile() async {
    return await AuthApiService.getProfile();
  }
}
