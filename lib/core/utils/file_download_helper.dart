import 'dart:typed_data';
import 'file_download_helper_stub.dart'
    if (dart.library.html) 'file_download_helper_web.dart'
    if (dart.library.io) 'file_download_helper_native.dart';

class FileDownloadHelper {
  static Future<bool> downloadFile({
    required Uint8List bytes,
    required String fileName,
  }) =>
      downloadFileImpl(bytes: bytes, fileName: fileName);
}
