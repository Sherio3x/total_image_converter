import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

enum ImageFormat { jpg, png, webp, gif, bmp }

class ImageConverter {
  static const Map<ImageFormat, String> formatExtensions = {
    ImageFormat.jpg: 'jpg',
    ImageFormat.png: 'png',
    ImageFormat.webp: 'webp',
    ImageFormat.gif: 'gif',
    ImageFormat.bmp: 'bmp',
  };

  static const Map<ImageFormat, String> formatNames = {
    ImageFormat.jpg: 'JPG',
    ImageFormat.png: 'PNG',
    ImageFormat.webp: 'WebP',
    ImageFormat.gif: 'GIF',
    ImageFormat.bmp: 'BMP',
  };

  // Convert single image
  static Future<String?> convertSingleImage({
    required File sourceFile,
    required ImageFormat targetFormat,
    double quality = 0.9,
  }) async {
    try {
      final bytes = await sourceFile.readAsBytes();
      final originalImage = img.decodeImage(bytes);

      if (originalImage == null) {
        print("Error: Could not decode image from bytes.");
        throw Exception("فشل في قراءة الصورة أو أنها غير صالحة.");
      }

      final convertedBytes = _encodeImage(originalImage, targetFormat, quality);
      if (convertedBytes == null) {
        print("Error: Failed to encode image to target format.");
        throw Exception("فشل في تحويل الصورة إلى الصيغة المطلوبة.");
      }

      final savedPath = await _saveImage(convertedBytes, targetFormat);
      return savedPath;
    } catch (e) {
      throw Exception('خطأ في تحويل الصورة: $e');
    }
  }

  // Convert multiple images (batch conversion)
  static Future<List<String>> convertMultipleImages({
    required List<File> sourceFiles,
    required ImageFormat targetFormat,
    double quality = 0.9,
    Function(int current, int total)? onProgress,
  }) async {
    final List<String> convertedPaths = [];
    
    for (int i = 0; i < sourceFiles.length; i++) {
      try {
        onProgress?.call(i + 1, sourceFiles.length);
        
        final convertedPath = await convertSingleImage(
          sourceFile: sourceFiles[i],
          targetFormat: targetFormat,
          quality: quality,
        );
        
        if (convertedPath != null) {
          convertedPaths.add(convertedPath);
        }
      } catch (e) {
        // Continue with other images even if one fails
        continue;
      }
    }
    
    return convertedPaths;
  }

  // Encode image to specific format
  static Uint8List? _encodeImage(img.Image image, ImageFormat format, double quality) {
    switch (format) {
      case ImageFormat.jpg:
        return Uint8List.fromList(
          img.encodeJpg(image, quality: (quality * 100).round())
        );
      case ImageFormat.png:
        return Uint8List.fromList(img.encodePng(image));
      case ImageFormat.webp:
        // WebP encoding is not fully supported in the image package
        // We'll convert to PNG with high quality as a fallback
        return Uint8List.fromList(img.encodePng(image));
      case ImageFormat.gif:
        return Uint8List.fromList(img.encodeGif(image));
      case ImageFormat.bmp:
        return Uint8List.fromList(img.encodeBmp(image));
      default:
        return null;
    }
  }

  // Save image to device storage
  static Future<String> _saveImage(Uint8List imageBytes, ImageFormat format) async {
    final directory = (await getExternalStorageDirectory())!; // Use external storage for user access
    final outputDir = Directory("${directory.path}/TotalImageConverter");
    if (!await outputDir.exists()) {
      await outputDir.create(recursive: true);
    }
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    String extension = formatExtensions[format]!;
    // Use PNG extension for WebP since we\"re converting to PNG as fallback
    if (format == ImageFormat.webp) {
      extension = "png";
    }
    final fileName = "converted_image_$timestamp.$extension";
    final filePath = "${outputDir.path}/$fileName";
    
    final file = File(filePath);
    await file.writeAsBytes(imageBytes);
    
    return filePath;
  }

  // Get supported input formats
  static List<String> getSupportedInputFormats() {
    return ['JPG', 'JPEG', 'PNG', 'WebP', 'GIF', 'BMP', 'TIFF'];
  }

  // Get supported output formats
  static List<ImageFormat> getSupportedOutputFormats() {
    return ImageFormat.values;
  }

  // Check if format supports quality adjustment
  static bool supportsQuality(ImageFormat format) {
    return format == ImageFormat.jpg || format == ImageFormat.webp;
  }

  // Get format from string
  static ImageFormat? getFormatFromString(String formatString) {
    switch (formatString.toUpperCase()) {
      case 'JPG':
      case 'JPEG':
        return ImageFormat.jpg;
      case 'PNG':
        return ImageFormat.png;
      case 'WEBP':
        return ImageFormat.webp;
      case 'GIF':
        return ImageFormat.gif;
      case 'BMP':
        return ImageFormat.bmp;
      default:
        return null;
    }
  }
}

