import 'dart:typed_data';
import 'download_utils_stub.dart'
    if (dart.library.html) 'download_utils_web.dart'
    if (dart.library.io) 'download_utils_io.dart';

/// Download utility class that works across all platforms
class DownloadUtils {
  /// Download image bytes as a file
  /// On web: triggers browser download
  /// On mobile: saves to gallery using saver_gallery
  static Future<void> downloadImage(
    Uint8List imageBytes, 
    String fileName, {
    String? androidRelativePath,
  }) async {
    return DownloadUtilsImpl.downloadImage(
      imageBytes, 
      fileName, 
      androidRelativePath: androidRelativePath,
    );
  }

  /// Check if download is supported on current platform
  static bool get isDownloadSupported => DownloadUtilsImpl.isDownloadSupported;
}
