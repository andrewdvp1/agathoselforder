import 'dart:typed_data';
import 'package:image/image.dart' as img;

class CompressedImageResult {
  final Uint8List bytes;
  final String extension;
  final String contentType;

  const CompressedImageResult({
    required this.bytes,
    required this.extension,
    required this.contentType,
  });
}

/// Cross-platform (Android & Web) image compression & validation (max 2 MB, JPG/PNG/WebP).
class ImageCompressor {
  static const int maxBytes = 2 * 1024 * 1024; // 2 MB
  static const int maxDimension = 1200;

  static CompressedImageResult compressForMenuUpload(
    Uint8List originalBytes,
    String fileName,
  ) {
    final lower = fileName.toLowerCase();
    final isAllowed = lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp');
    if (!isAllowed) {
      throw Exception('Format gambar harus JPG, PNG, atau WebP.');
    }

    final decoded = img.decodeImage(originalBytes);
    if (decoded == null) {
      if (originalBytes.length <= maxBytes) {
        final ext = lower.endsWith('.png')
            ? 'png'
            : (lower.endsWith('.webp') ? 'webp' : 'jpg');
        final mime = ext == 'png'
            ? 'image/png'
            : (ext == 'webp' ? 'image/webp' : 'image/jpeg');
        return CompressedImageResult(
          bytes: originalBytes,
          extension: ext,
          contentType: mime,
        );
      }
      throw Exception('Gambar tidak dapat dibaca atau melebihi batas 2 MB.');
    }

    img.Image working = decoded;
    if (working.width > maxDimension || working.height > maxDimension) {
      working = img.copyResize(
        working,
        width: working.width >= working.height ? maxDimension : null,
        height: working.height > working.width ? maxDimension : null,
        interpolation: img.Interpolation.linear,
      );
    }

    // Encode to JPEG with adaptive quality until <= 2 MB
    int quality = 85;
    Uint8List encoded = Uint8List.fromList(img.encodeJpg(working, quality: quality));
    while (encoded.length > maxBytes && quality > 40) {
      quality -= 15;
      encoded = Uint8List.fromList(img.encodeJpg(working, quality: quality));
    }

    if (encoded.length > maxBytes) {
      throw Exception('Ukuran gambar masih melebihi 2 MB setelah kompresi.');
    }

    return CompressedImageResult(
      bytes: encoded,
      extension: 'jpg',
      contentType: 'image/jpeg',
    );
  }
}
