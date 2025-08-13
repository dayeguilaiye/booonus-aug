import 'platform_utils_stub.dart'
    if (dart.library.io) 'platform_utils_io.dart'
    if (dart.library.html) 'platform_utils_web.dart';

/// Platform utility class that works across all platforms including web
class PlatformUtils {
  /// Check if the current platform is iOS
  static bool get isIOS => PlatformUtilsImpl.isIOS;

  /// Check if the current platform is Android
  static bool get isAndroid => PlatformUtilsImpl.isAndroid;

  /// Check if the current platform is Web
  static bool get isWeb => PlatformUtilsImpl.isWeb;

  /// Check if the current platform is Desktop (Windows, macOS, Linux)
  static bool get isDesktop => PlatformUtilsImpl.isDesktop;

  /// Check if the current platform is Windows
  static bool get isWindows => PlatformUtilsImpl.isWindows;

  /// Check if the current platform is macOS
  static bool get isMacOS => PlatformUtilsImpl.isMacOS;

  /// Check if the current platform is Linux
  static bool get isLinux => PlatformUtilsImpl.isLinux;

  /// Check if the current platform is Mobile (iOS or Android)
  static bool get isMobile => isIOS || isAndroid;

  /// Get platform-specific font family
  static String? get platformFontFamily {
    if (isIOS) {
      // iOS 使用系统默认字体，避免字体加载问题
      return null;
    } else if (isAndroid) {
      return 'Roboto';
    }
    return null; // Web and desktop use default fonts
  }

  /// Get platform name as string
  static String get platformName {
    if (isIOS) return 'iOS';
    if (isAndroid) return 'Android';
    if (isWeb) return 'Web';
    if (isWindows) return 'Windows';
    if (isMacOS) return 'macOS';
    if (isLinux) return 'Linux';
    return 'Unknown';
  }
}
