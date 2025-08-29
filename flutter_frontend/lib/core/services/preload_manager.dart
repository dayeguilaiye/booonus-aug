// 预加载管理器 - 智能预加载延迟组件
import 'dart:async';

import '../../deferred/shop_deferred.dart' deferred as shop_deferred;
import '../../deferred/profile_deferred.dart' deferred as profile_deferred;
import '../../deferred/rules_deferred.dart' deferred as rules_deferred;
import '../../deferred/settings_deferred.dart' deferred as settings_deferred;

/// 预加载管理器
/// 负责在适当的时机预加载延迟组件，提升用户体验
class PreloadManager {
  static final PreloadManager _instance = PreloadManager._internal();
  factory PreloadManager() => _instance;
  PreloadManager._internal();

  // 跟踪已加载的组件
  final Set<String> _loadedComponents = <String>{};
  final Map<String, Completer<void>> _loadingCompleters = {};

  /// 预加载所有非首屏组件
  /// 建议在用户登录成功后调用
  Future<void> preloadAllComponents() async {
    // 并行预加载所有组件，但不等待完成
    unawaited(_preloadComponent('shop', shop_deferred.loadLibrary));
    unawaited(_preloadComponent('profile', profile_deferred.loadLibrary));
    unawaited(_preloadComponent('rules', rules_deferred.loadLibrary));
    unawaited(_preloadComponent('settings', settings_deferred.loadLibrary));
  }

  /// 预加载特定组件
  Future<void> preloadComponent(String componentName) async {
    switch (componentName) {
      case 'shop':
        await _preloadComponent('shop', shop_deferred.loadLibrary);
        break;
      case 'profile':
        await _preloadComponent('profile', profile_deferred.loadLibrary);
        break;
      case 'rules':
        await _preloadComponent('rules', rules_deferred.loadLibrary);
        break;
      case 'settings':
        await _preloadComponent('settings', settings_deferred.loadLibrary);
        break;
    }
  }

  /// 检查组件是否已加载
  bool isComponentLoaded(String componentName) {
    return _loadedComponents.contains(componentName);
  }

  /// 获取组件加载状态
  Future<void> waitForComponent(String componentName) async {
    if (_loadedComponents.contains(componentName)) {
      return;
    }
    
    if (_loadingCompleters.containsKey(componentName)) {
      await _loadingCompleters[componentName]!.future;
    }
  }

  /// 内部预加载方法
  Future<void> _preloadComponent(String componentName, Future<void> Function() loadLibrary) async {
    if (_loadedComponents.contains(componentName)) {
      return;
    }

    if (_loadingCompleters.containsKey(componentName)) {
      await _loadingCompleters[componentName]!.future;
      return;
    }

    final completer = Completer<void>();
    _loadingCompleters[componentName] = completer;

    try {
      await loadLibrary();
      _loadedComponents.add(componentName);
      completer.complete();
    } catch (e) {
      completer.completeError(e);
      _loadingCompleters.remove(componentName);
      rethrow;
    } finally {
      _loadingCompleters.remove(componentName);
    }
  }

  /// 智能预加载策略
  /// 根据用户行为模式预加载可能需要的组件
  void smartPreload({
    required String currentRoute,
    required bool isLoggedIn,
  }) {
    if (!isLoggedIn) return;

    // 根据当前路由预测用户可能访问的页面
    switch (currentRoute) {
      case '/home':
        // 在首页时，用户很可能会访问商店或个人资料
        unawaited(_preloadComponent('shop', shop_deferred.loadLibrary));
        unawaited(_preloadComponent('profile', profile_deferred.loadLibrary));
        break;
      case '/shop':
        // 在商店页面时，用户可能会查看个人资料或规则
        unawaited(_preloadComponent('profile', profile_deferred.loadLibrary));
        unawaited(_preloadComponent('rules', rules_deferred.loadLibrary));
        break;
      case '/profile':
        // 在个人资料页面时，用户可能会访问设置
        unawaited(_preloadComponent('settings', settings_deferred.loadLibrary));
        break;
    }
  }

  /// 清理资源
  void dispose() {
    _loadedComponents.clear();
    _loadingCompleters.clear();
  }
}

/// 扩展方法，避免 unawaited 警告
extension _FutureExtensions on Future<void> {
  void get unawaited => this;
}
