import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

Future<bool> downloadFileImpl({
  required Uint8List bytes,
  required String fileName,
}) async {
  try {
    final saveUri = await FilePicker.saveFile(
      dialogTitle: 'Tải tài liệu về máy',
      fileName: fileName,
      bytes: bytes,
    );

    if (saveUri != null) {
      // Nếu saveFile đã tự ghi bytes hoặc trả về đường dẫn
      final path = saveUri.path;
      if (path != null) {
        final f = File(path);
        if (!await f.exists()) {
          await f.writeAsBytes(bytes);
        }
      }
      return true;
    }

    // Fallback: ghi vào thư mục Downloads của hệ thống
    final downloadsDir = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
    final targetPath = p.join(downloadsDir.path, fileName);
    final f = File(targetPath);
    await f.writeAsBytes(bytes);
    return true;
  } catch (e) {
    return false;
  }
}
