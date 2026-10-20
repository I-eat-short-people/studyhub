import 'dart:io';
import 'package:flutter/material.dart';
import 'package:drift/drift.dart' as drift;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../../core/database/database_global.dart';
import '../../../core/database/app_database.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/services/auth_sync_service.dart';
import 'pdf_viewer_screen.dart';

class SharedDocumentsScreen extends StatefulWidget {
  const SharedDocumentsScreen({super.key});

  @override
  State<SharedDocumentsScreen> createState() => _SharedDocumentsScreenState();
}

class _SharedDocumentsScreenState extends State<SharedDocumentsScreen> {
  bool _isLoading = true;
  List<SupabaseDocument> _sharedDocuments = [];

  @override
  void initState() {
    super.initState();
    _fetchSharedDocuments();
  }

  Future<void> _fetchSharedDocuments() async {
    setState(() => _isLoading = true);
    final docs = await supabaseService.getDocumentsSharedWithMe();
    if (mounted) {
      setState(() {
        _sharedDocuments = docs;
        _isLoading = false;
      });
    }
  }

  DocumentType _resolveDocumentType(SupabaseDocument doc) {
    final mime = doc.mimeType.toLowerCase();
    final fName = doc.fileName.toLowerCase();
    final sPath = doc.storagePath.toLowerCase();
    final dUrl = (doc.downloadUrl ?? '').toLowerCase();
    final dName = doc.name.toLowerCase();

    if (mime.contains('pdf') ||
        fName.endsWith('.pdf') ||
        sPath.endsWith('.pdf') ||
        dUrl.contains('.pdf') ||
        dName.endsWith('.pdf')) {
      return DocumentType.pdf;
    }
    if (mime.contains('presentation') ||
        mime.contains('powerpoint') ||
        fName.endsWith('.ppt') ||
        fName.endsWith('.pptx') ||
        dName.endsWith('.ppt') ||
        dName.endsWith('.pptx')) {
      return DocumentType.ppt;
    }
    if (mime.contains('word') ||
        fName.endsWith('.doc') ||
        fName.endsWith('.docx') ||
        dName.endsWith('.doc') ||
        dName.endsWith('.docx')) {
      return DocumentType.word;
    }
    if (dUrl.isNotEmpty && (dUrl.startsWith('http://') || dUrl.startsWith('https://')) && !mime.contains('application')) {
      return DocumentType.link;
    }
    return DocumentType.pdf;
  }

  Future<void> _openPreview(SupabaseDocument doc) async {
    if (doc.downloadUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tài liệu không có đường dẫn xem trước')),
      );
      return;
    }

