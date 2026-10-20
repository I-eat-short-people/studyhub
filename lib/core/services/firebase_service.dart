import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../firebase_options.dart';
import '../database/database_global.dart';
import 'auth_sync_service.dart';

/// Kết quả sau khi upload tệp lên Firebase Cloud Storage
class FirebaseUploadResult {
  final String documentPk;
  final String fileName;
  final String downloadUrl;
  final String storagePath;
  final int sizeBytes;
  final DateTime uploadedAt;

  const FirebaseUploadResult({
    required this.documentPk,
    required this.fileName,
    required this.downloadUrl,
    required this.storagePath,
    required this.sizeBytes,
    required this.uploadedAt,
  });
}

/// Dịch vụ tích hợp Firebase Authentication (Google Sign-In) & Firebase Cloud Storage
class FirebaseService extends ChangeNotifier {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  bool _isInitialized = false;
  bool _isLoading = false;
  String? _lastError;
  User? _currentUser;
  StreamSubscription<User?>? _authSubscription;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  String? get lastError => _lastError;
  User? get currentUser => FirebaseAuth.instance.currentUser ?? _currentUser;
  bool get isLoggedIn => currentUser != null || authSyncService.isLoggedIn;
  String? get userDisplayName =>
      authSyncService.user?.displayName ??
      currentUser?.displayName ??
      authSyncService.user?.email.split('@').first ??
      currentUser?.email?.split('@').first;
  String? get userEmail => authSyncService.user?.email ?? currentUser?.email;
  String? get userPhotoUrl => authSyncService.user?.photoUrl ?? currentUser?.photoURL;
  String? get userId =>
      authSyncService.user != null
          ? authSyncService.user!.email.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')
          : currentUser?.uid;

  GoogleSignIn get _googleSignIn => authSyncService.googleSignIn;

  /// Khởi tạo Firebase an toàn cho ứng dụng StudyHub
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      _isInitialized = true;

      // Lắng nghe trạng thái đăng nhập Firebase Auth
      _authSubscription = FirebaseAuth.instance.authStateChanges().listen((User? user) {
        _currentUser = user;
        notifyListeners();
      });

