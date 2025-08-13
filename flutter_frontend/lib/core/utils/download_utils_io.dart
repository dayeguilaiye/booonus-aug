import 'dart:typed_data';
import 'package:saver_gallery/saver_gallery.dart';

/// IO implementation for download utilities (mobile and desktop platforms)
class DownloadUtilsImpl {
  static Future<void> downloadImage(
    Uint8List imageBytes, 
    String fileName, {
    String? androidRelativePath,
  }) async {
    await SaverGallery.saveImage(
      imageBytes,
      quality: 100,
      fileName: fileName,
      androidRelativePath: androidRelativePath ?? 'Pictures/小小卖部',
      skipIfExists: false,
    );
  }

  static bool get isDownloadSupported => true;
}
