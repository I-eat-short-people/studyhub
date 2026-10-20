import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/auth_sync_service.dart';
import '../services/firebase_service.dart';
import '../services/supabase_service.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';

class GoogleSyncDialog extends StatefulWidget {
  const GoogleSyncDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (ctx) => const GoogleSyncDialog(),
    );
  }

  @override
  State<GoogleSyncDialog> createState() => _GoogleSyncDialogState();
}

class _GoogleSyncDialogState extends State<GoogleSyncDialog> {

  @override
  void initState() {
    super.initState();
    authSyncService.addListener(_onAuthChange);
    firebaseService.addListener(_onAuthChange);
  }

  @override
  void dispose() {
    authSyncService.removeListener(_onAuthChange);
    firebaseService.removeListener(_onAuthChange);
    super.dispose();
  }

  void _onAuthChange() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final textLightColor = getColor(context, 'textLight');
    final isLoggedIn = authSyncService.isLoggedIn;
    final user = authSyncService.user;
    final isSyncing = authSyncService.isSyncing;
    final lastError = authSyncService.lastError;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: getColor(context, 'lightDarkAccent'),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Row
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4285F4).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.cloud_sync_rounded,
                      color: Color(0xFF4285F4),
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tài khoản & Đồng bộ',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Google Drive Cloud Sync',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF4285F4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Error banner if any
              if (lastError != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          lastError,
                          style: const TextStyle(fontSize: 12, color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
                if (lastError.contains('SHA-1') || lastError.contains('10')) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF57C00).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFF57C00).withValues(alpha: 0.4)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.vpn_key_rounded, size: 16, color: Color(0xFFE65100)),
                            SizedBox(width: 6),
                            Text(
                              'Mã SHA-1 của máy bạn (bắt buộc cho Firebase):',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFE65100),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const SelectableText(
                            'C8:7A:A5:3B:00:94:3A:81:7A:EF:0E:28:D9:04:D2:7D:DC:3F:D6:4A',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF263238),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                                  visualDensity: VisualDensity.compact,
                                  side: const BorderSide(color: Color(0xFFF57C00)),
                                ),
                                icon: const Icon(Icons.copy_rounded, size: 14, color: Color(0xFFE65100)),
                                label: const Text(
                                  'Sao chép SHA-1',
                                  style: TextStyle(fontSize: 11.5, color: Color(0xFFE65100), fontWeight: FontWeight.w700),
                                ),
                                onPressed: () {
                                  Clipboard.setData(const ClipboardData(
                                    text: 'C8:7A:A5:3B:00:94:3A:81:7A:EF:0E:28:D9:04:D2:7D:DC:3F:D6:4A',
                                  ));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Đã sao chép mã SHA-1 vào bộ nhớ tạm!'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
                if (lastError.contains('People API') || lastError.contains('people.googleapis.com')) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE65100).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE65100).withValues(alpha: 0.4)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.person_search_rounded, size: 18, color: Color(0xFFE65100)),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Cần kích hoạt Google People API (Bắt buộc cho Web):',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFBF360C),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Google Sign-In trên Web yêu cầu dịch vụ People API để lấy họ tên và ảnh đại diện tài khoản Google của bạn. Hãy bấm nút dưới đây để kích hoạt trên Google Cloud Console (hoàn toàn miễn phí):',
                          style: TextStyle(fontSize: 11.5, color: Color(0xFF37474F)),
                        ),
                        const SizedBox(height: 10),
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                            visualDensity: VisualDensity.compact,
                            backgroundColor: const Color(0xFFE65100),
                          ),
                          icon: const Icon(Icons.open_in_new_rounded, size: 14),
                          label: const Text(
                            'Bật Google People API (Dự án 749333059425)',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                          onPressed: () {
                            launchUrl(
                              Uri.parse('https://console.developers.google.com/apis/api/people.googleapis.com/overview?project=749333059425'),
                              mode: LaunchMode.externalApplication,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ] else if (lastError.contains('401') || lastError.contains('hết hạn') || lastError.contains('Cấp lại quyền')) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF6C00).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFEF6C00).withValues(alpha: 0.4)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.refresh_rounded, size: 18, color: Color(0xFFE65100)),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Làm mới phiên làm việc Google Drive (401)',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFE65100),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Mã truy cập Google Drive của tài khoản đã hết hạn hoặc cần cấp lại quyền sau khi chuyển tài khoản. Bấm nút dưới đây để làm mới:',
                          style: TextStyle(fontSize: 11, color: Color(0xFF37474F)),
                        ),
                        const SizedBox(height: 10),
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                            visualDensity: VisualDensity.compact,
                            backgroundColor: const Color(0xFFEF6C00),
                          ),
                          icon: isSyncing
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.sync_rounded, size: 16),
                          label: Text(
                            isSyncing ? 'Đang cấp lại quyền...' : 'Cấp lại quyền & Đồng bộ ngay',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                          onPressed: isSyncing
                              ? null
                              : () async {
                                  final ok = await authSyncService.reauthorizeDrive();
                                  if (context.mounted && ok) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Đồng bộ Google Drive thành công!')),
                                    );
                                  }
                                },
                        ),
                      ],
                    ),
                  ),
                ] else if (lastError.contains('Google Drive API') || (lastError.contains('403') && lastError.contains('drive'))) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1976D2).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF1976D2).withValues(alpha: 0.4)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.cloud_sync_rounded, size: 16, color: Color(0xFF1976D2)),
                            SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Kích hoạt Google Drive API (Chỉ 1 Click):',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0D47A1),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Dự án Google Cloud chưa bật Drive API. Bạn có thể bấm nút bên dưới để bật (miễn phí), hoặc sử dụng sao lưu lên Cloud Storage:',
                          style: TextStyle(fontSize: 11, color: Color(0xFF37474F)),
                        ),
                        const SizedBox(height: 8),
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                            visualDensity: VisualDensity.compact,
                            backgroundColor: const Color(0xFF1976D2),
                          ),
                          icon: const Icon(Icons.open_in_new_rounded, size: 14),
                          label: const Text(
                            'Bật Google Drive API trên Google Cloud',
                            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                          ),
                          onPressed: () {
                            launchUrl(
                              Uri.parse('https://console.cloud.google.com/apis/library/drive.googleapis.com?project=749333059425'),
                              mode: LaunchMode.externalApplication,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ],

              if (!isLoggedIn) ...[
                // Not logged in State
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: getColor(context, 'canvasContainer'),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: getColor(context, 'dividerColor'),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.offline_pin_rounded,
                          color: textLightColor, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Chưa đăng nhập. Toàn bộ tài liệu hiện đang được lưu an toàn tại bộ nhớ thiết bị của bạn.',
                          style: TextStyle(
                            fontSize: 13,
                            color: textLightColor,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Đăng nhập tài khoản Google thật để tự động sao lưu và đồng bộ CSDL tài liệu lên Google Drive. Nếu không đăng nhập, bạn vẫn dùng bình thường (Local-First).',
                  style: TextStyle(
                    fontSize: 13,
                    color: textLightColor,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                // Real Google Sign In Button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF1F1F1F),
                    elevation: 1,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: const BorderSide(color: Color(0xFFDADCE0)),
                    ),
                  ),
                  onPressed: isSyncing
                      ? null
                      : () async {
                          final success = await authSyncService.signInWithGoogle();
                          if (success) {
                            await supabaseService.clearAccessCache();
                            await supabaseService.syncDocumentsForCurrentAccount();
                          }
                          if (context.mounted && success) {
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Đăng nhập Google và đồng bộ tài liệu thành công!'),
                              ),
                            );
                          }
                        },
                  child: isSyncing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(2),
                                child: const Icon(
                                  Icons.g_mobiledata_rounded,
                                  color: Color(0xFF4285F4),
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Đăng nhập bằng Google',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF3C4043),
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ] else ...[
                // Logged in State
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: getColor(context, 'canvasContainer'),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: getColor(context, 'dividerColor'),
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: const Color(0xFF3F51B5),
                        backgroundImage: user?.photoUrl != null
                            ? NetworkImage(user!.photoUrl!)
                            : null,
                        child: user?.photoUrl == null
                            ? Text(
                                user?.displayName.substring(0, 1).toUpperCase() ?? 'G',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.displayName ?? '',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              user?.email ?? '',
                              style: TextStyle(
                                fontSize: 13,
                                color: textLightColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFF43A047),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        authSyncService.lastSyncTime != null
                            ? 'Google Drive: Đã đồng bộ lúc ${Formatters.formatDate(authSyncService.lastSyncTime!)}'
                            : 'Đang chuẩn bị đồng bộ...',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: textLightColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Trạng thái Tự động sao lưu đám mây tinh gọn
                const Row(
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFF43A047),
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Tự động sao lưu đám mây',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF1A73E8),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: isSyncing
                            ? null
                            : () async {
                                final ok = await authSyncService.syncNow();
                                if (context.mounted && ok) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Đồng bộ Google Drive thành công!'),
                                    ),
                                  );
                                }
                              },
                        icon: isSyncing
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.sync_rounded, size: 20),
                        label: Text(
                          isSyncing ? 'Đang đồng bộ...' : 'Đồng bộ ngay',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: getColor(context, 'expenseAmount'),
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        side: BorderSide(
                          color: getColor(context, 'expenseAmount').withValues(alpha: 0.5),
                        ),
                      ),
                      onPressed: () async {
                        await authSyncService.signOut();
                        await firebaseService.signOut();
                        await supabaseService.clearAccessCache();
                        if (context.mounted) {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Đã đăng xuất Google')),
                          );
                        }
                      },
                      icon: const Icon(Icons.logout_rounded, size: 18),
                      label: const Text(
                        'Đăng xuất',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class GoogleProfileAppBarButton extends StatelessWidget {
  const GoogleProfileAppBarButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: authSyncService,
      builder: (context, _) {
        final isLoggedIn = authSyncService.isLoggedIn;
        final user = authSyncService.user;

        return IconButton(
          icon: isLoggedIn
              ? CircleAvatar(
                  radius: 14,
                  backgroundColor: const Color(0xFF3F51B5),
                  backgroundImage: user?.photoUrl != null
                      ? NetworkImage(user!.photoUrl!)
                      : null,
                  child: user?.photoUrl == null
                      ? Text(
                          user?.displayName.substring(0, 1).toUpperCase() ?? 'G',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        )
                      : null,
                )
              : const Icon(Icons.account_circle_outlined, size: 26),
          tooltip: isLoggedIn
              ? 'Tài khoản: ${user?.displayName} (Google Drive Sync)'
              : 'Đăng nhập Google & Đồng bộ',
          onPressed: () async {
            await GoogleSyncDialog.show(context);
            if (context.mounted && supabaseService.isConfigured && authSyncService.isLoggedIn) {
              await supabaseService.syncDocumentsForCurrentAccount();
            }
          },
        );
      },
    );
  }
}
