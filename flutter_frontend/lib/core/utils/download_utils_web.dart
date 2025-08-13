import 'dart:typed_data';
import 'dart:convert';
import 'dart:html' as html;

/// Web implementation for download utilities
class DownloadUtilsImpl {
  static Future<void> downloadImage(
    Uint8List imageBytes, 
    String fileName, {
    String? androidRelativePath,
  }) async {
    // Convert image bytes to base64
    final base64String = base64Encode(imageBytes);
    final dataUrl = 'data:image/png;base64,$base64String';
    
    // Create download link
    final anchor = html.AnchorElement(href: dataUrl)
      ..setAttribute('download', fileName)
      ..style.display = 'none';
    
    // Add to DOM, click, and remove
    html.document.body?.children.add(anchor);
    anchor.click();
    html.document.body?.children.remove(anchor);
  }

  static bool get isDownloadSupported => true;
}
