import 'dart:typed_data';

Future<String> saveReportFile({
  required Uint8List bytes,
  required String fileName,
  required String mimeType,
}) {
  throw UnsupportedError('Platform tidak didukung untuk penyimpanan file.');
}
