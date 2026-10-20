import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:io' show Platform;
import 'app_notification_service.dart';

/// Callback khi nhận được thông báo mới
typedef NotificationCallback = void Function(RemoteMessage message);

/// Dịch vụ quản lý Firebase Cloud Messaging (FCM)
/// Thiết kế an toàn đa nền tảng (Web, Android, iOS, fallback cho Desktop)
class FirebaseNotificationService with ChangeNotifier {
  static final FirebaseNotificationService _instance = FirebaseNotificationService._internal();
  factory FirebaseNotificationService() => _instance;
  FirebaseNotificationService._internal();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  final List<RemoteMessage> _receivedMessages = [];
  List<RemoteMessage> get receivedMessages => List.unmodifiable(_receivedMessages);

  NotificationCallback? onMessageReceived;

  /// Kiểm tra xem nền tảng hiện tại có hỗ trợ Firebase Messaging không
  bool get isSupported {
    if (kIsWeb) return true;
    try {
      return Platform.isAndroid || Platform.isIOS || Platform.isMacOS;
    } catch (_) {
      return false;
    }
  }

  /// Khởi tạo FCM, xin cấp quyền và lấy token
  Future<void> initialize() async {
    if (_isInitialized) return;
    if (!isSupported) {
      debugPrint('[FCM] Nền tảng hiện tại không hỗ trợ FCM trực tiếp (Desktop/Windows), chuyển sang chế độ in-app fallback.');
      return;
    }

    try {
      if (Firebase.apps.isEmpty) {
        debugPrint('[FCM] Firebase core chưa sẵn sàng, chờ khởi tạo.');
        return;
      }

      final messaging = FirebaseMessaging.instance;

      // 1. Xin quyền thông báo (đặc biệt quan trọng trên iOS, Android 13+ và Web)
      try {
        final settings = await messaging.requestPermission(
          alert: true,
          announcement: false,
          badge: true,
          carPlay: false,
          criticalAlert: false,
          provisional: false,
          sound: true,
        );
        debugPrint('[FCM] Quyền thông báo: ${settings.authorizationStatus}');
      } catch (permErr) {
        debugPrint('[FCM] Bỏ qua lỗi xin quyền thông báo: $permErr');
      }

      // 2. Lấy FCM Token
      try {
        _fcmToken = await messaging.getToken();
        debugPrint('[FCM] Token thiết bị: $_fcmToken');
      } catch (tokenErr) {
        debugPrint('[FCM] Không thể lấy FCM token (có thể thiếu cấu hình VAPID trên Web): $tokenErr');
      }

      // Lắng nghe token refresh
      messaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        notifyListeners();
      });

      // 3. Lắng nghe thông báo khi ứng dụng đang mở (Foreground)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('[FCM] Nhận thông báo Foreground: ${message.notification?.title} - ${message.notification?.body}');
        _receivedMessages.insert(0, message);
        onMessageReceived?.call(message);
        appNotificationService.refreshNotifications();
        notifyListeners();
      });

      // 4. Lắng nghe khi người dùng bấm vào thông báo mở ứng dụng từ Background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('[FCM] Người dùng mở app từ thông báo: ${message.data}');
        _receivedMessages.insert(0, message);
        appNotificationService.refreshNotifications();
        notifyListeners();
      });

      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('[FCM] Khởi tạo FCM gặp lỗi: $e');
    }
  }

  /// Đăng ký theo dõi chủ đề (Topic)
  Future<void> subscribeToTopic(String topic) async {
    if (!isSupported || !_isInitialized) return;
    try {
      if (!kIsWeb) {
        await FirebaseMessaging.instance.subscribeToTopic(topic);
        debugPrint('[FCM] Đã subscribe topic: $topic');
      }
    } catch (e) {
      debugPrint('[FCM] Lỗi subscribe topic: $e');
    }
  }

  /// Hủy đăng ký chủ đề
  Future<void> unsubscribeFromTopic(String topic) async {
    if (!isSupported || !_isInitialized) return;
    try {
      if (!kIsWeb) {
        await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
        debugPrint('[FCM] Đã unsubscribe topic: $topic');
      }
    } catch (e) {
      debugPrint('[FCM] Lỗi unsubscribe topic: $e');
    }
  }

  /// Thêm một tin nhắn giả lập / in-app event (Dùng cho desktop hoặc test)
  void simulateNotification({required String title, required String body, Map<String, dynamic>? data}) {
    // Lưu ý: Không khởi tạo RemoteMessage trực tiếp nếu constructor phức tạp, chỉ cần notify
    notifyListeners();
  }
}

final firebaseNotificationService = FirebaseNotificationService();
