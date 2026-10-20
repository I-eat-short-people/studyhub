import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import '../database/database_global.dart';

class GoogleUserProfile {
  final String email;
  final String displayName;
  final String? photoUrl;

  const GoogleUserProfile({
    required this.email,
    required this.displayName,
    this.photoUrl,
  });
}

class _GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  _GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _client.send(request..headers.addAll(_headers));
  }
}

class AuthSyncService extends ChangeNotifier {
  static final AuthSyncService _instance = AuthSyncService._internal();
  factory AuthSyncService() => _instance;
  AuthSyncService._internal() {
    _initGoogleSignIn();
  }

  static const String _googleClientId = '749333059425-h2ssnacgt3l0b8kai5kurq8p135gk6mh.apps.googleusercontent.com';

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb ? _googleClientId : null,
    serverClientId: kIsWeb ? null : _googleClientId,
    scopes: [
      'email',
      'profile',
      drive.DriveApi.driveAppdataScope,
      drive.DriveApi.driveFileScope,
    ],
  );

  GoogleSignInAccount? _googleAccount;
  GoogleUserProfile? _user;
  DateTime? _lastSyncTime;
  bool _isSyncing = false;
  String? _lastError;

  bool get isLoggedIn => _user != null;
  GoogleUserProfile? get user => _user;
  GoogleSignIn get googleSignIn => _googleSignIn;
  DateTime? get lastSyncTime => _lastSyncTime;
  bool get isSyncing => _isSyncing;
  String? get lastError => _lastError;

  void _initGoogleSignIn() {
    try {
      _googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount? account) {
        if (account?.email != _googleAccount?.email) {
          _lastError = null;
        }
        _googleAccount = account;
        if (account != null) {
          _user = GoogleUserProfile(
            email: account.email,
            displayName: account.displayName ?? account.email.split('@').first,
            photoUrl: account.photoUrl,
          );
        } else {
          _user = null;
        }
        notifyListeners();
      });

      // Thử tự động khôi phục phiên đăng nhập khi khởi động (cả mobile và web)
      _googleSignIn.signInSilently().catchError((e) {
        // Bỏ qua lỗi nếu chưa đăng nhập hoặc mạng không sẵn sàng
        return null;
      });
    } catch (e) {
      debugPrint('[AuthSyncService] Khởi tạo Google Sign In bỏ qua trên web/demo: $e');
    }
  }

  Future<bool> signInWithGoogle() async {
    _isSyncing = true;
    _lastError = null;
    notifyListeners();

    try {
      // Xoá cache token cũ nếu có trước khi đăng nhập để tránh dính token tài khoản trước
      try {
        if (_googleAccount != null) {
          await _googleAccount!.clearAuthCache();
        }
      } catch (_) {}

      final account = await _googleSignIn.signIn();
      if (account == null) {
        // User cancelled the sign-in modal
        _isSyncing = false;
        notifyListeners();
        return false;
      }

      _googleAccount = account;
      _user = GoogleUserProfile(
        email: account.email,
        displayName: account.displayName ?? account.email.split('@').first,
        photoUrl: account.photoUrl,
      );

      // Đảm bảo đã cấp quyền Google Drive scopes
      try {
        final hasScopes = await _googleSignIn.canAccessScopes([
          drive.DriveApi.driveAppdataScope,
          drive.DriveApi.driveFileScope,
        ]);
        if (!hasScopes) {
          await _googleSignIn.requestScopes([
            drive.DriveApi.driveAppdataScope,
            drive.DriveApi.driveFileScope,
          ]);
        }
      } catch (scopeErr) {
        debugPrint('[AuthSyncService] Scope verification warning: $scopeErr');
      }

      // Tích hợp Firebase Authentication: Liên kết tài khoản Google với Firebase
      try {
        final googleAuth = await account.authentication;
        if (googleAuth.idToken != null || googleAuth.accessToken != null) {
          final credential = GoogleAuthProvider.credential(
            accessToken: googleAuth.accessToken,
            idToken: googleAuth.idToken,
          );
          await FirebaseAuth.instance.signInWithCredential(credential);
        }
      } catch (fbErr) {
        debugPrint('[AuthSyncService] Firebase Auth link warning: $fbErr');
      }

      // Thực hiện đồng bộ Google Drive (nếu Drive API đã bật)
      try {
        await syncNow();
      } catch (driveErr) {
        debugPrint('[AuthSyncService] Initial drive sync skipped: $driveErr');
      }
      return true;
    } on PlatformException catch (pe) {
      if (pe.message?.contains('10') == true || pe.code.contains('10')) {
        _lastError = 'Lỗi ApiException 10 (DEVELOPER_ERROR): Chưa dán mã SHA-1 của thiết bị vào Firebase Console.';
      } else if (pe.code == 'network_error') {
        _lastError = 'Lỗi kết nối mạng: Vui lòng kiểm tra Wi-Fi / 4G của thiết bị.';
      } else {
        _lastError = 'Lỗi Google Sign-In (${pe.code}): ${pe.message ?? pe.toString()}';
      }
      _isSyncing = false;
      notifyListeners();
      return false;
    } catch (e) {
      _lastError = 'Lỗi kết nối tài khoản Google: $e';
      _isSyncing = false;
      notifyListeners();
      return false;
    }
  }

  void signInDemo({
    String email = 'sinhvien.studyhub@gmail.com',
    String displayName = 'Sinh Viên StudyHub',
  }) {
    _googleAccount = null;
    _user = GoogleUserProfile(
      email: email,
      displayName: displayName,
      photoUrl: null,
    );
    _lastError = null;
    _lastSyncTime = DateTime.now();
    _isSyncing = false;
    notifyListeners();
  }

  Future<void> signOut() async {
    try {
      if (_googleAccount != null) {
        await _googleAccount!.clearAuthCache();
      }
    } catch (_) {}
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    _googleAccount = null;
    _user = null;
    _lastSyncTime = null;
    _lastError = null;
    notifyListeners();
  }

  /// Cấp lại quyền Google Drive và xóa auth cache (dùng khi gặp lỗi 401 do token hết hạn)
  Future<bool> reauthorizeDrive() async {
    if (_googleAccount == null) {
      _lastError = 'Chưa đăng nhập tài khoản Google.';
      notifyListeners();
      return false;
    }
    _isSyncing = true;
    _lastError = null;
    notifyListeners();

    try {
      // 1. Xóa cache token hiện tại trên thiết bị
      try {
        await _googleAccount!.clearAuthCache();
      } catch (cacheErr) {
        debugPrint('[AuthSyncService] clearAuthCache warning: $cacheErr');
      }

      // 2. Yêu cầu cấp quyền Drive Scopes tương tác
      try {
        await _googleSignIn.requestScopes([
          drive.DriveApi.driveAppdataScope,
          drive.DriveApi.driveFileScope,
        ]);
      } catch (scopeErr) {
        debugPrint('[AuthSyncService] requestScopes warning: $scopeErr');
      }

      // 3. Tiến hành đồng bộ lại
      return await syncNow();
    } catch (e) {
      _lastError = 'Lỗi cấp lại quyền Google Drive: $e';
      _isSyncing = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> _performDriveSync(Map<String, String> authHeaders) async {
    final authClient = _GoogleAuthClient(authHeaders);
    final driveApi = drive.DriveApi(authClient);

    // 1. Export local SQLite data to structured JSON
    final localSubjects = await database.subjectDao.getAllSubjects();
    final localDocs = await database.select(database.documents).get();
    final localDeleteLogs = await database.select(database.deleteLogs).get();

    final backupPayload = {
      'version': 2,
      'appName': 'StudyHub',
      'exportDate': DateTime.now().toIso8601String(),
      'subjects': localSubjects
          .map((s) => {
                'subjectPk': s.subjectPk,
                'name': s.name,
                'code': s.code,
                'color': s.color,
                'icon': s.icon,
                'dateCreated': s.dateCreated.toIso8601String(),
                'dateTimeModified': s.dateTimeModified.toIso8601String(),
              })
          .toList(),
      'documents': localDocs
          .map((d) => {
                'documentPk': d.documentPk,
                'name': d.name,
                'subjectFk': d.subjectFk,
                'type': d.type.index,
                'category': d.category.index,
                'filePath': d.filePath,
                'url': d.url,
                'fileSize': d.fileSize,
                'note': d.note,
                'isPinned': d.isPinned,
                'dateCreated': d.dateCreated.toIso8601String(),
                'dateTimeModified': d.dateTimeModified.toIso8601String(),
              })
          .toList(),
      'deleteLogs': localDeleteLogs
          .map((l) => {
                'deleteLogPk': l.deleteLogPk,
                'entryPk': l.entryPk,
                'type': l.type.index,
                'dateTimeModified': l.dateTimeModified.toIso8601String(),
              })
          .toList(),
    };

    final jsonContent = jsonEncode(backupPayload);
    final bytes = utf8.encode(jsonContent);

    // 2. Query Google Drive for existing backup file
    const backupFileName = 'studyhub_backup.json';
    final fileList = await driveApi.files.list(
      q: "name = '$backupFileName' and trashed = false",
      spaces: 'drive',
      $fields: 'files(id, name, modifiedTime)',
    );

    final existingFiles = fileList.files ?? [];

    if (existingFiles.isNotEmpty) {
      // Update existing backup on Google Drive
      final existingFileId = existingFiles.first.id!;
      final media = drive.Media(
        Stream.value(bytes),
        bytes.length,
        contentType: 'application/json',
      );

      final updateFile = drive.File()
        ..name = backupFileName
        ..description = 'StudyHub Cashew Cloud Backup';

      await driveApi.files.update(
        updateFile,
        existingFileId,
        uploadMedia: media,
      );
    } else {
      // Create new backup file on Google Drive
      final media = drive.Media(
        Stream.value(bytes),
        bytes.length,
        contentType: 'application/json',
      );

      final newFile = drive.File()
        ..name = backupFileName
        ..description = 'StudyHub Cashew Cloud Backup';

      await driveApi.files.create(
        newFile,
        uploadMedia: media,
      );
    }
  }

  Future<bool> syncNow() async {
    if (_googleAccount == null) {
      _lastError = 'Chưa đăng nhập tài khoản Google';
      notifyListeners();
      return false;
    }

    _isSyncing = true;
    _lastError = null;
    notifyListeners();

    try {
      var authHeaders = await _googleAccount!.authHeaders;

      try {
        await _performDriveSync(authHeaders);
      } catch (firstErr) {
        final errStr = firstErr.toString();
        final is401 = (firstErr is drive.DetailedApiRequestError && firstErr.status == 401) ||
            errStr.contains('401') ||
            errStr.toLowerCase().contains('invalid authentication') ||
            errStr.toLowerCase().contains('unauthorized');

        if (is401) {
          debugPrint('[AuthSyncService] Lỗi 401 Unauthorized từ Google Drive. Đang xóa cache và làm mới access token...');
          try {
            await _googleAccount?.clearAuthCache();
          } catch (cacheErr) {
            debugPrint('[AuthSyncService] clearAuthCache warning: $cacheErr');
          }

          try {
            final hasScopes = await _googleSignIn.canAccessScopes([
              drive.DriveApi.driveAppdataScope,
              drive.DriveApi.driveFileScope,
            ]);
            if (!hasScopes) {
              await _googleSignIn.requestScopes([
                drive.DriveApi.driveAppdataScope,
                drive.DriveApi.driveFileScope,
              ]);
            }
          } catch (_) {}

          // Lấy lại token mới
          authHeaders = await _googleAccount!.authHeaders;
          // Thử lại lần thứ 2 với token mới
          await _performDriveSync(authHeaders);
        } else {
          rethrow;
        }
      }

      _lastSyncTime = DateTime.now();
      _isSyncing = false;
      _lastError = null;
      notifyListeners();
      return true;
    } catch (e) {
      final errStr = e.toString();
      if (errStr.contains('403') ||
          errStr.contains('Google Drive API has not been used') ||
          errStr.contains('disabled')) {
        _lastError =
            'Google Drive API chưa được bật trong dự án studyhubmob. Bạn có thể bấm nút "Bật Google Drive API" bên dưới hoặc sử dụng Firebase Storage để lưu trữ.';
      } else if (errStr.contains('401') ||
          (e is drive.DetailedApiRequestError && e.status == 401) ||
          errStr.toLowerCase().contains('unauthorized')) {
        _lastError =
            'Phiên đăng nhập Google Drive đã hết hạn (401). Vui lòng nhấn "Cấp lại quyền Drive" để làm mới.';
      } else {
        _lastError = 'Lỗi đồng bộ Google Drive: $e';
      }
      _isSyncing = false;
      notifyListeners();
      return false;
    }
  }
}

final authSyncService = AuthSyncService();