      _currentUser = FirebaseAuth.instance.currentUser;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('[FirebaseService] Khởi tạo Firebase ở chế độ demo/fallback: $e');
      _isInitialized = false;
      _lastError = e.toString();
      notifyListeners();
      return false;
    }
  }

  // =========================================================================
  // 1. FIREBASE AUTHENTICATION VỚI GOOGLE
  // =========================================================================

  /// Đăng nhập tài khoản Google và liên kết với Firebase Auth
  Future<UserCredential?> signInWithGoogle() async {
    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      // 1. Khởi tạo Firebase nếu chưa khởi tạo
      if (!_isInitialized) {
        await initialize();
      }

      // 2. Kích hoạt giao diện chọn tài khoản Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // Người dùng nhấn huỷ hộp thoại đăng nhập
        _isLoading = false;
        notifyListeners();
        return null;
      }

      // 3. Lấy Authentication Tokens từ Google
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // 4. Tạo Firebase Credential từ ID Token & Access Token
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 5. Đăng nhập vào Firebase Authentication
      final UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      _currentUser = userCredential.user;
      _isLoading = false;
      _lastError = null;
      notifyListeners();
      return userCredential;
    } catch (e) {
      debugPrint('[FirebaseService] Lỗi signInWithGoogle: $e');
      _isLoading = false;
      _lastError = 'Đăng nhập Google thất bại: $e';
      notifyListeners();
      return null;
    }
  }

  /// Đăng xuất khỏi cả Firebase Authentication và Google Sign-In
  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      if (_isInitialized) {
        await FirebaseAuth.instance.signOut();
      }
      await _googleSignIn.signOut();
      _currentUser = null;
      _lastError = null;
    } catch (e) {
      _lastError = 'Lỗi đăng xuất: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // =========================================================================
  // 2. FIREBASE CLOUD STORAGE (LƯU TRỮ VÀ TẢI TÀI LIỆU)
  // =========================================================================

  /// Tải tệp tài liệu dạng bytes lên Firebase Storage
  /// Đường dẫn lưu trữ: users/{uid}/documents/{documentPk}/{fileName}
  Future<FirebaseUploadResult?> uploadDocumentBytes({
    required String documentPk,
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
    Map<String, String>? customMetadata,
  }) async {
    if (!isLoggedIn) {
      _lastError = 'Vui lòng đăng nhập trước khi tải lên Cloud Storage';
      notifyListeners();
      return null;
    }

    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      final uid = currentUser?.uid ?? userId ?? 'studyhub_user';
      final cleanFileName = fileName.replaceAll(RegExp(r'[^\w\.\-]'), '_');
      final storagePath = 'studyhub_users/$uid/documents/$documentPk/$cleanFileName';
      final storageRef = FirebaseStorage.instance.ref().child(storagePath);

      final metadata = SettableMetadata(
        contentType: mimeType,
        customMetadata: {
          'documentPk': documentPk,
          'fileName': cleanFileName,
          'uploadedBy': userEmail ?? uid,
          ...?customMetadata,
        },
      );

      // Upload task
      final uploadTask = storageRef.putData(bytes, metadata);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      final result = FirebaseUploadResult(
        documentPk: documentPk,
        fileName: fileName,
        downloadUrl: downloadUrl,
        storagePath: storagePath,
        sizeBytes: bytes.length,
        uploadedAt: DateTime.now(),
      );

      _isLoading = false;
      notifyListeners();
      return result;
    } on FirebaseException catch (fe) {
      debugPrint('[FirebaseService] FirebaseException [${fe.code}]: ${fe.message}');
      _isLoading = false;
      if (fe.code == 'permission-denied') {
        _lastError =
            'Firebase Storage từ chối quyền (permission-denied). Hãy mở Firebase Console -> Build -> Storage -> Rules và đổi sang: allow read, write: if request.auth != null; (hoặc if true; để test).';
      } else if (fe.code == 'unauthorized') {
        _lastError = 'Chưa được ủy quyền tải lên Firebase Storage (unauthorized).';
      } else if (fe.code == 'object-not-found') {
        _lastError = 'Không tìm thấy đường dẫn bucket Firebase Storage.';
      } else {
        _lastError = 'Lỗi Storage [${fe.code}]: ${fe.message}';
      }
      notifyListeners();
      return null;
    } catch (e) {
      debugPrint('[FirebaseService] Lỗi uploadDocumentBytes: $e');
      _isLoading = false;
      _lastError = 'Lỗi lưu trữ tệp lên Cloud: $e';
      notifyListeners();
      return null;
    }
  }

  /// Tải tệp tài liệu từ đường dẫn file trên máy lên Firebase Storage
  Future<FirebaseUploadResult?> uploadDocumentFromFile({
    required String documentPk,
    required String filePath,
    required String fileName,
    required String mimeType,
    Map<String, String>? customMetadata,
  }) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('Không tìm thấy tệp tin cục bộ tại: $filePath');
      }
      final bytes = await file.readAsBytes();
      return await uploadDocumentBytes(
        documentPk: documentPk,
        fileName: fileName,
        bytes: bytes,
        mimeType: mimeType,
        customMetadata: customMetadata,
      );
    } catch (e) {
      _lastError = 'Lỗi đọc tệp tải lên: $e';
      notifyListeners();
      return null;
    }
  }

  /// Tải dữ liệu nhị phân (bytes) của tài liệu từ Firebase Storage về máy
  Future<Uint8List?> downloadDocumentBytes(String storagePath) async {
    try {
      final ref = FirebaseStorage.instance.ref().child(storagePath);
      // Giới hạn tải tối đa 50MB cho tài liệu học tập
      const maxDownloadSize = 50 * 1024 * 1024;
      return await ref.getData(maxDownloadSize);
    } catch (e) {
      debugPrint('[FirebaseService] Lỗi downloadDocumentBytes: $e');
      _lastError = 'Lỗi tải tệp từ Cloud: $e';
      notifyListeners();
      return null;
    }
  }

  /// Xoá tệp tài liệu khỏi Firebase Cloud Storage
  Future<bool> deleteDocumentFromStorage(String storagePath) async {
    try {
      final ref = FirebaseStorage.instance.ref().child(storagePath);
      await ref.delete();
      return true;
    } catch (e) {
      debugPrint('[FirebaseService] Lỗi deleteDocumentFromStorage: $e');
      return false;
    }
  }

  /// Đồng bộ sao lưu tài liệu cục bộ lên Firebase Storage
  Future<int> backupAllLocalDocumentsToFirebase({
    Function(int current, int total)? onProgress,
  }) async {
    if (!isLoggedIn) {
      _lastError = 'Bạn chưa đăng nhập Google. Vui lòng đăng nhập trước khi sao lưu!';
      notifyListeners();
      return 0;
    }

    _isLoading = true;
    _lastError = null;
    notifyListeners();

    int successCount = 0;
    try {
      final docs = await database.select(database.documents).get();
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
              debugPrint('[FirebaseService] Không thể đọc filePath: $err');
            }
          }
        }

        // 2. Dự phòng: Trích xuất từ doc.url nếu lưu dạng Base64 Data URI
        if (fileBytes == null && doc.url != null && doc.url!.startsWith('data:')) {
          try {
            final commaIdx = doc.url!.indexOf(',');
            if (commaIdx != -1) {
              final base64Str = doc.url!.substring(commaIdx + 1);
              fileBytes = base64Decode(base64Str);
            }
          } catch (err) {
            debugPrint('[FirebaseService] Không thể giải mã base64: $err');
          }
        }

        if (fileBytes != null && fileBytes.isNotEmpty) {
          processedCount++;
          final res = await uploadDocumentBytes(
            documentPk: doc.documentPk,
            fileName: doc.name,
            bytes: fileBytes,
            mimeType: mimeType,
            customMetadata: {'subjectFk': doc.subjectFk},
          );

          if (res != null) {
            successCount++;
          }
        } else {
          debugPrint('[FirebaseService] Tài liệu "${doc.name}" không có tệp nội dung nhị phân (chỉ có link hoặc file không tồn tại).');
        }

        if (onProgress != null) {
          onProgress(i + 1, docs.length);
        }
      }

      if (processedCount == 0) {
        _lastError = 'Các tài liệu trong thư viện không có tệp đính kèm trên máy để tải lên.';
      }
    } catch (e) {
      _lastError = 'Lỗi sao lưu tài liệu: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }

    return successCount;
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}

/// Instance toàn cục tiện dụng
final firebaseService = FirebaseService();
