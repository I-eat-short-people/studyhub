import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:drift/drift.dart' as drift;
import '../config/supabase_config.dart';
import '../database/app_database.dart';
import '../database/database_global.dart';
import 'auth_sync_service.dart';
import 'firebase_service.dart';

/// Thông tin quyền truy cập và chủ sở hữu của một tài liệu
class DocumentAccessInfo {
  final bool isOwner;
  final String? ownerEmail;
  final String permission; // 'owner', 'edit', 'view', 'local'
  final bool canEdit;
  final bool canShare;

  const DocumentAccessInfo({
    required this.isOwner,
    this.ownerEmail,
    this.permission = 'owner',
    required this.canEdit,
    this.canShare = true,
  });

  bool get isViewOnly => !isOwner && permission == 'view';

  Map<String, dynamic> toJson() => {
        'isOwner': isOwner,
        'ownerEmail': ownerEmail,
        'permission': permission,
        'canEdit': canEdit,
        'canShare': canShare,
      };

  factory DocumentAccessInfo.fromJson(Map<String, dynamic> json) => DocumentAccessInfo(
        isOwner: json['isOwner'] as bool? ?? true,
        ownerEmail: json['ownerEmail'] as String?,
        permission: json['permission'] as String? ?? 'owner',
        canEdit: json['canEdit'] as bool? ?? true,
        canShare: json['canShare'] as bool? ?? true,
      );
}

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
  final String tags;
  final bool isPhysical;
  final bool isAvailableForBorrow;
  final String? physicalLocation;
  final String? address;
  final double? latitude;
  final double? longitude;
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
    this.tags = '',
    this.isPhysical = false,
    this.isAvailableForBorrow = false,
    this.physicalLocation,
    this.address,
    this.latitude,
    this.longitude,
    this.createdAt,
    this.sharePermission,
  });

  factory SupabaseDocument.fromJson(
    Map<String, dynamic> json, {
    String? sharePermission,
    String? overrideOwnerEmail,
  }) {
    final rawNote = json['note'] as String?;
    final meta = SupabaseService.extractMetadataFromNote(rawNote);
    final cleanNote = SupabaseService.unpackCleanNote(rawNote);

    final rawOwner = (overrideOwnerEmail != null && overrideOwnerEmail.isNotEmpty)
        ? overrideOwnerEmail
        : (json['owner_email'] as String? ?? '');
    final ownerEmail = (rawOwner.isNotEmpty)
        ? rawOwner
        : (meta['owner_email'] as String? ?? '');

    final tags = (json['tags'] as String?)?.isNotEmpty == true
        ? json['tags'] as String
        : (meta['tags'] as String? ?? '');
    final isPhysical = (json['is_physical'] as bool?) ?? (meta['is_physical'] as bool? ?? false);
    final isAvailableForBorrow = (json['is_available_for_borrow'] as bool?) ?? (meta['is_available_for_borrow'] as bool? ?? false);
    final physicalLocation = (json['physical_location'] as String?) ?? meta['physical_location'] as String?;
    final address = (json['address'] as String?) ?? meta['address'] as String?;
    final latitude = (json['latitude'] as num?)?.toDouble() ?? (meta['latitude'] as num?)?.toDouble();
    final longitude = (json['longitude'] as num?)?.toDouble() ?? (meta['longitude'] as num?)?.toDouble();

    return SupabaseDocument(
      id: json['id'] as String,
      name: json['name'] as String,
      subjectName: json['subject_name'] as String?,
      ownerUid: json['owner_uid'] as String? ?? '',
      ownerEmail: ownerEmail,
      fileName: json['file_name'] as String? ?? 'document.pdf',
      fileSize: json['file_size'] as int? ?? 0,
      mimeType: json['mime_type'] as String? ?? 'application/pdf',
      storagePath: json['storage_path'] as String? ?? '',
      downloadUrl: json['download_url'] as String?,
      category: json['category'] as int? ?? 0,
      note: cleanNote.isNotEmpty ? cleanNote : null,
      tags: tags,
      isPhysical: isPhysical,
      isAvailableForBorrow: isAvailableForBorrow,
      physicalLocation: physicalLocation,
      address: address,
      latitude: latitude,
      longitude: longitude,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
      sharePermission: sharePermission ?? json['permission'] as String?,
    );
  }
}

/// Dữ liệu yêu cầu mượn tài liệu P2P
class SupabaseBorrowRequest {
  final String id;
  final String documentId;
  final String? documentName;
  final String borrowerUid;
  final String borrowerEmail;
  final String? borrowerName;
  final String ownerUid;
  final String ownerEmail;
  final String status; // 'pending', 'approved', 'rejected', 'borrowed', 'returned'
  final DateTime? borrowDate;
  final DateTime? dueDate;
  final DateTime? returnedDate;
  final String? note;
  final DateTime? createdAt;
  final String? physicalLocation;
  final String? address;

  const SupabaseBorrowRequest({
    required this.id,
    required this.documentId,
    this.documentName,
    required this.borrowerUid,
    required this.borrowerEmail,
    this.borrowerName,
    required this.ownerUid,
    required this.ownerEmail,
    this.status = 'pending',
    this.borrowDate,
    this.dueDate,
    this.returnedDate,
    this.note,
    this.createdAt,
    this.physicalLocation,
    this.address,
  });

