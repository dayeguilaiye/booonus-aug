import 'dart:typed_data';

/// Stub implementation for download utilities
/// This should never be used as conditional imports should resolve to specific implementations
class DownloadUtilsImpl {
  static Future<void> downloadImage(
    Uint8List imageBytes, 
    String fileName, {
    String? androidRelativePath,
  }) async {
    throw UnsupportedError('Download not supported on this platform');
  }

  static bool get isDownloadSupported => false;
}
