import 'package:flutter/material.dart';
import '../../../core/database/app_database.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/services/auth_sync_service.dart';
import '../../../core/services/app_notification_service.dart';

class ShareDocumentDialog extends StatefulWidget {
  final Document document;

  const ShareDocumentDialog({
    super.key,
    required this.document,
  });

  @override
  State<ShareDocumentDialog> createState() => _ShareDocumentDialogState();
}

class _ShareDocumentDialogState extends State<ShareDocumentDialog> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _permission = 'view';
  bool _isSharing = false;
  bool _isLoadingShares = true;
  List<SupabaseDocumentShare> _existingShares = [];

  @override
  void initState() {
    super.initState();
    _loadExistingShares();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingShares() async {
    if (!supabaseService.isConfigured) {
      setState(() => _isLoadingShares = false);
      return;
    }
    setState(() => _isLoadingShares = true);
    final shares = await supabaseService.getDocumentShares(widget.document.documentPk);
    if (mounted) {
      setState(() {
        _existingShares = shares;
        _isLoadingShares = false;
      });
    }
  }

  Future<void> _handleShare() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    setState(() => _isSharing = true);

    final ok = await supabaseService.shareDocument(
      documentId: widget.document.documentPk,
      recipientEmail: email,
      permission: _permission,
    );

    setState(() => _isSharing = false);

    if (mounted) {
      if (ok) {
        _emailController.clear();
        appNotificationService.refreshNotifications();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF2E7D32),
            content: Text('Đã chia sẻ tài liệu thành công cho "$email"!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        _loadExistingShares();
      } else {
        final err = supabaseService.lastError ?? 'Xảy ra lỗi khi chia sẻ.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFC62828),
            content: Text('Chia sẻ thất bại: $err'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _handleRevoke(SupabaseDocumentShare share) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Thu hồi quyền truy cập?'),
        content: Text('Người dùng "${share.sharedWithEmail}" sẽ không thể truy cập tài liệu này nữa.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Huỷ')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFC62828)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Thu hồi'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await supabaseService.revokeShare(share.id);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã thu hồi quyền của "${share.sharedWithEmail}"'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        _loadExistingShares();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final myEmail = firebaseService.userEmail ?? authSyncService.user?.email ?? 'Chưa đăng nhập';

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3ECF8E).withValues(alpha: 0.15), // Supabase Green
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.share_rounded, color: Color(0xFF2E7D32), size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Chia sẻ tài liệu',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          widget.document.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant),
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
              const SizedBox(height: 12),

              // Nội dung có thể cuộn khi bàn phím ảo hiển thị
              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Cảnh báo nếu chưa cấu hình Supabase
                      if (!supabaseService.isConfigured) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.amber.shade700),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline_rounded, color: Colors.amber.shade900, size: 20),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'Chưa dán URL và Anon Key của Supabase vào lib/core/config/supabase_config.dart.',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Chủ sở hữu
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.person_pin_rounded, size: 18, color: Color(0xFF1976D2)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Người chia sẻ: $myEmail (Chủ sở hữu)',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Form nhập email chia sẻ
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                labelText: 'Nhập email người nhận',
                                hintText: 'vidu@gmail.com',
                                prefixIcon: const Icon(Icons.email_outlined),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Vui lòng nhập địa chỉ email';
                                }
                                if (!val.contains('@') || !val.contains('.')) {
                                  return 'Email không đúng định dạng';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 10),
                            // Tránh sọc vàng khi bàn phím nâng lên hoặc màn hình hẹp
                            Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              alignment: WrapAlignment.spaceBetween,
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                const Text(
                                  'Quyền hạn:',
                                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                ),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: SegmentedButton<String>(
                                    style: const ButtonStyle(
                                      visualDensity: VisualDensity.compact,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    segments: const [
                                      ButtonSegment(
                                        value: 'view',
                                        label: Text('Chỉ xem', style: TextStyle(fontSize: 12)),
                                        icon: Icon(Icons.visibility_rounded, size: 16),
                                      ),
                                      ButtonSegment(
                                        value: 'edit',
                                        label: Text('Được sửa', style: TextStyle(fontSize: 12)),
                                        icon: Icon(Icons.edit_note_rounded, size: 16),
                                      ),
                                    ],
                                    selected: {_permission},
                                    onSelectionChanged: (val) {
                                      setState(() => _permission = val.first);
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF2E7D32),
                                padding: const EdgeInsets.symmetric(vertical: 11),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: (_isSharing || !supabaseService.isConfigured) ? null : _handleShare,
                              icon: _isSharing
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Icon(Icons.person_add_alt_1_rounded, size: 18),
                              label: Text(_isSharing ? 'Đang chia sẻ...' : 'Thêm người nhận'),
                            ),
                          ],
                        ),
                      ),

                      const Divider(height: 24),

                      // Danh sách những người đang có quyền
                      const Text(
                        'Danh sách người đã được chia sẻ:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 8),

                      if (_isLoadingShares)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (_existingShares.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.group_outlined,
                                size: 36,
                                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Chưa có ai được chia sẻ tài liệu này.',
                                style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _existingShares.length,
                          separatorBuilder: (ctx, _) => const Divider(height: 1),
                          itemBuilder: (ctx, idx) {
                            final share = _existingShares[idx];
                            final isViewOnly = share.permission == 'view';

                            return ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(
                                radius: 16,
                                backgroundColor: theme.colorScheme.primaryContainer,
                                child: Text(
                                  share.sharedWithEmail.isNotEmpty ? share.sharedWithEmail[0].toUpperCase() : '?',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              ),
                              title: Text(
                                share.sharedWithEmail,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                              subtitle: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isViewOnly
                                          ? Colors.blue.withValues(alpha: 0.15)
                                          : Colors.orange.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      isViewOnly ? 'Chỉ xem' : 'Chỉnh sửa',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: isViewOnly ? Colors.blue.shade800 : Colors.orange.shade900,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.remove_circle_outline, color: Color(0xFFC62828), size: 18),
                                tooltip: 'Thu hồi quyền',
                                onPressed: () => _handleRevoke(share),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
