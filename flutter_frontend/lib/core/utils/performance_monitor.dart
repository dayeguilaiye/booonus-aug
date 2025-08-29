// 性能监控工具 - 跟踪延迟加载的性能指标
import 'dart:async';
import 'dart:developer' as developer;

/// 性能监控器
/// 用于跟踪延迟加载组件的性能指标
class PerformanceMonitor {
  static final PerformanceMonitor _instance = PerformanceMonitor._internal();
  factory PerformanceMonitor() => _instance;
  PerformanceMonitor._internal();

  final Map<String, DateTime> _loadStartTimes = {};
  final Map<String, Duration> _loadDurations = {};
  final Map<String, int> _loadCounts = {};

  /// 开始跟踪组件加载
  void startTracking(String componentName) {
    _loadStartTimes[componentName] = DateTime.now();
    _loadCounts[componentName] = (_loadCounts[componentName] ?? 0) + 1;
    
    developer.log(
      'Started loading component: $componentName',
      name: 'PerformanceMonitor',
    );
  }

  /// 结束跟踪组件加载
  void endTracking(String componentName) {
    final startTime = _loadStartTimes[componentName];
    if (startTime != null) {
      final duration = DateTime.now().difference(startTime);
      _loadDurations[componentName] = duration;
      _loadStartTimes.remove(componentName);
      
      developer.log(
        'Finished loading component: $componentName in ${duration.inMilliseconds}ms',
        name: 'PerformanceMonitor',
      );
    }
  }

  /// 获取组件加载时长
  Duration? getLoadDuration(String componentName) {
    return _loadDurations[componentName];
  }

  /// 获取组件加载次数
  int getLoadCount(String componentName) {
    return _loadCounts[componentName] ?? 0;
  }

  /// 获取所有性能指标
  Map<String, Map<String, dynamic>> getAllMetrics() {
    final metrics = <String, Map<String, dynamic>>{};
    
    for (final componentName in _loadDurations.keys) {
      metrics[componentName] = {
        'loadDuration': _loadDurations[componentName]?.inMilliseconds,
        'loadCount': _loadCounts[componentName] ?? 0,
      };
    }
    
    return metrics;
  }

  /// 打印性能报告
  void printPerformanceReport() {
    developer.log('=== Deferred Loading Performance Report ===', name: 'PerformanceMonitor');
    
    final metrics = getAllMetrics();
    if (metrics.isEmpty) {
      developer.log('No performance data available', name: 'PerformanceMonitor');
      return;
    }
    
    for (final entry in metrics.entries) {
      final componentName = entry.key;
      final data = entry.value;
      developer.log(
        '$componentName: ${data['loadDuration']}ms (loaded ${data['loadCount']} times)',
        name: 'PerformanceMonitor',
      );
    }
    
    developer.log('=== End Performance Report ===', name: 'PerformanceMonitor');
  }

  /// 清理数据
  void clear() {
    _loadStartTimes.clear();
    _loadDurations.clear();
    _loadCounts.clear();
  }
}

/// 性能监控装饰器
/// 用于包装延迟加载函数，自动跟踪性能
class PerformanceTracker {
  static Future<T> track<T>(
    String componentName,
    Future<T> Function() operation,
  ) async {
    final monitor = PerformanceMonitor();
    
    monitor.startTracking(componentName);
    try {
      final result = await operation();
      monitor.endTracking(componentName);
      return result;
    } catch (e) {
      monitor.endTracking(componentName);
      rethrow;
    }
  }
}
