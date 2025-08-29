// 商店相关的延迟加载组件
import 'package:flutter/material.dart';

// 导出商店相关的所有组件
export '../presentation/screens/shop/shop_screen.dart';
export '../presentation/screens/shop/my_shop_screen.dart';
export '../core/services/shop_api_service.dart';
export '../core/models/shop_item.dart';

// 商店功能的延迟加载包装器
class DeferredShopWrapper {
  static const String componentName = 'shop';
  
  // 预加载函数，可以在用户可能需要时提前调用
  static Future<void> preload() async {
    // 这里可以添加预加载逻辑，比如预取数据
  }
}
