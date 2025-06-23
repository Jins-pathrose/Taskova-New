import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

class ImageCompressor {
  static Future<File?> compressImage(File image, String targetPath, {int targetSizeKB = 20}) async {
    try {
      if (!await image.exists()) {
        print('Source image does not exist: ${image.path}');
        return null;
      }

      // Initial compression parameters
      int quality = 85;
      int minWidth = 800;
      int minHeight = 600;
      File? compressedFile = image;

      // Get initial file size
      int fileSizeKB = (await image.length()) ~/ 1024;
      print('Original image size: $fileSizeKB KB');

      // If already under target size, return original
      if (fileSizeKB <= targetSizeKB) {
        return image;
      }

      // Iteratively compress until size is close to target
      while (fileSizeKB > targetSizeKB && quality > 10) {
        final tempDir = await getTemporaryDirectory();
        final compressedPath = '${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';

        final xfile = await FlutterImageCompress.compressAndGetFile(
          image.path,
          compressedPath,
          quality: quality,
          minWidth: minWidth,
          minHeight: minHeight,
          format: CompressFormat.jpeg,
        );
        compressedFile = xfile != null ? File(xfile.path) : null;

        if (compressedFile == null) {
          print('Compression failed for ${image.path}');
          return null;
        }

        fileSizeKB = (await compressedFile.length()) ~/ 1024;
        print('Compressed image size: $fileSizeKB KB (quality: $quality, minWidth: $minWidth, minHeight: $minHeight)');

        // Adjust parameters for next iteration if needed
        if (fileSizeKB > targetSizeKB) {
          quality -= 10;
          minWidth = (minWidth * 0.9).round();
          minHeight = (minHeight * 0.9).round();
        }
      }

      // Verify final file
      if (compressedFile != null && await compressedFile.exists()) {
        print('Final compressed image saved at: ${compressedFile.path}');
        return compressedFile;
      } else {
        print('Compressed file does not exist');
        return null;
      }
    } catch (e) {
      print('Error compressing image: $e');
      return null;
    }
  }
}