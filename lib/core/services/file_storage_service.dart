import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import '../database/tables/documents_table.dart';
import '../utils/file_download_helper.dart';

class PickedFileInfo {
  final String name;
  final String? path;
  final Uint8List? bytes;
  final int size;
  final DocumentType type;
  final String? dataUri;

  PickedFileInfo({
    required this.name,
    this.path,
    this.bytes,
    required this.size,
    required this.type,
    this.dataUri,
  });
}

class FileStorageService {
  static Future<PickedFileInfo?> pickDocumentFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'ppt', 'pptx'],
    );

    if (result.isEmpty) return null;

    final file = result.first;
    final path = file.path;
    final name = file.name;
    final size = file.lengthSync() ?? (await file.length()) ?? 0;
    final bytes = await file.readAsBytes();

    final ext = p.extension(name).toLowerCase();
    DocumentType docType = DocumentType.pdf;
    String mimeType = 'application/pdf';

    if (ext == '.pdf') {
      docType = DocumentType.pdf;
      mimeType = 'application/pdf';
    } else if (ext == '.doc' || ext == '.docx') {
      docType = DocumentType.word;
      mimeType = 'application/msword';
    } else if (ext == '.ppt' || ext == '.pptx') {
      docType = DocumentType.ppt;
      mimeType = 'application/vnd.ms-powerpoint';
    }

    String? dataUri;
    if (bytes.isNotEmpty) {
      dataUri = 'data:$mimeType;base64,${base64Encode(bytes)}';
    }

    return PickedFileInfo(
      name: name,
      path: path,
      bytes: bytes,
      size: size,
      type: docType,
      dataUri: dataUri,
    );
  }

  static Future<String?> copyFileToLocalStorage(
      String sourcePath, String fileName) async {
    if (kIsWeb) {
      return sourcePath;
    }

    try {
      final appDir = await getApplicationDocumentsDirectory();
      final targetFolder = Directory(p.join(appDir.path, 'studyhub_files'));
      if (!await targetFolder.exists()) {
        await targetFolder.create(recursive: true);
      }

      final safeName = '${DateTime.now().millisecondsSinceEpoch}_$fileName';
      final targetPath = p.join(targetFolder.path, safeName);
      final sourceFile = File(sourcePath);

      if (await sourceFile.exists()) {
        await sourceFile.copy(targetPath);
        return targetPath;
      }
    } catch (_) {}
    return sourcePath;
  }

  static Future<bool> openUrl(String url) async {
    final uri = Uri.tryParse(url.trim());
    if (uri == null) return false;
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      try {
        return await launchUrl(uri, mode: LaunchMode.platformDefault);
      } catch (_) {}
    }
    return false;
  }

  static Future<String?> exportFile({
    String? sourceFilePath,
    String? fileUrl,
    required String defaultFileName,
  }) async {
    try {
      Uint8List? bytes;

      // 1. Đọc từ đường dẫn tệp nội bộ (Android, Windows, iOS)
      if (sourceFilePath != null && !kIsWeb) {
        final source = File(sourceFilePath);
        if (await source.exists()) {
          bytes = await source.readAsBytes();
        }
      }

      // 2. Giải mã từ chuỗi Data URI Base64
      if (bytes == null && fileUrl != null && fileUrl.startsWith('data:')) {
        final commaIdx = fileUrl.indexOf(',');
        if (commaIdx != -1) {
          final base64Str = fileUrl.substring(commaIdx + 1);
          bytes = base64Decode(base64Str);
        }
      }

      // 3. Tải từ Cloud Storage qua HTTP (Supabase / Firebase download URL)
      if (bytes == null &&
          fileUrl != null &&
          (fileUrl.startsWith('http://') || fileUrl.startsWith('https://'))) {
        try {
          final resp = await http.get(Uri.parse(fileUrl));
          if (resp.statusCode == 200) {
            bytes = resp.bodyBytes;
          }
        } catch (httpErr) {
          debugPrint('[FileStorageService] Lỗi tải qua HTTP: $httpErr');
        }
      }

      // 4. Lưu hoặc tải xuống thông qua FileDownloadHelper
      if (bytes != null && bytes.isNotEmpty) {
        final cleanFileName = defaultFileName.contains('.')
            ? defaultFileName
            : '$defaultFileName.pdf';
        final success = await FileDownloadHelper.downloadFile(
          bytes: bytes,
          fileName: cleanFileName,
        );
        if (success) {
          return cleanFileName;
        }
      } else if (fileUrl != null && !fileUrl.startsWith('data:')) {
        await openUrl(fileUrl);
        return fileUrl;
      }
    } catch (e) {
      debugPrint('[FileStorageService] Lỗi exportFile: $e');
    }
    return null;
  }
}
