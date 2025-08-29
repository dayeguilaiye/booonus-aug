import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../services/auth_api_service.dart';
import '../models/user.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoggedIn = false;

  bool get isLoggedIn => _isLoggedIn;

  AuthProvider() {
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final token = StorageService.getToken();
    final wasLoggedIn = _isLoggedIn;
    _isLoggedIn = token != null;

    // 只有当登录状态真正改变时才通知监听者
    if (wasLoggedIn != _isLoggedIn) {
      notifyListeners();
    }
  }

  Future<bool> login(String username, String password) async {
    try {
      final response = await AuthApiService.login(username, password);

      if (response['token'] != null) {
        await StorageService.saveToken(response['token']);
        if (response['user'] != null) {
          await StorageService.saveUserInfo(response['user']);
        }
        _isLoggedIn = true;
        notifyListeners(); // 只在登录成功时通知
        return true;
      } else {
        throw Exception('登录失败：无效的响应');
      }
    } catch (e) {
      // 重新抛出异常，让调用方处理
      rethrow;
    }
  }

  Future<bool> register(String username, String password) async {
    try {
      final response = await AuthApiService.register(username, password);

      if (response['token'] != null) {
        await StorageService.saveToken(response['token']);
        if (response['user'] != null) {
          await StorageService.saveUserInfo(response['user']);
        }
        _isLoggedIn = true;
        notifyListeners(); // 只在注册成功时通知
        return true;
      } else {
        throw Exception('注册失败：无效的响应');
      }
    } catch (e) {
      // 重新抛出异常，让调用方处理
      rethrow;
    }
  }

  Future<void> logout() async {
    await StorageService.removeToken();
    await StorageService.removeUserInfo();
    _isLoggedIn = false;
    notifyListeners();
  }


}
