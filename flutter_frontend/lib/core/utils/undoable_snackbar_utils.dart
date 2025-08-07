import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/points_api_service.dart';
import '../models/points_history.dart';
import 'error_message_utils.dart';

class UndoableSnackbarUtils {
  // 用于存储定时器，确保在无障碍模式下也能自动消失
  static Timer? _autoHideTimer;

  /// 显示带撤销功能的成功提醒
  ///
  /// [context] - BuildContext
  /// [message] - 成功消息
  /// [onRefresh] - 撤销成功后的刷新回调
  /// [targetUserId] - 目标用户ID，用于查询积分历史
  /// [duration] - SnackBar 显示时长，默认5秒
  static Future<void> showUndoableSuccess(
    BuildContext context,
    String message, {
    VoidCallback? onRefresh,
    int? targetUserId,
    Duration duration = const Duration(seconds: 5),
  }) async {
    // 检查 context 是否仍然有效
    if (!context.mounted) return;

    try {
      // 获取最新的积分历史记录
      final latestHistory = await _getLatestUndoableHistory(targetUserId);

      // 再次检查 context 是否仍然有效
      if (!context.mounted) return;

      if (latestHistory == null) {
        // 如果没有找到可撤销的记录，显示普通的成功提醒
        _showSimpleSuccess(context, message);
        return;
      }

      // 显示带撤销功能的 SnackBar
      _showUndoableSnackBar(
        context,
        message,
        latestHistory,
        onRefresh,
        duration,
      );
    } catch (e) {
      // 如果获取历史记录失败，显示普通的成功提醒
      if (context.mounted) {
        _showSimpleSuccess(context, message);
      }
    }
  }

  /// 显示带撤销功能的 SnackBar，支持在无障碍模式下自动消失
  static void _showUndoableSnackBar(
    BuildContext context,
    String message,
    PointsHistory latestHistory,
    VoidCallback? onRefresh,
    Duration duration,
  ) {
    // 取消之前的定时器
    _autoHideTimer?.cancel();

    // 显示 SnackBar
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle,
              color: AppColors.onSuccess,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: AppColors.onSuccess,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        // 设置一个很长的 duration，我们会用定时器手动控制
        duration: const Duration(days: 1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        action: SnackBarAction(
          label: '撤销',
          textColor: AppColors.onSuccess,
          onPressed: () {
            // 取消自动隐藏定时器
            _autoHideTimer?.cancel();
            _handleUndo(context, latestHistory, onRefresh);
          },
        ),
      ),
    );

    // 设置定时器，在指定时间后自动隐藏 SnackBar
    _autoHideTimer = Timer(duration, () {
      if (context.mounted) {
        scaffoldMessenger.hideCurrentSnackBar();
      }
    });
  }

  /// 获取最新的可撤销积分历史记录
  static Future<PointsHistory?> _getLatestUndoableHistory(int? targetUserId) async {
    try {
      final response = targetUserId != null
          ? await PointsApiService.getUserHistory(targetUserId, limit: 10)
          : await PointsApiService.getHistory(limit: 10);
      
      final historyList = response['history'] as List<dynamic>?;
      if (historyList == null || historyList.isEmpty) {
        return null;
      }

      // 查找最新的可撤销记录
      for (final historyJson in historyList) {
        final history = PointsHistory.fromJson(historyJson);
        if (history.canRevert && !history.isReverted) {
          return history;
        }
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  /// 处理撤销操作
  static Future<void> _handleUndo(
    BuildContext context,
    PointsHistory history,
    VoidCallback? onRefresh,
  ) async {
    // 检查 context 是否仍然有效
    if (!context.mounted) return;

    try {
      // 显示加载提示
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 8),
              Text('正在撤销...'),
            ],
          ),
          backgroundColor: AppColors.primary,
          duration: Duration(seconds: 2),
        ),
      );

      // 调用撤销 API
      await PointsApiService.revert(history.id);

      // 检查 context 是否仍然有效
      if (!context.mounted) return;

      // 隐藏加载提示
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      // 显示撤销成功提示
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(
                Icons.undo,
                color: AppColors.onPrimary,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                '撤销成功',
                style: TextStyle(color: AppColors.onPrimary),
              ),
            ],
          ),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );

      // 调用刷新回调
      onRefresh?.call();
    } catch (e) {
      // 检查 context 是否仍然有效
      if (!context.mounted) return;

      // 隐藏加载提示
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      // 显示撤销失败提示
      final errorMessage = ErrorMessageUtils.getUndoErrorMessage(e);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.error,
                color: AppColors.onError,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '撤销失败: $errorMessage',
                  style: const TextStyle(color: AppColors.onError),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// 显示普通的成功提醒（无撤销功能）
  static void _showSimpleSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle,
              color: AppColors.onSuccess,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: AppColors.onSuccess),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
