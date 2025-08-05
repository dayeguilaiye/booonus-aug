import 'package:flutter/material.dart';

import '../../../core/models/points_history.dart';
import '../../../core/services/points_api_service.dart';
import '../../../core/theme/app_colors.dart';

class PointsHistoryScreen extends StatefulWidget {
  final bool isMyHistory; // true表示我的积分记录，false表示对方的积分记录
  final int? targetUserId; // 当查看对方记录时需要传入对方的用户ID

  const PointsHistoryScreen({
    super.key,
    required this.isMyHistory,
    this.targetUserId,
  });

  @override
  State<PointsHistoryScreen> createState() => _PointsHistoryScreenState();
}

class _PointsHistoryScreenState extends State<PointsHistoryScreen> {
  List<PointsHistory> _history = [];
  bool _isLoading = true;
  String _error = '';
  int _total = 0;
  int _currentOffset = 0;
  final int _limit = 20;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && _hasMore) {
        _loadMoreHistory();
      }
    }
  }

  Future<void> _loadHistory() async {
    try {
      setState(() {
        _isLoading = true;
        _error = '';
        _currentOffset = 0;
      });

      Map<String, dynamic> response;

      // 根据是否查看自己的记录选择不同的API
      if (widget.isMyHistory) {
        print('PointsHistoryScreen: 加载我的积分记录');
        response = await PointsApiService.getHistory(
          limit: _limit,
          offset: 0,
        );
      } else {
        // 查看对方的记录
        if (widget.targetUserId == null) {
          throw Exception('缺少目标用户ID');
        }
        print('PointsHistoryScreen: 加载对方的积分记录，targetUserId: ${widget.targetUserId}');
        response = await PointsApiService.getUserHistory(
          widget.targetUserId!,
          limit: _limit,
          offset: 0,
        );
      }

      final historyData = response['history'] as List<dynamic>? ?? [];
      final history = historyData.map((item) => PointsHistory.fromJson(item)).toList();

      setState(() {
        _history = history;
        _total = response['total'] ?? 0;
        _currentOffset = _limit;
        _hasMore = history.length >= _limit;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreHistory() async {
    try {
      setState(() {
        _isLoading = true;
      });

      Map<String, dynamic> response;

      // 根据是否查看自己的记录选择不同的API
      if (widget.isMyHistory) {
        response = await PointsApiService.getHistory(
          limit: _limit,
          offset: _currentOffset,
        );
      } else {
        // 查看对方的记录
        if (widget.targetUserId == null) {
          throw Exception('缺少目标用户ID');
        }
        response = await PointsApiService.getUserHistory(
          widget.targetUserId!,
          limit: _limit,
          offset: _currentOffset,
        );
      }

      final historyData = response['history'] as List<dynamic>? ?? [];
      final newHistory = historyData.map((item) => PointsHistory.fromJson(item)).toList();

      setState(() {
        _history.addAll(newHistory);
        _currentOffset += _limit;
        _hasMore = newHistory.length >= _limit;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('加载更多记录失败: ${e.toString().replaceFirst('Exception: ', '')}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading && _history.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? _buildErrorState()
              : RefreshIndicator(
                  onRefresh: _loadHistory,
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTitle(),
                        const SizedBox(height: 24),
                        _buildHistorySection(),
                        if (_isLoading && _history.isNotEmpty)
                          const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                      ],
                    ),
                  ),
                ),
    );
  }

  // 构建错误状态
  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            const Text(
              '加载失败',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.onBackground,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadHistory,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
              ),
              child: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }

  // 处理返回按钮点击
  void _handleBackPress(BuildContext context) {
    Navigator.of(context).pop();
  }

  // 构建标题
  Widget _buildTitle() {
    return Row(
      children: [
        // 返回按钮
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: AppColors.gentleShadow,
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            onPressed: () => _handleBackPress(context),
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: AppColors.onSurface,
              size: 20,
            ),
            tooltip: '返回',
            style: IconButton.styleFrom(
              padding: const EdgeInsets.all(12),
              minimumSize: const Size(44, 44),
            ),
          ),
        ),
        const SizedBox(width: 16),
        // 标题
        Expanded(
          child: Text(
            widget.isMyHistory ? '我的积分记录' : '对方的积分记录',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.onBackground,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(width: 60), // 平衡右侧空间
      ],
    );
  }

  // 构建积分历史部分
  Widget _buildHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '积分变化记录 (${_history.length}/$_total)',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.onBackground,
          ),
        ),
        const SizedBox(height: 16),
        _history.isEmpty
            ? _buildEmptyHistoryState()
            : Column(
                children: _history.map((history) => _buildHistoryCard(history)).toList(),
              ),
      ],
    );
  }

  // 构建空历史状态
  Widget _buildEmptyHistoryState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(40),
            ),
            child: const Icon(
              Icons.history,
              size: 40,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '暂无积分记录',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.onBackground,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.isMyHistory ? '您还没有积分变化记录' : '对方还没有积分变化记录',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // 构建历史记录卡片
  Widget _buildHistoryCard(PointsHistory history) {
    final isPositive = history.points > 0;
    final pointsColor = isPositive ? AppColors.accent : AppColors.error;
    final pointsText = isPositive ? '+${history.points}' : '${history.points}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: AppColors.gentleShadow,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 积分变化图标
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: pointsColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              isPositive ? Icons.add_circle : Icons.remove_circle,
              color: pointsColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          // 描述和时间
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  history.description,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onBackground,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDateTime(history.createdAt),
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          // 积分变化
          Text(
            pointsText,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: pointsColor,
            ),
          ),
        ],
      ),
    );
  }

  // 格式化日期时间
  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      // 今天
      return '今天 ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      // 昨天
      return '昨天 ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      // 一周内
      final weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
      final weekday = weekdays[dateTime.weekday - 1];
      return '$weekday ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      // 超过一周
      return '${dateTime.month}月${dateTime.day}日 ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }
}
