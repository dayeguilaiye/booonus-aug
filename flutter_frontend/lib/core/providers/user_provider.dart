import 'package:flutter/material.dart';
import '../services/auth_api_service.dart';
import '../models/user.dart';

class UserProvider extends ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadUserProfile() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await AuthApiService.getProfile();
      if (response['user'] != null) {
        _user = User.fromJson(response['user']);
        notifyListeners();
      }
    } catch (e) {
      _setError('加载用户信息失败：${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateProfile(String username) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await AuthApiService.updateProfile(username);
      if (response['user'] != null) {
        _user = User.fromJson(response['user']);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _setError('更新用户信息失败：${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void updateUserPoints(int newPoints) {
    if (_user != null) {
      _user = _user!.copyWith(points: newPoints);
      notifyListeners();
    }
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

  void clear() {
    _user = null;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}
