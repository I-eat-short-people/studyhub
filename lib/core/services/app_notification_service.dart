import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'auth_sync_service.dart';
import 'firebase_service.dart';
import 'supabase_service.dart';

enum NotificationType {
  borrowRequestNew,       // Yêu cầu mượn mới gửi đến chủ sách
  borrowRequestApproved,  // Yêu cầu mượn của tôi được duyệt (kèm vị trí lấy)
  borrowRequestRejected,  // Yêu cầu mượn bị từ chối
  borrowDueDateReminder,  // Nhắc nhở hạn trả sách
  documentSharedWithMe,   // Tài liệu mới được chia sẻ với tôi
}

class AppNotificationItem {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final DateTime createdAt;
  final String? requestId;
  final String? documentName;
  final String? location;
  final bool isRead;

  const AppNotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.createdAt,
    this.requestId,
    this.documentName,
    this.location,
    this.isRead = false,
  });
}

class AppNotificationService with ChangeNotifier {
  static final AppNotificationService _instance = AppNotificationService._internal();
  factory AppNotificationService() => _instance;
  AppNotificationService._internal();

  bool _isInitialized = false;
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<AppNotificationItem> _notifications = [];
  List<AppNotificationItem> get notifications => List.unmodifiable(_notifications);

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  final Set<String> _readIds = {};
  Timer? _pollingTimer;
  bool _isRefreshing = false;

  String get _currentEmail {
    final a = authSyncService.user?.email;
    if (a != null && a.trim().isNotEmpty) return a.trim().toLowerCase();
    final f = firebaseService.currentUser?.email ?? firebaseService.userEmail;
    if (f != null && f.trim().isNotEmpty) return f.trim().toLowerCase();
    return '';
  }

  /// Khởi tạo service, nạp lịch sử đã đọc và lắng nghe thay đổi
  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;

    await _loadReadIdsFromDisk();

    // Lắng nghe thay đổi tài khoản
    authSyncService.addListener(_onAuthStateChanged);
    firebaseService.addListener(_onAuthStateChanged);
    supabaseService.addListener(_onSupabaseChanged);

