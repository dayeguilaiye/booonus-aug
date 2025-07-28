import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../services/auth_api_service.dart';
import '../models/user.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoggedIn = false;
  bool _isLoading = false;
  String? _error;

  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  String? get error => _error;

  AuthProvider() {
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final token = StorageService.getToken();
    _isLoggedIn = token != null;
    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await AuthApiService.login(username, password);
      
      if (response['token'] != null) {
        await StorageService.saveToken(response['token']);
        if (response['user'] != null) {
          await StorageService.saveUserInfo(response['user']);
        }
        _isLoggedIn = true;
        notifyListeners();
        return true;
      } else {
        _setError('登录失败：无效的响应');
        return false;
      }
    } catch (e) {
      _setError('登录失败：${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> register(String username, String password) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await AuthApiService.register(username, password);
      
      if (response['token'] != null) {
        await StorageService.saveToken(response['token']);
        if (response['user'] != null) {
          await StorageService.saveUserInfo(response['user']);
        }
        _isLoggedIn = true;
        notifyListeners();
        return true;
      } else {
        _setError('注册失败：无效的响应');
        return false;
      }
    } catch (e) {
      _setError('注册失败：${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    await StorageService.removeToken();
    await StorageService.removeUserInfo();
    _isLoggedIn = false;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _clearError();
  }
}
