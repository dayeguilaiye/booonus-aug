// 规则相关的延迟加载组件
import 'package:flutter/material.dart';

// 导出规则相关的所有组件
export '../presentation/screens/rules/rules_screen.dart';
export '../core/services/rules_api_service.dart';
export '../core/models/rule.dart';

// 规则功能的延迟加载包装器
class DeferredRulesWrapper {
  static const String componentName = 'rules';
  
  // 预加载函数
  static Future<void> preload() async {
    // 预加载规则数据等
  }
}