    // Polling định kỳ mỗi 20s để phát hiện yêu cầu mượn sách hoặc chia sẻ mới
    _pollingTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      refreshNotifications(silent: true);
    });

    await refreshNotifications();
  }

  void _onAuthStateChanged() {
    refreshNotifications(silent: true);
  }

  void _onSupabaseChanged() {
    refreshNotifications(silent: true);
  }

  Future<void> _loadReadIdsFromDisk() async {
    if (kIsWeb) return;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/studyhub_read_notifications.json');
      if (await file.exists()) {
        final content = await file.readAsString();
        final list = jsonDecode(content) as List;
        _readIds.addAll(list.map((e) => e.toString()));
      }
    } catch (e) {
      debugPrint('[AppNotificationService] Không thể đọc cache readIds: $e');
    }
  }

  Future<void> _saveReadIdsToDisk() async {
    if (kIsWeb) return;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/studyhub_read_notifications.json');
      await file.writeAsString(jsonEncode(_readIds.toList()));
    } catch (e) {
      debugPrint('[AppNotificationService] Không thể lưu cache readIds: $e');
    }
  }

  /// Tải và tổng hợp thông báo từ các luồng mượn sách & chia sẻ tài liệu Supabase
  Future<void> refreshNotifications({bool silent = false}) async {
    if (_isRefreshing) return;
    _isRefreshing = true;

    if (!silent) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      final myEmail = _currentEmail;
      if (myEmail.isEmpty) {
        _notifications = [];
        return;
      }

      final incoming = await supabaseService.getBorrowRequestsForMyDocuments();
      final outgoing = await supabaseService.getMyBorrowRequests();
      List<SupabaseDocument> sharedDocs = [];
      try {
        sharedDocs = await supabaseService.getDocumentsSharedWithMe();
      } catch (_) {}

      final List<AppNotificationItem> list = [];

      // 1. Thông báo yêu cầu mượn mới gửi đến sách của tôi
      for (final req in incoming) {
        if (req.status.toLowerCase() == 'pending') {
          list.add(AppNotificationItem(
            id: 'incoming_${req.id}',
            title: 'Yêu cầu mượn sách mới',
            body: '${req.borrowerName ?? req.borrowerEmail} muốn mượn sách "${req.documentName ?? 'Tài liệu'}"',
            type: NotificationType.borrowRequestNew,
            createdAt: req.createdAt ?? DateTime.now(),
            requestId: req.id,
            documentName: req.documentName,
            isRead: _readIds.contains('incoming_${req.id}'),
          ));
        }
      }

      // 2. Thông báo yêu cầu mượn của tôi đã được phản hồi (Duyệt / Từ chối / Hạn trả)
      for (final req in outgoing) {
        final status = req.status.toLowerCase();
        if (status == 'approved') {
          list.add(AppNotificationItem(
            id: 'outgoing_approved_${req.id}',
            title: 'Yêu cầu mượn được CHẤP THUẬN! 🎉',
            body: 'Chủ sách đã duyệt mượn "${req.documentName ?? 'Tài liệu'}". Bạn có thể đến lấy sách ngay.',
            type: NotificationType.borrowRequestApproved,
            createdAt: req.createdAt ?? DateTime.now(),
            requestId: req.id,
            documentName: req.documentName,
            isRead: _readIds.contains('outgoing_approved_${req.id}'),
          ));
        } else if (status == 'rejected') {
          list.add(AppNotificationItem(
            id: 'outgoing_rejected_${req.id}',
            title: 'Yêu cầu mượn bị từ chối',
            body: 'Yêu cầu mượn sách "${req.documentName ?? 'Tài liệu'}" đã bị từ chối bởi chủ sách.',
            type: NotificationType.borrowRequestRejected,
            createdAt: req.createdAt ?? DateTime.now(),
            requestId: req.id,
            documentName: req.documentName,
            isRead: _readIds.contains('outgoing_rejected_${req.id}'),
          ));
        }

        // Nhắc hẹn trả nếu hạn trả gần kề
        if ((status == 'approved' || status == 'borrowed') && req.dueDate != null) {
          final diff = req.dueDate!.difference(DateTime.now()).inDays;
          if (diff <= 1 && diff >= -5) {
            list.add(AppNotificationItem(
              id: 'outgoing_due_${req.id}',
              title: diff < 0 ? 'ĐÃ QUÁ HẠN TRẢ SÁCH!' : 'Nhắc nhở: Sắp đến hạn trả sách',
              body: 'Sách "${req.documentName ?? 'Tài liệu'}" có hạn trả vào ngày ${req.dueDate!.day}/${req.dueDate!.month}/${req.dueDate!.year}.',
              type: NotificationType.borrowDueDateReminder,
              createdAt: DateTime.now(),
              requestId: req.id,
              documentName: req.documentName,
              isRead: _readIds.contains('outgoing_due_${req.id}'),
            ));
          }
        }
      }

      // 3. Thông báo tài liệu mới được chia sẻ với tôi
      for (final doc in sharedDocs) {
        final sharer = doc.ownerEmail.isNotEmpty ? doc.ownerEmail : 'Thành viên StudyHub';
        list.add(AppNotificationItem(
          id: 'shared_${doc.id}',
          title: 'Tài liệu mới được chia sẻ 📄',
          body: '$sharer đã chia sẻ tài liệu "${doc.name}" với bạn.',
          type: NotificationType.documentSharedWithMe,
          createdAt: doc.createdAt ?? DateTime.now(),
          requestId: doc.id,
          documentName: doc.name,
          isRead: _readIds.contains('shared_${doc.id}'),
        ));
      }

      // Sắp xếp theo mới nhất
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _notifications = list;
    } catch (e) {
      debugPrint('[AppNotificationService] Lỗi nạp thông báo: $e');
    } finally {
      _isLoading = false;
      _isRefreshing = false;
      notifyListeners();
    }
  }

  void markAsRead(String id) {
    _readIds.add(id);
    _saveReadIdsToDisk();
    notifyListeners();
  }

  void markAllAsRead() {
    for (final n in _notifications) {
      _readIds.add(n.id);
    }
    _saveReadIdsToDisk();
    notifyListeners();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    authSyncService.removeListener(_onAuthStateChanged);
    firebaseService.removeListener(_onAuthStateChanged);
    supabaseService.removeListener(_onSupabaseChanged);
    super.dispose();
  }
}

final appNotificationService = AppNotificationService();

