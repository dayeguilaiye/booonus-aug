import 'package:flutter/material.dart';
import '../utils/platform_utils.dart';
import 'app_colors.dart';

class AppTheme {
  /// 获取平台特定的字体系列
  static String? get _platformFontFamily {
    return PlatformUtils.platformFontFamily;
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: _platformFontFamily,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        primaryContainer: AppColors.primaryContainer,
        onPrimary: AppColors.onPrimary,
        onPrimaryContainer: AppColors.onPrimaryContainer,
        secondary: AppColors.secondary,
        secondaryContainer: AppColors.secondaryContainer,
        onSecondary: AppColors.onSecondary,
        onSecondaryContainer: AppColors.onSecondaryContainer,
        tertiary: AppColors.tertiary,
        tertiaryContainer: AppColors.tertiaryContainer,
        onTertiary: AppColors.onTertiary,
        onTertiaryContainer: AppColors.onTertiaryContainer,
        background: AppColors.background,
        onBackground: AppColors.onBackground,
        surface: AppColors.surface,
        onSurface: AppColors.onSurface,
        surfaceVariant: AppColors.surfaceVariant,
        onSurfaceVariant: AppColors.onSurfaceVariant,
        outline: AppColors.outline,
        outlineVariant: AppColors.outlineVariant,
        error: AppColors.error,
        onError: AppColors.onError,
        errorContainer: AppColors.errorContainer,
        onErrorContainer: AppColors.onErrorContainer,
      ),
      
      // App Bar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppColors.onPrimary,
        ),
      ),
      
      // Card Theme
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        shadowColor: AppColors.outline,
      ),
      
      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        ),
      ),
      
      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      ),
      
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      
      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      
      // Floating Action Button Theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
      ),
      
      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceVariant,
        labelStyle: const TextStyle(color: AppColors.onSurfaceVariant),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      
      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: AppColors.outline,
        thickness: 1,
      ),

      // Text Theme - 优化跨平台文本渲染
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontFamily: _platformFontFamily,
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: AppColors.onBackground,
        ),
        displayMedium: TextStyle(
          fontFamily: _platformFontFamily,
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: AppColors.onBackground,
        ),
        displaySmall: TextStyle(
          fontFamily: _platformFontFamily,
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppColors.onBackground,
        ),
        headlineLarge: TextStyle(
          fontFamily: _platformFontFamily,
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: AppColors.onBackground,
        ),
        headlineMedium: TextStyle(
          fontFamily: _platformFontFamily,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.onBackground,
        ),
        headlineSmall: TextStyle(
          fontFamily: _platformFontFamily,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.onBackground,
        ),
        titleLarge: TextStyle(
          fontFamily: _platformFontFamily,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.onBackground,
        ),
        titleMedium: TextStyle(
          fontFamily: _platformFontFamily,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.onBackground,
        ),
        titleSmall: TextStyle(
          fontFamily: _platformFontFamily,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.onSurfaceVariant,
        ),
        bodyLarge: TextStyle(
          fontFamily: _platformFontFamily,
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: AppColors.onBackground,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontFamily: _platformFontFamily,
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: AppColors.onBackground,
          height: 1.4,
        ),
        bodySmall: TextStyle(
          fontFamily: _platformFontFamily,
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: AppColors.onSurfaceVariant,
          height: 1.3,
        ),
        labelLarge: TextStyle(
          fontFamily: _platformFontFamily,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.onBackground,
        ),
        labelMedium: TextStyle(
          fontFamily: _platformFontFamily,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.onSurfaceVariant,
        ),
        labelSmall: TextStyle(
          fontFamily: _platformFontFamily,
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: AppColors.onSurfaceVariant,
        ),
      ),
    );
  }
}
