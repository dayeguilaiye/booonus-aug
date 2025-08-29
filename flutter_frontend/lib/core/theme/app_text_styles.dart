import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  // 标题样式
  static const TextStyle title = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.onBackground,
  );
  
  static const TextStyle subtitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.onBackground,
  );
  
  // 正文样式
  static const TextStyle body = TextStyle(
    fontSize: 16,
    color: AppColors.onBackground,
    height: 1.5,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontSize: 14,
    color: AppColors.onSurfaceVariant,
  );
  
  // 按钮样式
  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );
  
  // 积分相关样式
  static const TextStyle points = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: AppColors.onPrimaryContainer,
  );
  
  static const TextStyle pointsLarge = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.onPrimaryContainer,
  );
  
  // 用户名样式
  static const TextStyle username = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.onPrimaryContainer,
  );
  
  static const TextStyle partnerName = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.onSecondaryContainer,
  );
  
  // 情侣相关样式
  static const TextStyle coupleTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.onSecondaryContainer,
  );
  
  // 历史记录样式
  static const TextStyle historyDescription = TextStyle(
    fontSize: 14,
    color: AppColors.onSurface,
  );
  
  static const TextStyle historyDate = TextStyle(
    fontSize: 12,
    color: AppColors.onSurfaceVariant,
  );
  
  // 错误和成功消息样式
  static const TextStyle error = TextStyle(
    fontSize: 14,
    color: AppColors.error,
    fontWeight: FontWeight.w500,
  );
  
  static const TextStyle success = TextStyle(
    fontSize: 14,
    color: AppColors.onSuccess,
  );
  
  static const TextStyle warning = TextStyle(
    fontSize: 14,
    color: AppColors.onWarning,
  );
  
  // 卡片标题样式
  static const TextStyle cardTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.onSurface,
  );
  
  // 价格样式
  static const TextStyle price = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: AppColors.coin,
  );
  
  // 描述样式
  static const TextStyle description = TextStyle(
    fontSize: 14,
    color: AppColors.onSurfaceVariant,
    height: 1.4,
  );
}
