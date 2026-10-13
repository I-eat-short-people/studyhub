import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../database/database_global.dart';
import 'auth_sync_service.dart';
import 'firebase_service.dart';

/// Dữ liệu tài liệu được lưu trữ trên Supabase Cloud
class SupabaseDocument {
  final String id;
  final String name;
  final String? subjectName;
  final String ownerUid;
  final String ownerEmail;
  final String fileName;
  final int fileSize;
  final String mimeType;
  final String storagePath;
  final String? downloadUrl;
  final int category;
  final String? note;
  final DateTime? createdAt;
  final String? sharePermission; // 'view' hoặc 'edit' nếu là tài liệu được chia sẻ

  const SupabaseDocument({
    required this.id,
    required this.name,
    this.subjectName,
    required this.ownerUid,
    required this.ownerEmail,
    required this.fileName,
    required this.fileSize,
    required this.mimeType,
    required this.storagePath,
    this.downloadUrl,
    this.category = 0,
    this.note,
    this.createdAt,
    this.sharePermission,
  });

  factory SupabaseDocument.fromJson(Map<String, dynamic> json, {String? sharePermission}) {
    return SupabaseDocument(
      id: json['id'] as String,
      name: json['name'] as String,
      subjectName: json['subject_name'] as String?,
      ownerUid: json['owner_uid'] as String? ?? '',
      ownerEmail: json['owner_email'] as String? ?? '',
      fileName: json['file_name'] as String? ?? 'document.pdf',
      fileSize: json['file_size'] as int? ?? 0,
      mimeType: json['mime_type'] as String? ?? 'application/pdf',
      storagePath: json['storage_path'] as String? ?? '',
      downloadUrl: json['download_url'] as String?,
      category: json['category'] as int? ?? 0,
      note: json['note'] as String?,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
      sharePermission: sharePermission ?? json['permission'] as String?,
    );
  }
}

/// Dữ liệu quyền chia sẻ của một tài liệu
class SupabaseDocumentShare {
  final String id;
  final String documentId;
  final String sharedByUid;
  final String sharedByEmail;
  final String sharedWithEmail;
  final String permission; // 'view' hoặc 'edit'
  final DateTime? createdAt;

  const SupabaseDocumentShare({
    required this.id,
    required this.documentId,
    required this.sharedByUid,
    required this.sharedByEmail,
    required this.sharedWithEmail,
    required this.permission,
    this.createdAt,
  });

  factory SupabaseDocumentShare.fromJson(Map<String, dynamic> json) {
    return SupabaseDocumentShare(
      id: json['id'] as String,
      documentId: json['document_id'] as String,
      sharedByUid: json['shared_by_uid'] as String? ?? '',
      sharedByEmail: json['shared_by_email'] as String? ?? '',
      sharedWithEmail: json['shared_with_email'] as String? ?? '',
      permission: json['permission'] as String? ?? 'view',
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
    );
  }
}

/// Dịch vụ kết nối Supabase Cloud: Storage, Quản lý tài liệu và Phân quyền chia sẻ
class SupabaseService extends ChangeNotifier {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  bool _isInitialized = false;
  bool _isLoading = false;
  String? _lastError;

  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  String? get lastError => _lastError;
  bool get isConfigured => SupabaseConfig.isConfigured;

  SupabaseClient? get client {
    if (!_isInitialized) return null;
    return Supabase.instance.client;
  }

  /// Khởi tạo Supabase an toàn lúc khởi động ứng dụng
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    if (!SupabaseConfig.isConfigured) {
      debugPrint('[SupabaseService] Chưa cấu hình URL và Anon Key trong lib/core/config/supabase_config.dart');
      _isInitialized = false;
      return false;
    }

