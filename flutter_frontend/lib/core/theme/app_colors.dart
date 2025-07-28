import 'package:flutter/material.dart';

/// 马卡龙配色方案 - 与 React Native 版本保持一致
class AppColors {
  // 主色调 - 粉色系
  static const Color primary = Color(0xFFFFB6C1);           // 浅粉色
  static const Color primaryContainer = Color(0xFFFFE4E1);  // 更浅的粉色
  static const Color onPrimary = Color(0xFF8B4B6B);         // 深粉色文字
  static const Color onPrimaryContainer = Color(0xFF8B4B6B);

  // 次要色调 - 薄荷绿
  static const Color secondary = Color(0xFF98FB98);         // 薄荷绿
  static const Color secondaryContainer = Color(0xFFF0FFF0); // 浅薄荷绿
  static const Color onSecondary = Color(0xFF2E8B57);       // 深绿色文字
  static const Color onSecondaryContainer = Color(0xFF2E8B57);

  // 第三色调 - 薰衣草紫
  static const Color tertiary = Color(0xFFDDA0DD);          // 薰衣草紫
  static const Color tertiaryContainer = Color(0xFFF8F0FF); // 浅紫色
  static const Color onTertiary = Color(0xFF663399);        // 深紫色文字
  static const Color onTertiaryContainer = Color(0xFF663399);

  // 背景色
  static const Color background = Color(0xFFFFFBF7);        // 温暖的白色
  static const Color onBackground = Color(0xFF5D4E75);      // 深紫灰色文字
  static const Color surface = Color(0xFFFFFFFF);           // 纯白色
  static const Color onSurface = Color(0xFF5D4E75);
  static const Color surfaceVariant = Color(0xFFF5F5DC);    // 米色
  static const Color onSurfaceVariant = Color(0xFF8B7D8B);

  // 轮廓和分割线
  static const Color outline = Color(0xFFE6E6FA);           // 淡紫色轮廓
  static const Color outlineVariant = Color(0xFFF0F8FF);

  // 错误色
  static const Color error = Color(0xFFFFB4AB);             // 柔和的红色
  static const Color onError = Color(0xFF8B0000);
  static const Color errorContainer = Color(0xFFFFEBEE);
  static const Color onErrorContainer = Color(0xFF8B0000);

  // 成功色（自定义）
  static const Color success = Color(0xFF90EE90);           // 浅绿色
  static const Color onSuccess = Color(0xFF006400);
  static const Color successContainer = Color(0xFFF0FFF0);
  static const Color onSuccessContainer = Color(0xFF006400);

  // 警告色（自定义）
  static const Color warning = Color(0xFFFFE4B5);           // 桃色
  static const Color onWarning = Color(0xFFFF8C00);
  static const Color warningContainer = Color(0xFFFFF8DC);
  static const Color onWarningContainer = Color(0xFFFF8C00);

  // 特殊色彩
  static const Color heart = Color(0xFFFF69B4);             // 热粉色
  static const Color star = Color(0xFFFFD700);              // 金色
  static const Color coin = Color(0xFFFFA500);              // 橙色

  // 透明度变体
  static Color primaryWithOpacity(double opacity) => primary.withOpacity(opacity);
  static Color secondaryWithOpacity(double opacity) => secondary.withOpacity(opacity);
  static Color successWithOpacity(double opacity) => success.withOpacity(opacity);
  static Color errorWithOpacity(double opacity) => error.withOpacity(opacity);
  static Color warningWithOpacity(double opacity) => warning.withOpacity(opacity);
}
