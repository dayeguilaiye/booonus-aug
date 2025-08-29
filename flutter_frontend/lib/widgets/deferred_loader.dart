// 延迟加载的通用加载器组件
import 'package:flutter/material.dart';
import '../core/utils/performance_monitor.dart';

/// 延迟加载组件的通用包装器
class DeferredLoader extends StatefulWidget {
  final Future<void> Function() loadLibrary;
  final Widget Function() builder;
  final Widget? loadingWidget;
  final Widget Function(Object error)? errorBuilder;
  final String? componentName;

  const DeferredLoader({
    super.key,
    required this.loadLibrary,
    required this.builder,
    this.loadingWidget,
    this.errorBuilder,
    this.componentName,
  });

  @override
  State<DeferredLoader> createState() => _DeferredLoaderState();
}

class _DeferredLoaderState extends State<DeferredLoader> {
  late Future<void> _loadingFuture;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadingFuture = _loadLibrary();
  }

  Future<void> _loadLibrary() async {
    try {
      // 使用性能监控跟踪加载时间
      await PerformanceTracker.track(
        widget.componentName ?? 'unknown',
        () => widget.loadLibrary(),
      );

      if (mounted) {
        setState(() {
          _isLoaded = true;
        });
      }
    } catch (e) {
      // 错误会在 FutureBuilder 中处理
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _loadingFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            if (widget.errorBuilder != null) {
              return widget.errorBuilder!(snapshot.error!);
            }
            return _buildDefaultError(snapshot.error!);
          }
          
          if (_isLoaded) {
            return widget.builder();
          }
        }

        return widget.loadingWidget ?? _buildDefaultLoading();
      },
    );
  }

  Widget _buildDefaultLoading() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6B9D)),
            ),
            const SizedBox(height: 16),
            Text(
              widget.componentName != null 
                ? '正在加载${widget.componentName}...' 
                : '正在加载...',
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF5D4E75),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultError(Object error) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            const Text(
              '加载失败',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF5D4E75),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _loadingFuture = _loadLibrary();
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B9D),
                foregroundColor: Colors.white,
              ),
              child: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }
}
