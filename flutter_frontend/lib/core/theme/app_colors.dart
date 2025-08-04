import 'package:flutter/material.dart';

/// 温暖可爱配色方案 - 基于原React项目的设计系统
class AppColors {
  // 主色调 - 温暖桃粉色 (HSL: 15 85% 70%)
  static const Color primary = Color(0xFFFF9B73);           // 温暖桃粉色
  static const Color primaryContainer = Color(0xFFFFF4F1);  // 非常浅的桃色
  static const Color onPrimary = Color(0xFFFFFFFF);         // 白色文字
  static const Color onPrimaryContainer = Color(0xFF5C2E1F); // 深棕色文字

  // 次要色调 - 柔和桃色 (HSL: 25 60% 92%)
  static const Color secondary = Color(0xFFFAF0E8);         // 柔和桃色
  static const Color secondaryContainer = Color(0xFFFDF8F4); // 更浅的桃色
  static const Color onSecondary = Color(0xFF5C2E1F);       // 深棕色文字
  static const Color onSecondaryContainer = Color(0xFF5C2E1F);

  // 强调色 - 薄荷绿 (HSL: 140 40% 75%)
  static const Color accent = Color(0xFF9DCCAA);            // 薄荷绿
  static const Color accentContainer = Color(0xFFE8F5EC);   // 浅薄荷绿
  static const Color onAccent = Color(0xFF5C2E1F);          // 深棕色文字
  static const Color onAccentContainer = Color(0xFF5C2E1F);

  // 背景色 (HSL: 30 25% 98%)
  static const Color background = Color(0xFFFCFBFA);        // 温暖的白色
  static const Color onBackground = Color(0xFF5C2E1F);      // 深棕色文字
  static const Color surface = Color(0xFFFFFFFF);           // 纯白色
  static const Color onSurface = Color(0xFF5C2E1F);
  static const Color surfaceVariant = Color(0xFFF7F3F0);    // 浅桃色变体
  static const Color onSurfaceVariant = Color(0xFF8B6B5C);  // 中等棕色

  // 第三色调 - 使用accent作为tertiary
  static const Color tertiary = Color(0xFF9DCCAA);          // 薄荷绿
  static const Color tertiaryContainer = Color(0xFFE8F5EC); // 浅薄荷绿
  static const Color onTertiary = Color(0xFF5C2E1F);        // 深棕色文字
  static const Color onTertiaryContainer = Color(0xFF5C2E1F);

  // 轮廓和分割线 (HSL: 25 30% 88%)
  static const Color outline = Color(0xFFE8DDD6);           // 温暖的边框色
  static const Color outlineVariant = Color(0xFFF2EBE6);
  static const Color input = Color(0xFFE8DDD6);             // 输入框边框

  // 禁用/空状态颜色
  static const Color disabled = Color(0xFFF5F5F5);          // 禁用背景色
  static const Color disabledContainer = Color(0xFFE0E0E0); // 禁用容器色
  static const Color onDisabled = Color(0xFF999999);        // 禁用文字色

  // 错误色 - 柔和珊瑚色 (HSL: 0 70% 65%)
  static const Color error = Color(0xFFE57373);             // 柔和的红色
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFEBEE);
  static const Color onErrorContainer = Color(0xFF8B0000);

  // 成功色 - 使用薄荷绿
  static const Color success = Color(0xFF9DCCAA);           // 薄荷绿
  static const Color onSuccess = Color(0xFF5C2E1F);
  static const Color successContainer = Color(0xFFE8F5EC);
  static const Color onSuccessContainer = Color(0xFF5C2E1F);

  // 警告色 - 温暖桃色
  static const Color warning = Color(0xFFFFB366);           // 温暖橙色
  static const Color onWarning = Color(0xFFFFFFFF);
  static const Color warningContainer = Color(0xFFFFF4F1);
  static const Color onWarningContainer = Color(0xFF5C2E1F);

  // 特殊色彩 - 基于新配色方案
  static const Color heart = Color(0xFFFF9B73);             // 温暖桃粉色
  static const Color star = Color(0xFFFFD54F);              // 温暖金色
  static const Color coin = Color(0xFFFF9B73);              // 温暖桃色

  // 自定义设计令牌
  static const Color primaryGlow = Color(0xFFFFB899);       // 主色发光效果
  static const Color secondaryGlow = Color(0xFFFDF8F4);     // 次要色发光效果
  static const Color mintLight = Color(0xFFD4E8DC);         // 浅薄荷色

  // 渐变色
  static const LinearGradient warmGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFAF0E8), Color(0xFFF7E6D9)],
  );

  // 阴影色
  static const Color cuteShadow = Color(0x40FF9B73);        // 可爱阴影
  static const Color gentleShadow = Color(0x145C2E1F);      // 温和阴影

  // 透明度变体
  static Color primaryWithOpacity(double opacity) => primary.withValues(alpha: opacity);
  static Color secondaryWithOpacity(double opacity) => secondary.withValues(alpha: opacity);
  static Color accentWithOpacity(double opacity) => accent.withValues(alpha: opacity);
  static Color successWithOpacity(double opacity) => success.withValues(alpha: opacity);
  static Color errorWithOpacity(double opacity) => error.withValues(alpha: opacity);
  static Color warningWithOpacity(double opacity) => warning.withValues(alpha: opacity);
}