    // Tạo đối tượng Document giả lập để tương thích với PdfViewerScreen
    final tempDoc = Document(
      documentPk: doc.id,
      name: doc.name,
      subjectFk: doc.subjectName ?? 'Môn học',
      type: _resolveDocumentType(doc),
      category: DocumentCategory.values[doc.category.clamp(0, 3)],
      url: doc.downloadUrl,
      fileSize: doc.fileSize,
      note: doc.note,
      isPinned: false,
      tags: doc.tags,
      isPhysical: doc.isPhysical,
      isAvailableForBorrow: doc.isAvailableForBorrow,
      physicalLocation: doc.physicalLocation,
      address: doc.address,
      latitude: doc.latitude,
      longitude: doc.longitude,
      dateCreated: doc.createdAt ?? DateTime.now(),
      dateTimeModified: DateTime.now(),
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfViewerScreen(document: tempDoc),
      ),
    );
  }

  Future<void> _downloadToLocalLibrary(SupabaseDocument doc) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(
        content: Text('Đang tải "${doc.name}" về thư viện máy...'),
        duration: const Duration(seconds: 2),
      ),
    );

    try {
      final bytes = await supabaseService.downloadDocumentBytes(doc.storagePath);
      if (bytes == null || bytes.isEmpty) {
        throw Exception('Không thể tải tệp tin từ Cloud Storage');
      }

      // Lưu tệp vào bộ nhớ ứng dụng
      final appDir = await getApplicationDocumentsDirectory();
      final targetFolder = Directory(p.join(appDir.path, 'studyhub_files'));
      if (!await targetFolder.exists()) {
        await targetFolder.create(recursive: true);
      }

      final safeName = '${DateTime.now().millisecondsSinceEpoch}_${doc.fileName}';
      final localFilePath = p.join(targetFolder.path, safeName);
      final file = File(localFilePath);
      await file.writeAsBytes(bytes);

      // Tìm môn học tương ứng hoặc gán vào môn học đầu tiên
      final subjects = await database.select(database.subjects).get();
      String subjectPk = subjects.isNotEmpty ? subjects.first.subjectPk : 'default_subject';
      if (doc.subjectName != null) {
        final match = subjects.where((s) => s.name.toLowerCase() == doc.subjectName!.toLowerCase());
        if (match.isNotEmpty) {
          subjectPk = match.first.subjectPk;
        }
      }

      // Lưu vào Drift SQLite Database
      final companion = DocumentsCompanion(
        documentPk: drift.Value(doc.id),
        name: drift.Value(doc.name),
        subjectFk: drift.Value(subjectPk),
        type: drift.Value(_resolveDocumentType(doc)),
        category: drift.Value(DocumentCategory.values[doc.category.clamp(0, 3)]),
        filePath: drift.Value(localFilePath),
        url: drift.Value(doc.downloadUrl),
        note: drift.Value(doc.note),
        isPinned: const drift.Value(false),
      );

      await database.documentDao.insertOrUpdateDocument(companion);

      // Lưu ngay vào cache quyền
      supabaseService.cacheAccessInfo(
        doc.id,
        DocumentAccessInfo(
          isOwner: false,
          ownerEmail: doc.ownerEmail,
          permission: doc.sharePermission ?? 'view',
          canEdit: doc.sharePermission == 'edit',
          canShare: false,
        ),
      );

      messenger.showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF2E7D32),
          content: Text('Đã lưu "${doc.name}" vào thư viện tài liệu cục bộ thành công!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFC62828),
          content: Text('Lỗi tải tệp: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final myEmail = firebaseService.userEmail ?? authSyncService.user?.email;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tài liệu được chia sẻ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Làm mới danh sách',
            onPressed: _fetchSharedDocuments,
          ),
        ],
      ),
      body: !supabaseService.isConfigured
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cloud_off_rounded, size: 64, color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(height: 16),
                    const Text(
                      'Chưa cấu hình Supabase',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Vui lòng mở file lib/core/config/supabase_config.dart và dán URL cùng Anon Key từ Supabase Dashboard của bạn.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            )
          : myEmail == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.account_circle_outlined, size: 64, color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(height: 16),
                        const Text(
                          'Vui lòng đăng nhập Google',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Đăng nhập tài khoản Google để hệ thống nhận diện và tải các tài liệu bạn bè đã chia sẻ cho bạn.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                )
              : _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _sharedDocuments.isEmpty
                      ? Center(
                          child: RefreshIndicator(
                            onRefresh: _fetchSharedDocuments,
                            child: SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              child: Padding(
                                padding: const EdgeInsets.all(32),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.folder_shared_outlined,
                                      size: 72,
                                      color: theme.colorScheme.primary.withValues(alpha: 0.4),
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'Chưa có tài liệu nào được chia sẻ',
                                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Khi bạn bè chia sẻ tài liệu đến email:\n$myEmail\nTài liệu sẽ tự động xuất hiện tại đây.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _fetchSharedDocuments,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _sharedDocuments.length,
                            itemBuilder: (ctx, idx) {
                              final doc = _sharedDocuments[idx];
                              final isViewOnly = doc.sharePermission == 'view';
                              final isPdf = _resolveDocumentType(doc) == DocumentType.pdf;

                              return Card(
                                margin: const EdgeInsets.only(bottom: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                elevation: 1,
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: isPdf ? Colors.red.withValues(alpha: 0.12) : Colors.blue.withValues(alpha: 0.12),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Icon(
                                              isPdf ? Icons.picture_as_pdf_rounded : Icons.description_rounded,
                                              color: isPdf ? Colors.red.shade700 : Colors.blue.shade700,
                                              size: 26,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  doc.name,
                                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  doc.subjectName ?? 'Môn học chung',
                                                  style: TextStyle(fontSize: 12, color: theme.colorScheme.primary, fontWeight: FontWeight.w600),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: isViewOnly ? Colors.blue.withValues(alpha: 0.12) : Colors.orange.withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              isViewOnly ? 'Chỉ xem' : 'Được sửa',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: isViewOnly ? Colors.blue.shade800 : Colors.orange.shade900,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.person_pin_rounded, size: 16, color: Color(0xFF1976D2)),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                'Người chia sẻ: ${doc.ownerEmail}',
                                                style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            if (doc.fileSize > 0)
                                              Text(
                                                '${(doc.fileSize / 1024).toStringAsFixed(1)} KB',
                                                style: TextStyle(fontSize: 11.5, color: theme.colorScheme.onSurfaceVariant),
                                              ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          OutlinedButton.icon(
                                            style: OutlinedButton.styleFrom(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                              visualDensity: VisualDensity.compact,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            ),
                                            onPressed: () => _downloadToLocalLibrary(doc),
                                            icon: const Icon(Icons.download_rounded, size: 16),
                                            label: const Text('Lưu vào máy'),
                                          ),
                                          const SizedBox(width: 8),
                                          FilledButton.icon(
                                            style: FilledButton.styleFrom(
                                              backgroundColor: const Color(0xFF1976D2),
                                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                              visualDensity: VisualDensity.compact,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            ),
                                            onPressed: () => _openPreview(doc),
                                            icon: const Icon(Icons.visibility_rounded, size: 16),
                                            label: const Text('Xem trước'),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
    );
  }
}
