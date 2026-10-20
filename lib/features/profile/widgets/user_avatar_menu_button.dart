import 'package:flutter/material.dart';
import '../../../core/services/auth_sync_service.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/widgets/google_sync_dialog.dart';
import 'user_preferences_dialog.dart';

/// Nút Avatar góc trên AppBar, bấm vào mở Menu 3 tùy chọn:
/// 1. Tài khoản (Google Sync / Đăng nhập)
/// 2. Sở thích (Tùy chỉnh tag AI Recommendation)
/// 3. Đăng xuất
class UserAvatarMenuButton extends StatelessWidget {
  const UserAvatarMenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: authSyncService,
      builder: (context, _) {
        final isLoggedIn = authSyncService.isLoggedIn;
        final user = authSyncService.user;

        return PopupMenuButton<String>(
          tooltip: 'Menu tài khoản & sở thích',
          offset: const Offset(0, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          onSelected: (value) async {
            if (value == 'account') {
              await GoogleSyncDialog.show(context);
              if (context.mounted &&
                  supabaseService.isConfigured &&
                  authSyncService.isLoggedIn) {
                await supabaseService.syncDocumentsForCurrentAccount();
              }
            } else if (value == 'preferences') {
              await UserPreferencesDialog.show(context);
            } else if (value == 'logout') {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18)),
                  title: const Text('Đăng xuất tài khoản?'),
                  content: const Text(
                      'Bạn có chắc chắn muốn đăng xuất khỏi StudyHub trên thiết bị này?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Hủy'),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Đăng xuất'),
                    ),
                  ],
                ),
              );

              if (confirmed == true) {
                await authSyncService.signOut();
                await firebaseService.signOut();
                await supabaseService.clearAccessCache();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã đăng xuất thành công')),
                  );
                }
              }
            }
          },
          itemBuilder: (context) => [
            // Header: Thông tin tài khoản
            PopupMenuItem<String>(
              enabled: false,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: const Color(0xFF3F51B5),
                    backgroundImage: user?.photoUrl != null
                        ? NetworkImage(user!.photoUrl!)
                        : null,
                    child: user?.photoUrl == null
                        ? Text(
                            (user?.displayName.isNotEmpty == true
                                    ? user!.displayName[0]
                                    : 'G')
                                .toUpperCase(),
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isLoggedIn
                              ? (user?.displayName ?? 'Người dùng')
                              : 'Khách (Chưa đăng nhập)',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Colors.black87),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (isLoggedIn && user?.email != null)
                          Text(
                            user!.email,
                            style: const TextStyle(
                                fontSize: 11, color: Colors.grey),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const PopupMenuDivider(),

            // 1. Tài khoản
            const PopupMenuItem<String>(
              value: 'account',
              child: Row(
                children: [
                  Icon(Icons.manage_accounts_rounded,
                      color: Color(0xFF3F51B5), size: 20),
                  SizedBox(width: 12),
                  Text('Tài khoản & Đồng bộ',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                ],
              ),
            ),

            // 2. Sở thích
            const PopupMenuItem<String>(
              value: 'preferences',
              child: Row(
                children: [
                  Icon(Icons.tune_rounded, color: Color(0xFFE91E63), size: 20),
                  SizedBox(width: 12),
                  Text('Sở thích & Tag gợi ý',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                ],
              ),
            ),

            // 3. Đăng xuất (chỉ hiện khi đã đăng nhập)
            if (isLoggedIn) ...[
              const PopupMenuDivider(),
              const PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
                    SizedBox(width: 12),
                    Text('Đăng xuất',
                        style: TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.w600,
                            fontSize: 14)),
                  ],
                ),
              ),
            ],
          ],
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF3F51B5),
              backgroundImage:
                  user?.photoUrl != null ? NetworkImage(user!.photoUrl!) : null,
              child: user?.photoUrl == null
                  ? (isLoggedIn
                      ? Text(
                          (user?.displayName.isNotEmpty == true
                                  ? user!.displayName[0]
                                  : 'U')
                              .toUpperCase(),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.person_rounded,
                          color: Colors.white,
                          size: 18,
                        ))
                  : null,
            ),
          ),
        );
      },
    );
  }
}