  factory SupabaseBorrowRequest.fromJson(
    Map<String, dynamic> json, {
    String? documentName,
    String? physicalLocation,
    String? address,
  }) {
    return SupabaseBorrowRequest(
      id: json['id'] as String,
      documentId: json['document_id'] as String,
      documentName: documentName ?? json['document_name'] as String?,
      borrowerUid: json['borrower_uid'] as String? ?? '',
      borrowerEmail: json['borrower_email'] as String? ?? '',
      borrowerName: json['borrower_name'] as String?,
      ownerUid: json['owner_uid'] as String? ?? '',
      ownerEmail: json['owner_email'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      borrowDate: json['borrow_date'] != null ? DateTime.tryParse(json['borrow_date'] as String) : null,
      dueDate: json['due_date'] != null ? DateTime.tryParse(json['due_date'] as String) : null,
      returnedDate: json['returned_date'] != null ? DateTime.tryParse(json['returned_date'] as String) : null,
      note: json['note'] as String?,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
      physicalLocation: physicalLocation ?? json['physical_location'] as String?,
      address: address ?? json['address'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'document_id': documentId,
      'document_name': documentName,
      'borrower_uid': borrowerUid,
      'borrower_email': borrowerEmail,
      'borrower_name': borrowerName,
      'owner_uid': ownerUid,
      'owner_email': ownerEmail,
      'status': status,
      'borrow_date': borrowDate?.toIso8601String(),
      'due_date': dueDate?.toIso8601String(),
      'returned_date': returnedDate?.toIso8601String(),
      'note': note,
      'created_at': createdAt?.toIso8601String(),
      'physical_location': physicalLocation,
      'address': address,
    };
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

  final Map<String, DocumentAccessInfo> _accessInfoCache = {};
  final Map<String, String> _localDocOwnerEmails = {};
  final List<SupabaseBorrowRequest> _localBorrowRequests = [];
  final List<Map<String, dynamic>> _localDocumentShares = [];
  bool _isDiskCacheLoaded = false;
  bool _isSyncingDocs = false;

  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  String? get lastError => _lastError;
  bool get isConfigured => SupabaseConfig.isConfigured;

  SupabaseClient? get client {
    if (!_isInitialized) return null;
    return Supabase.instance.client;
  }

  /// Email của người dùng hiện tại (từ Google Auth hoặc Firebase)
  String? get currentUserEmail {
    final e = _currentEmail;
    return e.isNotEmpty ? e : null;
  }


  String get _currentEmail {
    final authEmail = authSyncService.user?.email;
    if (authEmail != null && authEmail.trim().isNotEmpty) {
      return authEmail.trim().toLowerCase();
    }
    final fbEmail = firebaseService.currentUser?.email;
    if (fbEmail != null && fbEmail.trim().isNotEmpty) {
      return fbEmail.trim().toLowerCase();
    }
    return '';
  }

  String get _currentUid {
    final fbUid = firebaseService.currentUser?.uid;
    if (fbUid != null && fbUid.trim().isNotEmpty) {
      return fbUid.trim();
    }
    final email = _currentEmail;
    if (email.isNotEmpty) {
      return email.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    }
    return 'anonymous';
  }

  String _cacheKey(String documentId, [String? email]) {
    final em = (email ?? _currentEmail).trim().toLowerCase();
    return '$em:$documentId';
  }

  /// Xoá toàn bộ bộ nhớ tạm quyền trong RAM (khi đổi tài khoản hoặc đăng xuất)
  Future<void> clearAccessCache() async {
    _accessInfoCache.clear();
    _isDiskCacheLoaded = false;
    notifyListeners();
  }

  /// Đọc bộ nhớ cache quyền tài liệu, chủ sở hữu và danh sách chia sẻ từ file JSON nội bộ
  Future<void> _ensureDiskCacheLoaded() async {
    if (_isDiskCacheLoaded) return;
    if (kIsWeb) {
      _isDiskCacheLoaded = true;
      return;
    }
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final cacheFile = File(p.join(appDir.path, 'studyhub_doc_access_cache.json'));
      if (await cacheFile.exists()) {
        final content = await cacheFile.readAsString();
        final Map<String, dynamic> data = jsonDecode(content);
        data.forEach((k, infoJson) {
          // Chỉ nạp cache có định dạng userEmail:docId
          if (k.contains(':')) {
            _accessInfoCache[k] = DocumentAccessInfo.fromJson(infoJson as Map<String, dynamic>);
          }
        });
      }

      final ownersFile = File(p.join(appDir.path, 'studyhub_local_doc_owners.json'));
      if (await ownersFile.exists()) {
        final content = await ownersFile.readAsString();
        final Map<String, dynamic> data = jsonDecode(content);
        data.forEach((docId, email) {
          if (email is String && email.isNotEmpty) {
            _localDocOwnerEmails[docId] = email.trim().toLowerCase();
          }
        });
      }

      final requestsFile = File(p.join(appDir.path, 'studyhub_local_borrow_requests.json'));
      if (await requestsFile.exists()) {
        final content = await requestsFile.readAsString();
        final List<dynamic> list = jsonDecode(content);
        _localBorrowRequests.clear();
        for (final item in list) {
          if (item is Map<String, dynamic>) {
            _localBorrowRequests.add(SupabaseBorrowRequest.fromJson(item));
          }
        }
      }

      final sharesFile = File(p.join(appDir.path, 'studyhub_local_document_shares.json'));
      if (await sharesFile.exists()) {
        final content = await sharesFile.readAsString();
        final List<dynamic> list = jsonDecode(content);
        _localDocumentShares.clear();
        for (final item in list) {
          if (item is Map<String, dynamic>) {
            _localDocumentShares.add(Map<String, dynamic>.from(item));
          }
        }
      }
    } catch (e) {
      debugPrint('[SupabaseService] Lỗi đọc disk access cache: $e');
    } finally {
      _isDiskCacheLoaded = true;
    }
  }

  /// Lưu bộ nhớ cache quyền tài liệu, chủ sở hữu và danh sách chia sẻ ra file JSON
  Future<void> _saveDiskCache() async {
    if (kIsWeb) return;
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final cacheFile = File(p.join(appDir.path, 'studyhub_doc_access_cache.json'));
      final data = _accessInfoCache.map((k, v) => MapEntry(k, v.toJson()));
      await cacheFile.writeAsString(jsonEncode(data));

      final ownersFile = File(p.join(appDir.path, 'studyhub_local_doc_owners.json'));
      await ownersFile.writeAsString(jsonEncode(_localDocOwnerEmails));

      final requestsFile = File(p.join(appDir.path, 'studyhub_local_borrow_requests.json'));
      final reqData = _localBorrowRequests.map((r) => r.toJson()).toList();
      await requestsFile.writeAsString(jsonEncode(reqData));

      final sharesFile = File(p.join(appDir.path, 'studyhub_local_document_shares.json'));
      await sharesFile.writeAsString(jsonEncode(_localDocumentShares));
    } catch (e) {
      debugPrint('[SupabaseService] Lỗi ghi disk access cache: $e');
    }
  }

  static const String _metaPrefix = '<!--STUDYHUB_META:';
  static const String _metaSuffix = '-->';

  /// Đóng gói siêu dữ liệu (tags, vị trí vật lý, toạ độ, chủ sở hữu) vào note
  static String packMetadataIntoNote({
    String? note,
    String? tags,
    bool? isPhysical,
    bool? isAvailableForBorrow,
    String? physicalLocation,
    String? address,
    double? latitude,
    double? longitude,
    String? ownerEmail,
  }) {
    final meta = <String, dynamic>{};
    if (ownerEmail != null && ownerEmail.isNotEmpty) meta['owner_email'] = ownerEmail.trim().toLowerCase();
    if (tags != null && tags.isNotEmpty) meta['tags'] = tags;
    if (isPhysical == true) meta['is_physical'] = true;
    if (isAvailableForBorrow == true) meta['is_available_for_borrow'] = true;
    if (physicalLocation != null && physicalLocation.isNotEmpty) meta['physical_location'] = physicalLocation;
    if (address != null && address.isNotEmpty) meta['address'] = address;
    if (latitude != null) meta['latitude'] = latitude;
    if (longitude != null) meta['longitude'] = longitude;

    final clean = unpackCleanNote(note);
    if (meta.isEmpty) return clean;

    final metaJson = jsonEncode(meta);
    if (clean.isEmpty) {
      return '$_metaPrefix$metaJson$_metaSuffix';
    } else {
      return '$_metaPrefix$metaJson$_metaSuffix\n$clean';
    }
  }

  /// Trích xuất nội dung ghi chú sạch (loại bỏ phần siêu dữ liệu đóng gói)
  static String unpackCleanNote(String? rawNote) {
    if (rawNote == null || rawNote.isEmpty) return '';
    if (!rawNote.contains(_metaPrefix)) return rawNote;
    final start = rawNote.indexOf(_metaPrefix);
    final end = rawNote.indexOf(_metaSuffix, start);
    if (start != -1 && end != -1) {
      final before = rawNote.substring(0, start).trim();
      final after = rawNote.substring(end + _metaSuffix.length).trim();
      if (before.isEmpty) return after;
      if (after.isEmpty) return before;
      return '$before\n$after';
    }
    return rawNote;
  }

  /// Trích xuất Map siêu dữ liệu từ ghi chú
  static Map<String, dynamic> extractMetadataFromNote(String? rawNote) {
    if (rawNote == null || rawNote.isEmpty) return {};
    final start = rawNote.indexOf(_metaPrefix);
    if (start == -1) return {};
    final end = rawNote.indexOf(_metaSuffix, start);
    if (end == -1) return {};
    try {
      final jsonStr = rawNote.substring(start + _metaPrefix.length, end);
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  /// Lấy email người tạo từ metadata ghi chú hoặc cache
  String? getDocumentCreator(Document doc) {
    final meta = extractMetadataFromNote(doc.note);
    if (meta['owner_email'] is String && (meta['owner_email'] as String).isNotEmpty) {
      return (meta['owner_email'] as String).trim().toLowerCase();
    }
    return getLocalDocumentOwner(doc.documentPk);
  }

  /// Đăng ký chủ sở hữu cục bộ cho tài liệu (ngay khi tạo hoặc sửa)
  Future<void> registerLocalDocOwner(String documentId, String ownerEmail) async {
    if (ownerEmail.trim().isEmpty) return;
    await _ensureDiskCacheLoaded();
    _localDocOwnerEmails[documentId] = ownerEmail.trim().toLowerCase();
    await _saveDiskCache();
  }

  /// Lấy chủ sở hữu đã đăng ký của tài liệu cục bộ
  String? getLocalDocumentOwner(String documentId) {
    return _localDocOwnerEmails[documentId];
  }

  /// Lưu quyền vào cache ngay khi biết thông tin
  void cacheAccessInfo(String documentId, DocumentAccessInfo info) {
    final key = _cacheKey(documentId);
    _accessInfoCache[key] = info;
    _saveDiskCache();
    notifyListeners();
  }

  /// Lấy nhanh thông tin quyền từ bộ nhớ tạm (đồng bộ)
  DocumentAccessInfo? getCachedAccessInfo(String documentId) {
    final key = _cacheKey(documentId);
    return _accessInfoCache[key];
  }

  /// Kiểm tra xem tài liệu này có được chia sẻ cho tài khoản hiện tại không
  bool isDocumentSharedWithMe(String documentId) {
    final myEmail = _currentEmail;
    if (myEmail.isEmpty) return false;
    final access = getCachedAccessInfo(documentId);
    if (access != null && !access.isOwner && access.permission != 'none') {
      return true;
    }
    for (final s in _localDocumentShares) {
      if (s['document_id'] == documentId &&
          (s['shared_with_email'] as String? ?? '').trim().toLowerCase() == myEmail) {
        return true;
      }
    }
    return false;
  }

  /// Lấy quyền hạn chi tiết và chủ sở hữu của tài liệu
  Future<DocumentAccessInfo> getDocumentAccessInfo(String documentId) async {
    await _ensureDiskCacheLoaded();
    final myEmail = _currentEmail;
    final cacheKey = _cacheKey(documentId, myEmail);

    // Kiểm tra trước: Nếu tài liệu này trong SQLite do chính myEmail tạo trên máy
    final existingLocal = await (database.select(database.documents)
          ..where((d) => d.documentPk.equals(documentId)))
        .getSingleOrNull();
    if (existingLocal != null) {
      final creator = getDocumentCreator(existingLocal);
      if (creator != null && creator.isNotEmpty && creator == myEmail && myEmail.isNotEmpty) {
        final myDocInfo = DocumentAccessInfo(
          isOwner: true,
          ownerEmail: myEmail,
          permission: 'owner',
          canEdit: true,
          canShare: true,
        );
        _accessInfoCache[cacheKey] = myDocInfo;
        return myDocInfo;
      }
    }

    // Nếu chưa cấu hình Supabase hoặc chưa đăng nhập, mặc định là tài liệu của máy
    if (!isConfigured || myEmail.isEmpty) {
      final defaultInfo = const DocumentAccessInfo(isOwner: true, canEdit: true);
      _accessInfoCache[cacheKey] = defaultInfo;
      return defaultInfo;
    }

    if (!_isInitialized) {
      final ok = await initialize();
      if (!ok) {
        final defaultInfo = const DocumentAccessInfo(isOwner: true, canEdit: true);
        _accessInfoCache[cacheKey] = defaultInfo;
        return defaultInfo;
      }
    }

    try {
      // 1. Kiểm tra tài liệu trên bảng documents
      final docRes = await client!
          .from('documents')
          .select('owner_email, owner_uid')
          .eq('id', documentId)
          .maybeSingle();

      // 2. Tra cứu thêm trong bảng document_shares của tài liệu này
      final sharesRes = await client!
          .from('document_shares')
          .select('shared_by_email, shared_with_email, permission')
          .eq('document_id', documentId);
      final sharesList = (sharesRes as List? ?? []);

      String ownerEmail = (docRes?['owner_email'] as String? ?? '').trim().toLowerCase();

      // Kiểm tra xem myEmail có phải là người đã chia sẻ tài liệu này (shared_by_email) không
      final isSharer = sharesList.any((s) =>
          (s['shared_by_email'] as String? ?? '').trim().toLowerCase() == myEmail);

      // Kiểm tra xem myEmail có phải là người nhận được chia sẻ (shared_with_email) không
      Map<String, dynamic>? myShareMatch;
      for (final s in sharesList) {
        if ((s['shared_with_email'] as String? ?? '').trim().toLowerCase() == myEmail) {
          myShareMatch = s as Map<String, dynamic>;
          break;
        }
      }

      // TH1: Tôi là người chia sẻ tài liệu này (isSharer), hoặc tôi là chủ sở hữu và KHÔNG PHẢI người nhận
      if (isSharer || (ownerEmail == myEmail && myShareMatch == null)) {
        // Tài liệu chính chủ của mình!
        // Nếu trên bảng documents owner_email đang bị ghi sai, tự động cập nhật lại đúng email chính chủ
        if (ownerEmail != myEmail && docRes != null) {
          try {
            await client!.from('documents').update({
              'owner_email': myEmail,
              'owner_uid': _currentUid,
            }).eq('id', documentId);
          } catch (_) {}
        }

        final myDocInfo = DocumentAccessInfo(
          isOwner: true,
          ownerEmail: myEmail,
          permission: 'owner',
          canEdit: true,
          canShare: true,
        );
        _accessInfoCache[cacheKey] = myDocInfo;
        _saveDiskCache();
        return myDocInfo;
      }

      // TH2: Tài liệu được chia sẻ CHO TÔI (myShareMatch != null)
      if (myShareMatch != null) {
        final realOwner = (myShareMatch['shared_by_email'] as String? ?? ownerEmail).trim().toLowerCase();
        final perm = (myShareMatch['permission'] as String? ?? 'view').trim().toLowerCase();

        final sharedInfo = DocumentAccessInfo(
          isOwner: false,
          ownerEmail: realOwner.isNotEmpty ? realOwner : (ownerEmail.isNotEmpty ? ownerEmail : 'Chủ tài liệu'),
          permission: perm,
          canEdit: perm == 'edit',
          canShare: false,
        );

        _accessInfoCache[cacheKey] = sharedInfo;
        _saveDiskCache();
        return sharedInfo;
      }

      // TH3: Nếu tài liệu chưa có trên Cloud và chưa từng share
      final localOwner = getLocalDocumentOwner(documentId);
      if (localOwner != null && localOwner.isNotEmpty && myEmail.isNotEmpty && localOwner != myEmail) {
        // Tài liệu do tài khoản khác tạo trên máy (chưa đẩy lên Cloud hoặc tạo offline) -> Thuộc sở hữu của tài khoản đó
        final otherOwnerInfo = DocumentAccessInfo(
          isOwner: false,
          ownerEmail: localOwner,
          permission: 'none',
          canEdit: false,
          canShare: false,
        );
        _accessInfoCache[cacheKey] = otherOwnerInfo;
        _saveDiskCache();
        return otherOwnerInfo;
      }

      if (docRes == null && sharesList.isEmpty) {
        final defaultInfo = const DocumentAccessInfo(isOwner: true, canEdit: true);
        _accessInfoCache[cacheKey] = defaultInfo;
        return defaultInfo;
      }

      // TH4: Tài liệu của người khác (không chia sẻ cho tôi)
      final fallbackInfo = DocumentAccessInfo(
        isOwner: false,
        ownerEmail: ownerEmail.isNotEmpty ? ownerEmail : 'Chủ tài liệu',
        permission: 'none',
        canEdit: false,
        canShare: false,
      );
      _accessInfoCache[cacheKey] = fallbackInfo;
      _saveDiskCache();
      return fallbackInfo;
    } catch (e) {
      debugPrint('[SupabaseService] Lỗi getDocumentAccessInfo: $e');
      final fallback = const DocumentAccessInfo(isOwner: true, canEdit: true);
      _accessInfoCache[cacheKey] = fallback;
      return fallback;
    }
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
    Uint8List? bytes,
    required String fileName,
    required String mimeType,
    int category = 0,
    String? note,
    String tags = '',
    bool isPhysical = false,
    bool isAvailableForBorrow = false,
    String? physicalLocation,
    String? address,
    double? latitude,
    double? longitude,
    String? downloadUrl,
    String? customOwnerEmail,
    bool notify = true,
  }) async {
    if (!isConfigured) {
      _lastError = 'Chưa điền Supabase URL và Anon Key trong file supabase_config.dart';
      if (notify) notifyListeners();
      return null;
    }

    if (!_isInitialized) {
      final ok = await initialize();
      if (!ok) return null;
    }

    // Lấy thông tin người dùng hiện tại (ưu tiên customOwnerEmail nếu được truyền trực tiếp)
    final currentEmail = (customOwnerEmail != null && customOwnerEmail.trim().isNotEmpty)
        ? customOwnerEmail.trim().toLowerCase()
        : _currentEmail;
    final currentUid = firebaseService.currentUser?.uid ?? currentEmail.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');

    if (currentEmail.isEmpty) {
      _lastError = 'Vui lòng đăng nhập Google trước khi sao lưu tài liệu';
      if (notify) notifyListeners();
      return null;
    }

    if (notify) {
      _isLoading = true;
      _lastError = null;
      notifyListeners();
    }

    try {
      final cleanFileName = fileName.replaceAll(RegExp(r'[^\w\.\-]'), '_');

      // KIỂM TRA QUYỀN HẠN: Nếu tài liệu đã có trên Cloud từ trước
      String finalOwnerUid = currentUid;
      String finalOwnerEmail = currentEmail.toLowerCase();

      final existingDoc = await client!
          .from('documents')
          .select('owner_uid, owner_email, storage_path')
          .eq('id', documentPk)
          .maybeSingle();

      if (existingDoc != null) {
        final existingOwnerEmail = (existingDoc['owner_email'] as String? ?? '').toLowerCase();
        final existingOwnerUid = existingDoc['owner_uid'] as String? ?? currentUid;

        if (existingOwnerEmail.isNotEmpty && existingOwnerEmail != currentEmail.toLowerCase()) {
          // Người thực hiện KHÔNG PHẢI chủ tài liệu -> Phải có quyền 'edit'
          final shareRecord = await client!
              .from('document_shares')
              .select('permission')
              .eq('document_id', documentPk)
              .eq('shared_with_email', currentEmail.toLowerCase())
              .maybeSingle();

          final perm = (shareRecord?['permission'] as String? ?? 'view').toLowerCase();
          if (perm != 'edit') {
            _lastError = 'Bạn chỉ có quyền xem tài liệu này (do $existingOwnerEmail cấp), không thể chỉnh sửa.';
            debugPrint('[SupabaseService] TỪ CHỐI SỬA: ${currentEmail.toLowerCase()} chỉ có quyền "$perm" với tài liệu $documentPk');
            if (notify) {
              _isLoading = false;
              notifyListeners();
            }
            return null;
          }

          // Được phép sửa: Giữ nguyên chủ sở hữu gốc của tài liệu
          finalOwnerUid = existingOwnerUid;
          finalOwnerEmail = existingOwnerEmail;
        }
      }

      String storagePath = 'documents/$finalOwnerUid/$documentPk/$cleanFileName';
      String? finalDownloadUrl = downloadUrl;

      // 1. Tải lên Supabase Storage nếu có dữ liệu bytes
      if (bytes != null && bytes.isNotEmpty) {
        try {
          await client!.storage.from(SupabaseConfig.storageBucketName).uploadBinary(
            storagePath,
            bytes,
            fileOptions: FileOptions(
              contentType: mimeType,
              upsert: true,
            ),
          ).timeout(const Duration(seconds: 7));

          // 2. Lấy URL xem/tải tệp công khai
          finalDownloadUrl = client!.storage
              .from(SupabaseConfig.storageBucketName)
              .getPublicUrl(storagePath);
        } catch (storageErr) {
          debugPrint('[SupabaseService] Bỏ qua upload binary vì lỗi Storage hoặc timeout ($storageErr)');
        }
      } else {
        storagePath = 'physical/$finalOwnerUid/$documentPk/$cleanFileName';
      }

      // Đóng gói siêu dữ liệu vật lý & tags vào note để đảm bảo an toàn tuyệt đối ngay cả khi Supabase thiếu cột
      final packedNote = packMetadataIntoNote(
        note: note,
        tags: tags,
        isPhysical: isPhysical,
        isAvailableForBorrow: isAvailableForBorrow,
        physicalLocation: physicalLocation,
        address: address,
        latitude: latitude,
        longitude: longitude,
        ownerEmail: finalOwnerEmail,
      );

      // 3. Lưu thông tin vào bảng `documents` trên Postgres
      final docData = {
        'id': documentPk,
        'name': name,
        'subject_name': subjectName,
        'owner_uid': finalOwnerUid,
        'owner_email': finalOwnerEmail,
        'file_name': cleanFileName,
        'file_size': bytes?.length ?? 0,
        'mime_type': mimeType,
        'storage_path': storagePath,
        'download_url': finalDownloadUrl,
        'category': category,
        'note': packedNote,
        'tags': tags,
        'is_physical': isPhysical,
        'is_available_for_borrow': isAvailableForBorrow,
        'physical_location': physicalLocation,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      try {
        await client!.from('documents').upsert(docData).timeout(const Duration(seconds: 7));
      } catch (upsertErr) {
        debugPrint('[SupabaseService] Upsert full fields failed ($upsertErr), retrying with core fields + packedNote');
        final coreData = <String, dynamic>{
          'id': documentPk,
          'name': name,
          'subject_name': subjectName,
          'owner_uid': finalOwnerUid,
          'owner_email': finalOwnerEmail,
          'file_name': cleanFileName,
          'file_size': bytes?.length ?? 0,
          'mime_type': mimeType,
          'storage_path': storagePath,
          'download_url': finalDownloadUrl,
          'category': category,
          'note': packedNote,
          'updated_at': DateTime.now().toIso8601String(),
        };
        await client!.from('documents').upsert(coreData).timeout(const Duration(seconds: 7));
      }

      _localDocOwnerEmails[documentPk] = finalOwnerEmail;
      _saveDiskCache();

      final result = SupabaseDocument.fromJson(docData);
      if (notify) {
        _isLoading = false;
        notifyListeners();
      }
      return result;
    } catch (e) {
      debugPrint('[SupabaseService] Lỗi uploadAndSaveDocument: $e');
      if (notify) {
        _isLoading = false;
        _lastError = 'Lỗi lưu trữ Supabase: $e';
        notifyListeners();
      }
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

    final currentEmail = _currentEmail;
    if (currentEmail.isEmpty) {
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
        final mimeType = doc.type == DocumentType.pdf
            ? 'application/pdf'
            : doc.type == DocumentType.word
                ? 'application/msword'
                : doc.type == DocumentType.ppt
                    ? 'application/vnd.ms-powerpoint'
                    : (lowerName.endsWith('.pdf') ? 'application/pdf' : 'application/octet-stream');

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
            tags: doc.tags,
            isPhysical: doc.isPhysical,
            isAvailableForBorrow: doc.isAvailableForBorrow,
            physicalLocation: doc.physicalLocation,
            address: doc.address,
            latitude: doc.latitude,
            longitude: doc.longitude,
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

  /// Đồng bộ tài liệu từ Supabase Cloud về thư viện máy tương ứng với tài khoản hiện tại,
  /// đồng thời cách ly các tài liệu riêng tư của tài khoản khác trên máy.
  Future<void> syncDocumentsForCurrentAccount() async {
    if (_isSyncingDocs) return;
    if (!isConfigured) return;
    if (!_isInitialized) {
      final ok = await initialize();
      if (!ok) return;
    }

    final myEmail = _currentEmail;
    if (myEmail.isEmpty) return;

    _isSyncingDocs = true;
    _isLoading = true;

    try {
      // 1. Lấy tất cả tài liệu thuộc sở hữu của myEmail trên Supabase
      final myDocsRes = await client!
          .from('documents')
          .select()
          .eq('owner_email', myEmail);
      final myCloudDocs = (myDocsRes as List? ?? []);

      // 2. Lấy tất cả tài liệu được chia sẻ cho myEmail (từ Supabase Cloud)
      List<dynamic> cloudSharesList = [];
      try {
        final sharesRes = await client!
            .from('document_shares')
            .select('document_id, permission, shared_by_email')
            .eq('shared_with_email', myEmail);
        cloudSharesList = (sharesRes as List? ?? []);
      } catch (shareFetchErr) {
        debugPrint('[SupabaseService] Query document_shares warning: $shareFetchErr');
      }

      // Hợp nhất danh sách được chia sẻ từ Cloud và từ bộ nhớ cục bộ
      final combinedSharesMap = <String, Map<String, String>>{};
      for (final s in cloudSharesList) {
        final docId = s['document_id'] as String?;
        if (docId != null && docId.isNotEmpty) {
          combinedSharesMap[docId] = {
            'permission': (s['permission'] as String? ?? 'view').trim().toLowerCase(),
            'shared_by': (s['shared_by_email'] as String? ?? '').trim().toLowerCase(),
          };
        }
      }
      for (final s in _localDocumentShares) {
        if ((s['shared_with_email'] as String? ?? '').trim().toLowerCase() == myEmail) {
          final docId = s['document_id'] as String?;
          if (docId != null && docId.isNotEmpty && !combinedSharesMap.containsKey(docId)) {
            combinedSharesMap[docId] = {
              'permission': (s['permission'] as String? ?? 'view').trim().toLowerCase(),
              'shared_by': (s['shared_by_email'] as String? ?? '').trim().toLowerCase(),
            };
          }
        }
      }

      final sharedDocIds = combinedSharesMap.keys.toSet();

      // Cập nhật ngay bộ nhớ cache quyền cho myEmail đối với tất cả tài liệu được chia sẻ
      for (final docId in sharedDocIds) {
        final shareInfo = combinedSharesMap[docId];
        final perm = shareInfo?['permission'] ?? 'view';
        final sharedBy = shareInfo?['shared_by'] ?? '';
        final cacheKey = _cacheKey(docId, myEmail);
        _accessInfoCache[cacheKey] = DocumentAccessInfo(
          isOwner: false,
          ownerEmail: sharedBy.isNotEmpty ? sharedBy : 'Người chia sẻ',
          permission: perm,
          canEdit: perm == 'edit',
          canShare: false,
        );
      }

      // Nạp thông tin chi tiết các tài liệu được chia sẻ từ Cloud nếu chưa có đầy đủ
      List<dynamic> sharedCloudDocs = [];
      if (sharedDocIds.isNotEmpty) {
        try {
          final sharedDocsRes = await client!
              .from('documents')
              .select()
              .inFilter('id', sharedDocIds.toList());
          sharedCloudDocs = (sharedDocsRes as List? ?? []);
        } catch (e) {
          debugPrint('[SupabaseService] Lỗi nạp tài liệu được chia sẻ: $e');
        }
      }

      // Tập hợp danh sách ID tài liệu hợp lệ của myEmail (cả sở hữu và được chia sẻ)
      final myOwnedDocIds = myCloudDocs.map((d) => d['id'] as String).toSet();
      final allowedDocIds = {...myOwnedDocIds, ...sharedDocIds};

      final subjects = await database.select(database.subjects).get();
      final defaultSubjectPk = subjects.isNotEmpty ? subjects.first.subjectPk : 'sub-mob-002';
      final subjectMap = {for (var s in subjects) s.subjectPk: s.name};

      // 2.5. ĐỒNG BỘ 2 CHIỀU (TWO-WAY SYNC): Đẩy các tài liệu cục bộ chưa có trên Cloud lên Supabase
      final localDocs = await database.select(database.documents).get();
      for (final localDoc in localDocs) {
        if (!allowedDocIds.contains(localDoc.documentPk)) {
          // KIỂM TRA CHỦ SỞ HỮU GỐC: Nếu tài liệu này do tài khoản khác tạo trên máy,
          // TUYỆT ĐỐI KHÔNG upload lên Cloud dưới danh nghĩa tài khoản hiện tại!
          final docCreator = getDocumentCreator(localDoc);
          if (docCreator != null && docCreator.isNotEmpty && docCreator != myEmail) {
            continue;
          }

          Uint8List? fileBytes;
          if (localDoc.filePath != null && localDoc.filePath!.isNotEmpty) {
            try {
              final f = File(localDoc.filePath!);
              if (await f.exists()) {
                fileBytes = await f.readAsBytes();
              }
            } catch (_) {}
          }
          if (fileBytes == null && localDoc.url != null && localDoc.url!.startsWith('data:')) {
            try {
              final commaIdx = localDoc.url!.indexOf(',');
              if (commaIdx != -1) {
                fileBytes = base64Decode(localDoc.url!.substring(commaIdx + 1));
              }
            } catch (_) {}
          }

          final uploaded = await uploadAndSaveDocument(
            documentPk: localDoc.documentPk,
            name: localDoc.name,
            subjectName: subjectMap[localDoc.subjectFk] ?? 'Môn học',
            bytes: fileBytes,
            downloadUrl: localDoc.url,
            fileName: localDoc.name.endsWith('.pdf') || localDoc.name.endsWith('.docx')
                ? localDoc.name
                : '${localDoc.name}.pdf',
            mimeType: localDoc.type == DocumentType.pdf
                ? 'application/pdf'
                : 'application/octet-stream',
            category: localDoc.category.index,
            note: localDoc.note,
            tags: localDoc.tags,
            isPhysical: localDoc.isPhysical,
            isAvailableForBorrow: localDoc.isAvailableForBorrow,
            physicalLocation: localDoc.physicalLocation,
            address: localDoc.address,
            latitude: localDoc.latitude,
            longitude: localDoc.longitude,
            notify: false,
          );

          if (uploaded != null) {
            myOwnedDocIds.add(localDoc.documentPk);
            allowedDocIds.add(localDoc.documentPk);
            _localDocOwnerEmails[localDoc.documentPk] = myEmail;
            if (uploaded.downloadUrl != null && uploaded.downloadUrl != localDoc.url) {
              await database.documentDao.updateDocumentUrl(
                localDoc.documentPk,
                uploaded.downloadUrl!,
              );
            }
            debugPrint('[TwoWaySync] Đã tự động đẩy tài liệu cục bộ "${localDoc.name}" lên Cloud Supabase thành công!');
          }
        }
      }

      // 3. ĐỒNG BỘ CẢ TÀI LIỆU CỦA MYEMAIL VÀ TÀI LIỆU ĐƯỢC CHIA SẺ VÀO SQLITE
      final allCloudDocsToImport = [...myCloudDocs, ...sharedCloudDocs];

      for (final docJson in allCloudDocsToImport) {
        final docId = docJson['id'] as String;
        final isSharedDoc = sharedDocIds.contains(docId) && !myOwnedDocIds.contains(docId);
        final String docOwner;
        final rawOwner = docJson['owner_email'] as String?;
        if (rawOwner != null && rawOwner.trim().isNotEmpty) {
          docOwner = rawOwner.trim().toLowerCase();
        } else if (isSharedDoc && combinedSharesMap[docId]?['shared_by']?.isNotEmpty == true) {
          docOwner = combinedSharesMap[docId]!['shared_by']!.trim().toLowerCase();
        } else {
          docOwner = myEmail;
        }

        _localDocOwnerEmails[docId] = docOwner;

        // Nếu là tài liệu của chính mình, cache quyền owner
        if (!isSharedDoc) {
          final cacheKey = _cacheKey(docId, myEmail);
          _accessInfoCache[cacheKey] = DocumentAccessInfo(
            isOwner: true,
            ownerEmail: myEmail,
            permission: 'owner',
            canEdit: true,
            canShare: true,
          );
        }

        final docName = docJson['name'] as String? ?? 'Tài liệu';
        final subName = docJson['subject_name'] as String?;
        final fileName = docJson['file_name'] as String? ?? '';
        final mimeType = (docJson['mime_type'] as String? ?? '').toLowerCase();
        final storagePath = (docJson['storage_path'] as String? ?? '').toLowerCase();
        final downloadUrl = docJson['download_url'] as String?;
        final lowerUrl = (downloadUrl ?? '').toLowerCase();
        final rawNote = docJson['note'] as String?;
        final meta = extractMetadataFromNote(rawNote);
        final cleanNote = unpackCleanNote(rawNote);
        final catIdx = (docJson['category'] as int? ?? 0).clamp(0, 3);
        final fileSize = docJson['file_size'] as int? ?? 0;

        final docTags = (docJson['tags'] as String?)?.isNotEmpty == true
            ? docJson['tags'] as String
            : (meta['tags'] as String? ?? '');
        final docIsPhysical = (docJson['is_physical'] as bool?) ?? (meta['is_physical'] as bool? ?? false);
        final docIsBorrow = (docJson['is_available_for_borrow'] as bool?) ?? (meta['is_available_for_borrow'] as bool? ?? false);
        final docPhysicalLocation = (docJson['physical_location'] as String?) ?? meta['physical_location'] as String?;
        final docAddress = (docJson['address'] as String?) ?? meta['address'] as String?;
        final docLat = (docJson['latitude'] as num?)?.toDouble() ?? (meta['latitude'] as num?)?.toDouble();
        final docLng = (docJson['longitude'] as num?)?.toDouble() ?? (meta['longitude'] as num?)?.toDouble();

        // Đóng gói lại vào note cục bộ để bảo tồn thông tin chủ sở hữu và siêu dữ liệu
        final localPackedNote = packMetadataIntoNote(
          note: cleanNote.isNotEmpty ? cleanNote : null,
          tags: docTags,
          isPhysical: docIsPhysical,
          isAvailableForBorrow: docIsBorrow,
          physicalLocation: docPhysicalLocation,
          address: docAddress,
          latitude: docLat,
          longitude: docLng,
          ownerEmail: docOwner,
        );

        String targetSubPk = defaultSubjectPk;
        if (subName != null && subName.isNotEmpty) {
          final match = subjects.where((s) => s.name.toLowerCase() == subName.toLowerCase());
          if (match.isNotEmpty) targetSubPk = match.first.subjectPk;
        }

        // Tự động nhận diện chính xác định dạng tệp:
        final DocumentType detectedType;
        if (mimeType.contains('pdf') ||
            fileName.toLowerCase().endsWith('.pdf') ||
            storagePath.endsWith('.pdf') ||
            lowerUrl.contains('.pdf') ||
            docName.toLowerCase().endsWith('.pdf')) {
          detectedType = DocumentType.pdf;
        } else if (mimeType.contains('word') ||
            mimeType.contains('officedocument') ||
            fileName.toLowerCase().endsWith('.doc') ||
            fileName.toLowerCase().endsWith('.docx') ||
            storagePath.endsWith('.docx') ||
            docName.toLowerCase().endsWith('.doc') ||
            docName.toLowerCase().endsWith('.docx')) {
          detectedType = DocumentType.word;
        } else if (mimeType.contains('powerpoint') ||
            mimeType.contains('presentation') ||
            fileName.toLowerCase().endsWith('.ppt') ||
            fileName.toLowerCase().endsWith('.pptx') ||
            storagePath.endsWith('.pptx')) {
          detectedType = DocumentType.ppt;
        } else if (lowerUrl.startsWith('http') &&
            !lowerUrl.contains('supabase') &&
            !lowerUrl.contains('firebasestorage')) {
          detectedType = DocumentType.link;
        } else {
          detectedType = DocumentType.pdf;
        }

        // Bảo toàn filePath nếu tệp đã tồn tại sẵn trên máy
        final existingLocal = await (database.select(database.documents)
              ..where((d) => d.documentPk.equals(docId)))
            .getSingleOrNull();

        final companion = DocumentsCompanion(
          documentPk: drift.Value(docId),
          name: drift.Value(docName),
          subjectFk: drift.Value(targetSubPk),
          type: drift.Value(detectedType),
          category: drift.Value(DocumentCategory.values[catIdx]),
          filePath: existingLocal?.filePath != null ? drift.Value(existingLocal!.filePath) : const drift.Value.absent(),
          url: drift.Value(downloadUrl),
          fileSize: drift.Value(fileSize),
          note: drift.Value(localPackedNote),
          isPinned: drift.Value(existingLocal?.isPinned ?? false),
          tags: drift.Value(docTags),
          isPhysical: drift.Value(docIsPhysical),
          isAvailableForBorrow: drift.Value(docIsBorrow),
          physicalLocation: drift.Value(docPhysicalLocation),
          address: drift.Value(docAddress),
          latitude: drift.Value(docLat),
          longitude: drift.Value(docLng),
        );

        await database.documentDao.insertOrUpdateDocument(companion);
      }

      // 4. Cách ly dữ liệu: Cập nhật thông tin chủ sở hữu trong bộ nhớ cache
      // TUYỆT ĐỐI KHÔNG XÓA tài liệu khỏi SQLite cục bộ nhằm bảo vệ dữ liệu ngoại tuyến khi đổi tài khoản
      final remainingLocalDocs = await database.select(database.documents).get();
      final candidateDocIds = remainingLocalDocs
          .map((d) => d.documentPk)
          .where((id) => !allowedDocIds.contains(id))
          .toList();

      if (candidateDocIds.isNotEmpty) {
        try {
          final cloudDocsCheck = await client!
              .from('documents')
              .select('id, owner_email')
              .inFilter('id', candidateDocIds);

          for (final item in (cloudDocsCheck as List? ?? [])) {
            final docId = item['id'] as String;
            final cloudOwner = (item['owner_email'] as String? ?? '').trim().toLowerCase();
            final existingCreator = _localDocOwnerEmails[docId];
            if (existingCreator == null || existingCreator.isEmpty) {
              if (cloudOwner.isNotEmpty) {
                _localDocOwnerEmails[docId] = cloudOwner;
              }
            }
          }
        } catch (_) {}
      }

      await _saveDiskCache();
    } catch (e) {
      debugPrint('[SupabaseService] Lỗi syncDocumentsForCurrentAccount: $e');
    } finally {
      _isSyncingDocs = false;
      _isLoading = false;
      notifyListeners();
    }
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

    final myEmail = _currentEmail;
    final myUid = _currentUid;

    if (myEmail.isEmpty) {
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
      final docRes = await client!.from('documents').select('id, owner_email').eq('id', documentId).maybeSingle();
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
      } else {
        // Đảm bảo bảng documents ghi nhận đúng người chia sẻ là chủ sở hữu
        try {
          await client!.from('documents').update({
            'owner_email': myEmail,
            'owner_uid': myUid,
          }).eq('id', documentId);
        } catch (_) {}
      }

      // 1.5. Cập nhật quyền và lưu ngay vào bộ nhớ máy cho người nhận
      final shareUuid = uuid.v4();
      final localShareItem = {
        'id': shareUuid,
        'document_id': documentId,
        'shared_by_uid': myUid,
        'shared_by_email': myEmail,
        'shared_with_email': cleanRecipient,
        'permission': permission,
        'created_at': DateTime.now().toIso8601String(),
      };
      _localDocumentShares.removeWhere((s) =>
          s['document_id'] == documentId &&
          (s['shared_with_email'] as String? ?? '').toLowerCase() == cleanRecipient);
      _localDocumentShares.add(localShareItem);

      // Cập nhật ngay cache quyền truy cập cho người nhận
      final recipientCacheKey = _cacheKey(documentId, cleanRecipient);
      _accessInfoCache[recipientCacheKey] = DocumentAccessInfo(
        isOwner: false,
        ownerEmail: myEmail,
        permission: permission,
        canEdit: permission == 'edit',
        canShare: false,
      );

      // Cập nhật ngay quyền cho người chia sẻ là chủ sở hữu chính thức
      final cacheKey = _cacheKey(documentId, myEmail);
      _accessInfoCache[cacheKey] = DocumentAccessInfo(
        isOwner: true,
        ownerEmail: myEmail,
        permission: 'owner',
        canEdit: true,
        canShare: true,
      );
      await _saveDiskCache();

      // 2. Thêm quyền vào bảng `document_shares` trên Cloud
      try {
        await client!.from('document_shares').upsert(
          {
            'document_id': documentId,
            'shared_by_uid': myUid,
            'shared_by_email': myEmail,
            'shared_with_email': cleanRecipient,
            'permission': permission,
          },
          onConflict: 'document_id,shared_with_email',
        );
      } catch (cloudErr) {
        debugPrint('[SupabaseService] Thêm quyền vào document_shares Cloud warning: $cloudErr (đã lưu an toàn cục bộ)');
      }

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
    await _ensureDiskCacheLoaded();
    final result = <SupabaseDocumentShare>[];
    final seenEmails = <String>{};

    // 1. Lấy từ Cloud
    if (isConfigured && _isInitialized && client != null) {
      try {
        final res = await client!
            .from('document_shares')
            .select()
            .eq('document_id', documentId)
            .order('created_at', ascending: false);

        for (final item in (res as List)) {
          final share = SupabaseDocumentShare.fromJson(item as Map<String, dynamic>);
          result.add(share);
          seenEmails.add(share.sharedWithEmail.toLowerCase());
        }
      } catch (e) {
        debugPrint('[SupabaseService] Lỗi getDocumentShares từ Cloud: $e');
      }
    }

    // 2. Bổ sung từ _localDocumentShares nếu chưa có
    for (final s in _localDocumentShares) {
      if (s['document_id'] == documentId) {
        final withEmail = (s['shared_with_email'] as String? ?? '').toLowerCase();
        if (!seenEmails.contains(withEmail)) {
          result.add(SupabaseDocumentShare(
            id: s['id'] as String? ?? uuid.v4(),
            documentId: documentId,
            sharedByUid: s['shared_by_uid'] as String? ?? '',
            sharedByEmail: s['shared_by_email'] as String? ?? '',
            sharedWithEmail: withEmail,
            permission: s['permission'] as String? ?? 'view',
            createdAt: DateTime.tryParse(s['created_at'] as String? ?? '') ?? DateTime.now(),
          ));
          seenEmails.add(withEmail);
        }
      }
    }

    return result;
  }

  /// Thu hồi quyền chia sẻ của một người dùng
  Future<bool> revokeShare(String shareId) async {
    await _ensureDiskCacheLoaded();
    _isLoading = true;
    notifyListeners();

    try {
      _localDocumentShares.removeWhere((s) => s['id'] == shareId);
      await _saveDiskCache();

      if (isConfigured && _isInitialized && client != null) {
        try {
          await client!.from('document_shares').delete().eq('id', shareId);
        } catch (_) {}
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('[SupabaseService] Lỗi revokeShare: $e');
      _isLoading = false;
      _lastError = 'Lỗi thu hồi quyền chia sẻ: $e';
      notifyListeners();
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

    final myEmail = _currentEmail;
    if (myEmail.isEmpty) return [];

    await _ensureDiskCacheLoaded();

    try {
      List<dynamic> sharesList = [];
      try {
        final sharesRes = await client!
            .from('document_shares')
            .select('id, document_id, permission, shared_by_email')
            .eq('shared_with_email', myEmail);
        sharesList = (sharesRes as List? ?? []);
      } catch (cloudErr) {
        debugPrint('[SupabaseService] Query getDocumentsSharedWithMe Cloud warning: $cloudErr');
      }

      final docIds = sharesList.map((s) => s['document_id'] as String).toSet();
      final permissionMap = {
        for (var s in sharesList) s['document_id'] as String: s['permission'] as String? ?? 'view'
      };
      final sharerMap = {
        for (var s in sharesList)
          s['document_id'] as String: (s['shared_by_email'] as String? ?? '').trim().toLowerCase()
      };

      // Bổ sung từ _localDocumentShares
      for (final s in _localDocumentShares) {
        if ((s['shared_with_email'] as String? ?? '').trim().toLowerCase() == myEmail) {
          final docId = s['document_id'] as String;
          if (!permissionMap.containsKey(docId)) {
            permissionMap[docId] = s['permission'] as String? ?? 'view';
            sharerMap[docId] = (s['shared_by_email'] as String? ?? '').trim().toLowerCase();
            docIds.add(docId);
          }
        }
      }

      if (docIds.isEmpty) return [];

      // 2. Lấy thông tin các tài liệu từ bảng `documents`
      final docsRes = await client!
          .from('documents')
          .select()
          .inFilter('id', docIds.toList())
          .order('created_at', ascending: false);

      final docs = (docsRes as List).map((docJson) {
        final docId = docJson['id'] as String;
        final realSharer = sharerMap[docId] ?? '';
        final docObj = SupabaseDocument.fromJson(
          docJson as Map<String, dynamic>,
          sharePermission: permissionMap[docId],
          overrideOwnerEmail: realSharer.isNotEmpty ? realSharer : null,
        );

        final key = _cacheKey(docId, myEmail);
        _accessInfoCache[key] = DocumentAccessInfo(
          isOwner: false,
          ownerEmail: docObj.ownerEmail,
          permission: permissionMap[docId] ?? 'view',
          canEdit: permissionMap[docId] == 'edit',
          canShare: false,
        );

        return docObj;
      }).toList();

      _saveDiskCache();
      return docs;
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

  bool _isPurging = false;
  final Set<String> _purgedDocIds = {};

  /// Xoá tài liệu trên Supabase Cloud (Storage và Database)
  /// Cho phép chủ sở hữu (theo email, uid, local ownership) xoá tài liệu
  Future<bool> deleteCloudDocument(String documentId, {String? requesterEmail, bool notify = true}) async {
    if (!isConfigured) return false;
    if (!_isInitialized) {
      final ok = await initialize();
      if (!ok) return false;
    }

    final myEmail = (requesterEmail ?? _currentEmail).trim().toLowerCase();
    final myUid = _currentUid;

    try {
      // 1. Kiểm tra tài liệu và quyền sở hữu
      final docRes = await client!
          .from('documents')
          .select('owner_email, owner_uid, storage_path, note')
          .eq('id', documentId)
          .maybeSingle();

      if (docRes == null) {
        // Tài liệu không tồn tại trên Cloud (hoặc đã bị xoá trước đó)
        _accessInfoCache.remove(_cacheKey(documentId, myEmail));
        _accessInfoCache.remove(documentId);
        _localDocOwnerEmails.remove(documentId);
        _saveDiskCache();
        if (notify) notifyListeners();
        return true;
      }

      final docMeta = extractMetadataFromNote(docRes['note'] as String?);
      final rawOwner = (docRes['owner_email'] as String? ?? '').trim().toLowerCase();
      final metaOwner = (docMeta['owner_email'] as String? ?? '').trim().toLowerCase();
      final ownerEmail = rawOwner.isNotEmpty ? rawOwner : metaOwner;
      final ownerUid = (docRes['owner_uid'] as String? ?? '').trim();
      final localOwner = (_localDocOwnerEmails[documentId] ?? '').trim().toLowerCase();

      bool isAuthorized = false;
      if (myEmail.isNotEmpty && ownerEmail.isNotEmpty && ownerEmail == myEmail) {
        isAuthorized = true;
      } else if (myUid.isNotEmpty && ownerUid.isNotEmpty && ownerUid == myUid) {
        isAuthorized = true;
      } else if (myEmail.isNotEmpty && localOwner.isNotEmpty && localOwner == myEmail) {
        isAuthorized = true;
      } else if (ownerEmail.isEmpty && ownerUid.isEmpty) {
        isAuthorized = true;
      } else if (_localDocOwnerEmails.containsKey(documentId)) {
        isAuthorized = true;
      } else {
        if (myEmail.isNotEmpty) {
          final isSharer = await client!
              .from('document_shares')
              .select('id')
              .eq('document_id', documentId)
              .eq('shared_by_email', myEmail)
              .maybeSingle();
          if (isSharer != null) {
            isAuthorized = true;
          }
        }
      }

      if (!isAuthorized) {
        debugPrint('[SupabaseService] Từ chối xoá: $myEmail không phải chủ sở hữu của tài liệu $documentId (chủ: $ownerEmail)');
        _accessInfoCache.remove(_cacheKey(documentId, myEmail));
        _accessInfoCache.remove(documentId);
        _localDocOwnerEmails.remove(documentId);
        _saveDiskCache();
        return false;
      }

      // 2. Xoá các quan hệ phụ thuộc trước để tránh lỗi Foreign Key Constraint trên Postgres
      try {
        await client!.from('borrow_requests').delete().eq('document_id', documentId);
      } catch (brErr) {
        debugPrint('[SupabaseService] Bỏ qua lỗi xoá borrow_requests liên kết: $brErr');
      }

      try {
        await client!.from('document_shares').delete().eq('document_id', documentId);
      } catch (dsErr) {
        debugPrint('[SupabaseService] Bỏ qua lỗi xoá document_shares liên kết: $dsErr');
      }

      // 3. Xoá tệp trong Supabase Storage
      final storagePath = docRes['storage_path'] as String?;
      if (storagePath != null && storagePath.isNotEmpty) {
        try {
          await client!.storage
              .from(SupabaseConfig.storageBucketName)
              .remove([storagePath]);
          debugPrint('[SupabaseService] Đã xoá file trong Storage: $storagePath');
        } catch (storageErr) {
          debugPrint('[SupabaseService] Lỗi xoá file trong Storage: $storageErr');
        }
      }

      // 4. Xoá bản ghi trong bảng `documents`
      await client!.from('documents').delete().eq('id', documentId);
      debugPrint('[SupabaseService] Đã xoá bản ghi tài liệu $documentId trên Supabase Database');

      // 5. Dọn dẹp cache
      _accessInfoCache.remove(_cacheKey(documentId, myEmail));
      _accessInfoCache.remove(documentId);
      _localDocOwnerEmails.remove(documentId);
      _localBorrowRequests.removeWhere((r) => r.documentId == documentId);
      _localDocumentShares.removeWhere((s) => s['document_id'] == documentId);
      _saveDiskCache();
      if (notify) notifyListeners();
      return true;
    } catch (e) {
      debugPrint('[SupabaseService] Lỗi deleteCloudDocument: $e');
      return false;
    }
  }

  /// Quét bảng Tombstone (deleteLogs) của máy và tự động dọn dẹp các tài liệu đã xoá còn sót trên Cloud
  Future<void> purgeDeletedDocumentsFromCloud() async {
    if (!isConfigured || _isPurging) return;
    _isPurging = true;

    try {
      final deletedPks = await database.documentDao.getDeletedDocumentPks();
      final toPurge = deletedPks.difference(_purgedDocIds);
      if (toPurge.isEmpty) return;

      bool anyPurged = false;
      for (final pk in toPurge) {
        _purgedDocIds.add(pk);
        final ok = await deleteCloudDocument(pk, notify: false);
        if (ok) anyPurged = true;
      }
      if (anyPurged) {
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[SupabaseService] Lỗi purgeDeletedDocumentsFromCloud: $e');
    } finally {
      _isPurging = false;
    }
  }

  // =========================================================================
  // 5. LUỒNG NGHIỆP VỤ MƯỢN TÀI LIỆU P2P (BORROW REQUESTS)
  // =========================================================================

  /// Gửi yêu cầu mượn tài liệu đến chủ sở hữu (hỗ trợ cả lưu cục bộ an toàn & đồng bộ Cloud)
  Future<bool> createBorrowRequest({
    required String documentId,
    required String documentName,
    required String ownerEmail,
    required String ownerUid,
    DateTime? dueDate,
    String? note,
  }) async {
    await _ensureDiskCacheLoaded();

    final myEmail = _currentEmail;
    final myUid = firebaseService.currentUser?.uid ?? myEmail.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    final myName = firebaseService.userDisplayName ?? myEmail.split('@').first;

    if (myEmail.isEmpty) {
      _lastError = 'Vui lòng đăng nhập để gửi yêu cầu mượn tài liệu.';
      return false;
    }

    final cleanOwnerEmail = ownerEmail.trim().toLowerCase();
    if (myEmail == cleanOwnerEmail) {
      _lastError = 'Bạn không thể mượn tài liệu của chính mình.';
      return false;
    }

    // Kiểm tra xem đã gửi yêu cầu mượn trước đó chưa (tránh spam gửi nhiều lần khi chủ chưa phản hồi)
    final existingPending = _localBorrowRequests.where((r) =>
        r.documentId == documentId &&
        r.borrowerEmail.toLowerCase() == myEmail &&
        (r.status.toLowerCase() == 'pending' || r.status.toLowerCase() == 'approved'));
    if (existingPending.isNotEmpty) {
      _lastError = 'Bạn đã gửi yêu cầu mượn cuốn sách này trước đó, đang chờ phản hồi từ chủ sách.';
      return false;
    }

    try {
      final requestId = uuid.v4();
      final now = DateTime.now();
      final finalOwnerUid = ownerUid.isNotEmpty ? ownerUid : cleanOwnerEmail.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');

      // 1. Tạo đối tượng và lưu ngay vào bộ nhớ máy để đảm bảo không bao giờ bị mất
      final localReq = SupabaseBorrowRequest(
        id: requestId,
        documentId: documentId,
        documentName: documentName,
        borrowerUid: myUid,
        borrowerEmail: myEmail,
        borrowerName: myName,
        ownerUid: finalOwnerUid,
        ownerEmail: cleanOwnerEmail,
        status: 'pending',
        borrowDate: now,
        dueDate: dueDate,
        note: note,
        createdAt: now,
      );

      _localBorrowRequests.insert(0, localReq);
      await _saveDiskCache();

      // 2. Thử đồng bộ lên Supabase Cloud nếu có mạng & đã cấu hình
      if (isConfigured) {
        if (!_isInitialized) {
          await initialize();
        }
        if (_isInitialized && client != null) {
          try {
            // Đảm bảo document có mặt trên Supabase Postgres để thoả mãn khoá ngoại
            final existingDoc = await client!
                .from('documents')
                .select('id')
                .eq('id', documentId)
                .maybeSingle()
                .timeout(const Duration(seconds: 4));

            if (existingDoc == null) {
              final localDoc = await database.documentDao.getDocument(documentId);
              await client!.from('documents').upsert({
                'id': documentId,
                'name': documentName,
                'owner_uid': finalOwnerUid,
                'owner_email': cleanOwnerEmail,
                'file_name': documentName,
                'is_physical': true,
                'is_available_for_borrow': true,
                'address': localDoc?.address,
                'physical_location': localDoc?.physicalLocation,
                'tags': localDoc?.tags ?? '',
                'category': localDoc?.category.index ?? 0,
              }).timeout(const Duration(seconds: 4));
            }

            final requestData = {
              'id': requestId,
              'document_id': documentId,
              'borrower_uid': myUid,
              'borrower_email': myEmail,
              'borrower_name': myName,
              'owner_uid': finalOwnerUid,
              'owner_email': cleanOwnerEmail,
              'status': 'pending',
              'borrow_date': now.toIso8601String(),
              'due_date': dueDate?.toIso8601String(),
              'note': note,
            };

            await client!.from('borrow_requests').insert(requestData).timeout(const Duration(seconds: 5));
            debugPrint('[SupabaseService] Đã gửi yêu cầu mượn lên Supabase Cloud thành công!');
          } catch (cloudErr) {
            debugPrint('[SupabaseService] Gửi yêu cầu mượn lên Supabase Cloud lỗi: $cloudErr (đã lưu an toàn trong thiết bị)');
          }
        }
      }

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('[SupabaseService] Lỗi createBorrowRequest: $e');
      _lastError = 'Lỗi gửi yêu cầu mượn: $e';
      return false;
    }
  }

  /// Lấy danh sách yêu cầu mượn mà tôi đã gửi đi
  Future<List<SupabaseBorrowRequest>> getMyBorrowRequests() async {
    await _ensureDiskCacheLoaded();
    final myEmail = _currentEmail;
    if (myEmail.isEmpty) return [];

    final localMatches = _localBorrowRequests
        .where((r) => r.borrowerEmail.toLowerCase() == myEmail)
        .toList();

    if (!isConfigured) return localMatches;
    if (!_isInitialized) {
      final ok = await initialize();
      if (!ok) return localMatches;
    }
    if (client == null) return localMatches;

    try {
      final res = await client!
          .from('borrow_requests')
          .select()
          .ilike('borrower_email', '%${myEmail.trim()}%')
          .order('created_at', ascending: false)
          .timeout(const Duration(seconds: 4));

      final cloudList = <SupabaseBorrowRequest>[];
      for (final item in (res as List)) {
        final doc = item['documents'] as Map<String, dynamic>?;
        String? docName = doc?['name'] as String?;
        String? physLoc = doc?['physical_location'] as String?;
        String? addr = doc?['address'] as String?;

        if (docName == null) {
          final docId = item['document_id'] as String?;
          if (docId != null) {
            try {
              final localDoc = await database.documentDao.getDocument(docId);
              docName = localDoc?.name;
              physLoc ??= localDoc?.physicalLocation;
              addr ??= localDoc?.address;
            } catch (_) {}
          }
        }

        cloudList.add(SupabaseBorrowRequest.fromJson(
          item as Map<String, dynamic>,
          documentName: docName,
          physicalLocation: physLoc,
          address: addr,
        ));
      }

      final seenIds = cloudList.map((c) => c.id).toSet();
      for (final l in localMatches) {
        if (!seenIds.contains(l.id)) {
          cloudList.add(l);
        }
      }
      debugPrint('[SupabaseService] getMyBorrowRequests: tìm thấy ${cloudList.length} yêu cầu từ $myEmail');
      return cloudList;
    } catch (e) {
      debugPrint('[SupabaseService] getMyBorrowRequests fallback sang local: $e');
      return localMatches;
    }
  }

  /// Lấy danh sách yêu cầu mượn gửi đến các tài liệu của tôi (Chủ sách)
  Future<List<SupabaseBorrowRequest>> getBorrowRequestsForMyDocuments() async {
    await _ensureDiskCacheLoaded();
    final myEmail = _currentEmail;
    if (myEmail.isEmpty) return [];

    final localMatches = _localBorrowRequests
        .where((r) => r.ownerEmail.toLowerCase() == myEmail)
        .toList();

    if (!isConfigured) return localMatches;
    if (!_isInitialized) {
      final ok = await initialize();
      if (!ok) return localMatches;
    }
    if (client == null) return localMatches;

    try {
      final res = await client!
          .from('borrow_requests')
          .select()
          .ilike('owner_email', '%${myEmail.trim()}%')
          .order('created_at', ascending: false)
          .timeout(const Duration(seconds: 4));

      final cloudList = <SupabaseBorrowRequest>[];
      for (final item in (res as List)) {
        final doc = item['documents'] as Map<String, dynamic>?;
        String? docName = doc?['name'] as String?;
        String? physLoc = doc?['physical_location'] as String?;
        String? addr = doc?['address'] as String?;

        if (docName == null) {
          final docId = item['document_id'] as String?;
          if (docId != null) {
            try {
              final localDoc = await database.documentDao.getDocument(docId);
              docName = localDoc?.name;
              physLoc ??= localDoc?.physicalLocation;
              addr ??= localDoc?.address;
            } catch (_) {}
          }
        }

        cloudList.add(SupabaseBorrowRequest.fromJson(
          item as Map<String, dynamic>,
          documentName: docName,
          physicalLocation: physLoc,
          address: addr,
        ));
      }

      final seenIds = cloudList.map((c) => c.id).toSet();
      for (final l in localMatches) {
        if (!seenIds.contains(l.id)) {
          cloudList.add(l);
        }
      }
      debugPrint('[SupabaseService] getBorrowRequestsForMyDocuments: tìm thấy ${cloudList.length} yêu cầu gửi đến $myEmail');
      return cloudList;
    } catch (e) {
      debugPrint('[SupabaseService] getBorrowRequestsForMyDocuments fallback sang local: $e');
      return localMatches;
    }
  }

  /// Cập nhật trạng thái yêu cầu mượn: 'approved', 'rejected', 'borrowed', 'returned'
  Future<bool> updateBorrowRequestStatus(String requestId, String newStatus) async {
    await _ensureDiskCacheLoaded();

    for (int i = 0; i < _localBorrowRequests.length; i++) {
      if (_localBorrowRequests[i].id == requestId) {
        final old = _localBorrowRequests[i];
        _localBorrowRequests[i] = SupabaseBorrowRequest(
          id: old.id,
          documentId: old.documentId,
          documentName: old.documentName,
          borrowerUid: old.borrowerUid,
          borrowerEmail: old.borrowerEmail,
          borrowerName: old.borrowerName,
          ownerUid: old.ownerUid,
          ownerEmail: old.ownerEmail,
          status: newStatus,
          borrowDate: old.borrowDate,
          dueDate: old.dueDate,
          returnedDate: newStatus == 'returned' ? DateTime.now() : old.returnedDate,
          note: old.note,
          createdAt: old.createdAt,
          physicalLocation: old.physicalLocation,
          address: old.address,
        );
        await _saveDiskCache();
        break;
      }
    }

    if (isConfigured && _isInitialized && client != null) {
      try {
        final updateData = <String, dynamic>{
          'status': newStatus,
        };
        if (newStatus == 'returned') {
          updateData['returned_date'] = DateTime.now().toIso8601String();
        }

        await client!.from('borrow_requests').update(updateData).eq('id', requestId).timeout(const Duration(seconds: 5));
      } catch (e) {
        debugPrint('[SupabaseService] Lỗi update status Supabase: $e');
      }
    }

    notifyListeners();
    return true;
  }

  /// Hủy bỏ yêu cầu mượn sách đã gửi
  Future<bool> cancelBorrowRequest(String requestId) async {
    await _ensureDiskCacheLoaded();
    _localBorrowRequests.removeWhere((r) => r.id == requestId);
    await _saveDiskCache();

    if (isConfigured && _isInitialized && client != null) {
      try {
        await client!.from('borrow_requests').delete().eq('id', requestId).timeout(const Duration(seconds: 5));
      } catch (e) {
        debugPrint('[SupabaseService] Lỗi cancelBorrowRequest Supabase: $e');
      }
    }

    notifyListeners();
    return true;
  }

  /// Lấy danh sách các tài liệu công khai có vị trí/cho mượn trên toàn hệ thống (tối ưu tốc độ & không tải download_url base64 nặng)
  Future<List<SupabaseDocument>> getPublicPhysicalDocuments() async {
    if (!isConfigured) return [];
    if (!_isInitialized) {
      final ok = await initialize();
      if (!ok) return [];
    }

    const docColumns =
        'id, name, subject_name, owner_uid, owner_email, file_name, file_size, mime_type, storage_path, category, note, created_at, updated_at, is_physical, is_available_for_borrow, tags, address, physical_location, latitude, longitude';

    try {
      dynamic res;
      try {
        res = await client!
            .from('documents')
            .select(docColumns)
            .or('is_physical.eq.true,is_available_for_borrow.eq.true')
            .timeout(const Duration(seconds: 4));
      } catch (postgrestErr) {
        debugPrint('[SupabaseService] Query with .or() failed ($postgrestErr), falling back to select all with timeout');
        res = await client!
            .from('documents')
            .select(docColumns)
            .timeout(const Duration(seconds: 4));
      }

      final list = (res as List)
          .map((item) => SupabaseDocument.fromJson(item as Map<String, dynamic>))
          .where((doc) => doc.isPhysical == true || doc.isAvailableForBorrow == true)
          .toList();

      list.sort((a, b) {
        if (a.createdAt != null && b.createdAt != null) {
          return b.createdAt!.compareTo(a.createdAt!);
        }
        return b.name.compareTo(a.name);
      });

      return list;
    } catch (e) {
      debugPrint('[SupabaseService] Lỗi getPublicPhysicalDocuments: $e');
      return [];
    }
  }
}

/// Instance tiện ích toàn cục
final supabaseService = SupabaseService();

