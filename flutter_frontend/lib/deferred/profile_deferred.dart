// 个人资料相关的延迟加载组件
import 'package:flutter/material.dart';

// 导出个人资料相关的所有组件
export '../presentation/screens/profile/profile_screen.dart';
export '../presentation/screens/profile/points_history_screen.dart';
export '../presentation/screens/profile/avatar_selection_screen.dart';

// 个人资料功能的延迟加载包装器
class DeferredProfileWrapper {
  static const String componentName = 'profile';
  
  // 预加载函数
  static Future<void> preload() async {
    // 预加载用户头像资源等
  }
}