    try {
      await Supabase.initialize(
        url: SupabaseConfig.supabaseUrl,
        anonKey: SupabaseConfig.supabaseAnonKey,
      );
      _isInitialized = true;
      _lastError = null;
      notifyListeners();
      debugPrint('[SupabaseService] Khởi tạo Supabase thành công!');
      return true;
    } catch (e) {
      debugPrint('[SupabaseService] Lỗi khởi tạo: $e');
      _isInitialized = false;
      _lastError = e.toString();
      notifyListeners();
      return false;
    }
  }

  // =========================================================================
  // 1. SUPABASE CLOUD STORAGE & LƯU METADATA TÀI LIỆU
  // =========================================================================

  /// Tải tệp tài liệu lên Supabase Storage và lưu metadata vào bảng `documents`
  Future<SupabaseDocument?> uploadAndSaveDocument({
    required String documentPk,
    required String name,
    required String? subjectName,
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
    int category = 0,
    String? note,
  }) async {
    if (!isConfigured) {
      _lastError = 'Chưa điền Supabase URL và Anon Key trong file supabase_config.dart';
      notifyListeners();
      return null;
    }

    if (!_isInitialized) {
      final ok = await initialize();
      if (!ok) return null;
    }

    // Lấy thông tin người dùng từ Firebase Auth hoặc Google Profile
    final currentUser = firebaseService.currentUser;
    final currentEmail = currentUser?.email ?? authSyncService.user?.email;
    final currentUid = currentUser?.uid ?? authSyncService.user?.email.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_') ?? 'studyhub_user';

    if (currentEmail == null) {
      _lastError = 'Vui lòng đăng nhập Google trước khi sao lưu tài liệu';
      notifyListeners();
      return null;
    }

    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      final cleanFileName = fileName.replaceAll(RegExp(r'[^\w\.\-]'), '_');
      final storagePath = 'documents/$currentUid/$documentPk/$cleanFileName';

      // 1. Tải lên Supabase Storage
      await client!.storage.from(SupabaseConfig.storageBucketName).uploadBinary(
        storagePath,
        bytes,
        fileOptions: FileOptions(
          contentType: mimeType,
          upsert: true,
        ),
      );

      // 2. Lấy URL xem/tải tệp công khai
      final downloadUrl = client!.storage
          .from(SupabaseConfig.storageBucketName)
          .getPublicUrl(storagePath);

      // 3. Lưu thông tin vào bảng `documents` trên Postgres
      final docData = {
        'id': documentPk,
        'name': name,
        'subject_name': subjectName,
        'owner_uid': currentUid,
        'owner_email': currentEmail.toLowerCase(),
        'file_name': cleanFileName,
        'file_size': bytes.length,
        'mime_type': mimeType,
        'storage_path': storagePath,
        'download_url': downloadUrl,
        'category': category,
        'note': note,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await client!.from('documents').upsert(docData);

      final result = SupabaseDocument.fromJson(docData);
      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      debugPrint('[SupabaseService] Lỗi uploadAndSaveDocument: $e');
      _isLoading = false;
      _lastError = 'Lỗi lưu trữ Supabase: $e';
      notifyListeners();
      return null;
    }
  }

  /// Sao lưu tất cả tài liệu trong máy lên Supabase Cloud
  Future<int> backupAllLocalDocumentsToSupabase({
    Function(int current, int total)? onProgress,
  }) async {
    if (!isConfigured) {
      _lastError = 'Chưa điền Supabase URL và Anon Key trong file supabase_config.dart';
      notifyListeners();
      return 0;
    }

    if (!_isInitialized) {
      final ok = await initialize();
      if (!ok) return 0;
    }

    final currentUser = firebaseService.currentUser;
    final currentEmail = currentUser?.email ?? authSyncService.user?.email;
    if (currentEmail == null) {
      _lastError = 'Vui lòng đăng nhập Google trước khi thực hiện sao lưu';
      notifyListeners();
      return 0;
    }

    _isLoading = true;
    _lastError = null;
    notifyListeners();

    int successCount = 0;
    try {
      final docs = await database.select(database.documents).get();
      final subjects = await database.select(database.subjects).get();
      final subjectMap = {for (var s in subjects) s.subjectPk: s.name};

      if (docs.isEmpty) {
        _lastError = 'Không có tài liệu nào trong thư viện để sao lưu.';
        return 0;
      }

      int processedCount = 0;

      for (int i = 0; i < docs.length; i++) {
        final doc = docs[i];
        Uint8List? fileBytes;

        final lowerName = doc.name.toLowerCase();
        final mimeType = lowerName.endsWith('.pdf')
            ? 'application/pdf'
            : (lowerName.endsWith('.docx') || lowerName.endsWith('.doc'))
                ? 'application/msword'
                : (lowerName.endsWith('.pptx') || lowerName.endsWith('.ppt'))
                    ? 'application/vnd.ms-powerpoint'
                    : 'application/octet-stream';

        // 1. Thử đọc từ filePath cục bộ
        if (doc.filePath != null && doc.filePath!.isNotEmpty) {
          final file = File(doc.filePath!);
          if (await file.exists()) {
            try {
              fileBytes = await file.readAsBytes();
            } catch (err) {
              debugPrint('[SupabaseService] Lỗi đọc filePath: $err');
            }
          }
        }

        // 2. Dự phòng: Trích xuất từ Base64 Data URI trong doc.url
        if (fileBytes == null && doc.url != null && doc.url!.startsWith('data:')) {
          try {
            final commaIdx = doc.url!.indexOf(',');
            if (commaIdx != -1) {
              final base64Str = doc.url!.substring(commaIdx + 1);
              fileBytes = base64Decode(base64Str);
            }
          } catch (err) {
            debugPrint('[SupabaseService] Lỗi giải mã Base64: $err');
          }
        }

        if (fileBytes != null && fileBytes.isNotEmpty) {
          processedCount++;
          final res = await uploadAndSaveDocument(
            documentPk: doc.documentPk,
            name: doc.name,
            subjectName: subjectMap[doc.subjectFk] ?? 'Môn học',
            bytes: fileBytes,
            fileName: doc.name.endsWith('.pdf') || doc.name.endsWith('.docx') ? doc.name : '${doc.name}.pdf',
            mimeType: mimeType,
            category: doc.category.index,
            note: doc.note,
          );

          if (res != null) {
            successCount++;
          }
        }

        if (onProgress != null) {
          onProgress(i + 1, docs.length);
        }
      }

      if (processedCount == 0) {
        _lastError = 'Các tài liệu trong thư viện không có file đính kèm trên máy để tải lên.';
      }
    } catch (e) {
      _lastError = 'Lỗi sao lưu tài liệu lên Supabase: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }

    return successCount;
  }

  // =========================================================================
  // 2. PHÂN QUYỀN VÀ CHIA SẺ TÀI LIỆU (DOCUMENT SHARING)
  // =========================================================================

  /// Chia sẻ một tài liệu cho người dùng khác thông qua địa chỉ Email
  Future<bool> shareDocument({
    required String documentId,
    required String recipientEmail,
    String permission = 'view', // 'view' hoặc 'edit'
  }) async {
    if (!isConfigured || !_isInitialized) {
      _lastError = 'Supabase chưa được cấu hình hoặc chưa khởi tạo';
      notifyListeners();
      return false;
    }

    final currentUser = firebaseService.currentUser;
    final myEmail = currentUser?.email ?? authSyncService.user?.email;
    final myUid = currentUser?.uid ?? authSyncService.user?.email ?? 'anonymous';

    if (myEmail == null) {
      _lastError = 'Vui lòng đăng nhập Google trước khi chia sẻ tài liệu';
      notifyListeners();
      return false;
    }

    final cleanRecipient = recipientEmail.trim().toLowerCase();
    if (cleanRecipient == myEmail.toLowerCase()) {
      _lastError = 'Bạn không thể tự chia sẻ tài liệu cho chính mình';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      // 1. Kiểm tra tài liệu đã tồn tại trên bảng `documents` Supabase chưa
      final docRes = await client!.from('documents').select('id').eq('id', documentId).maybeSingle();
      if (docRes == null) {
        // Tài liệu chưa được sao lưu lên Cloud, cần đồng bộ tài liệu này trước
        final localDoc = await (database.select(database.documents)..where((d) => d.documentPk.equals(documentId))).getSingleOrNull();
        if (localDoc == null) {
          throw Exception('Không tìm thấy tài liệu trong cơ sở dữ liệu máy');
        }

        // Tự động tải lên Supabase trước khi chia sẻ
        Uint8List? bytes;
        if (localDoc.filePath != null && await File(localDoc.filePath!).exists()) {
          bytes = await File(localDoc.filePath!).readAsBytes();
        } else if (localDoc.url != null && localDoc.url!.startsWith('data:')) {
          final idx = localDoc.url!.indexOf(',');
          if (idx != -1) bytes = base64Decode(localDoc.url!.substring(idx + 1));
        }

        if (bytes == null) {
          throw Exception('Tài liệu không có nội dung tệp để chia sẻ lên Cloud');
        }

        final subjects = await database.select(database.subjects).get();
        final subName = subjects.firstWhere((s) => s.subjectPk == localDoc.subjectFk, orElse: () => subjects.first).name;

        await uploadAndSaveDocument(
          documentPk: localDoc.documentPk,
          name: localDoc.name,
          subjectName: subName,
          bytes: bytes,
          fileName: localDoc.name.endsWith('.pdf') ? localDoc.name : '${localDoc.name}.pdf',
          mimeType: 'application/pdf',
          category: localDoc.category.index,
          note: localDoc.note,
        );
      }

      // 2. Thêm quyền vào bảng `document_shares`
      await client!.from('document_shares').upsert(
        {
          'document_id': documentId,
          'shared_by_uid': myUid,
          'shared_by_email': myEmail.toLowerCase(),
          'shared_with_email': cleanRecipient,
          'permission': permission,
        },
        onConflict: 'document_id,shared_with_email',
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('[SupabaseService] Lỗi shareDocument: $e');
      _isLoading = false;
      _lastError = 'Lỗi chia sẻ tài liệu: $e';
      notifyListeners();
      return false;
    }
  }

  /// Lấy danh sách những người đang được chia sẻ quyền của một tài liệu
  Future<List<SupabaseDocumentShare>> getDocumentShares(String documentId) async {
    if (!isConfigured || !_isInitialized) return [];

    try {
      final res = await client!
          .from('document_shares')
          .select()
          .eq('document_id', documentId)
          .order('created_at', ascending: false);

      return (res as List).map((item) => SupabaseDocumentShare.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('[SupabaseService] Lỗi getDocumentShares: $e');
      return [];
    }
  }

  /// Thu hồi quyền chia sẻ của một người dùng
  Future<bool> revokeShare(String shareId) async {
    if (!isConfigured || !_isInitialized) return false;

    try {
      await client!.from('document_shares').delete().eq('id', shareId);
      return true;
    } catch (e) {
      debugPrint('[SupabaseService] Lỗi revokeShare: $e');
      return false;
    }
  }

  /// Lấy danh sách các tài liệu mà người khác đã chia sẻ cho tài khoản hiện tại
  Future<List<SupabaseDocument>> getDocumentsSharedWithMe() async {
    if (!isConfigured) return [];
    if (!_isInitialized) {
      final ok = await initialize();
      if (!ok) return [];
    }

    final currentUser = firebaseService.currentUser;
    final myEmail = currentUser?.email ?? authSyncService.user?.email;
    if (myEmail == null) return [];

    try {
      // 1. Tìm các bản ghi share cấp cho email của tôi
      final sharesRes = await client!
          .from('document_shares')
          .select('id, document_id, permission, shared_by_email')
          .eq('shared_with_email', myEmail.trim().toLowerCase());

      final sharesList = sharesRes as List;
      if (sharesList.isEmpty) return [];

      final docIds = sharesList.map((s) => s['document_id'] as String).toList();
      final permissionMap = {for (var s in sharesList) s['document_id'] as String: s['permission'] as String};

      // 2. Lấy thông tin các tài liệu từ bảng `documents`
      final docsRes = await client!
          .from('documents')
          .select()
          .inFilter('id', docIds)
          .order('created_at', ascending: false);

      return (docsRes as List).map((docJson) {
        final docId = docJson['id'] as String;
        return SupabaseDocument.fromJson(
          docJson as Map<String, dynamic>,
          sharePermission: permissionMap[docId],
        );
      }).toList();
    } catch (e) {
      debugPrint('[SupabaseService] Lỗi getDocumentsSharedWithMe: $e');
      _lastError = 'Lỗi nạp tài liệu được chia sẻ: $e';
      return [];
    }
  }

  /// Tải tệp bytes từ Supabase Storage về máy
  Future<Uint8List?> downloadDocumentBytes(String storagePath) async {
    if (!isConfigured || !_isInitialized) return null;

    try {
      return await client!.storage.from(SupabaseConfig.storageBucketName).download(storagePath);
    } catch (e) {
      debugPrint('[SupabaseService] Lỗi downloadDocumentBytes: $e');
      _lastError = 'Lỗi tải tệp: $e';
      return null;
    }
  }
}

/// Instance tiện ích toàn cục
final supabaseService = SupabaseService();
