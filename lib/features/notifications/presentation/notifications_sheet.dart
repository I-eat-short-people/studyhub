import 'package:flutter/material.dart';
import '../../../core/services/app_notification_service.dart';

/// Nút Chuông Thông Báo trên AppBar kèm Badge số lượng thông báo
class NotificationBellButton extends StatefulWidget {
  final Function(int targetTab, int? subTab)? onNavigateToTab;

  const NotificationBellButton({super.key, this.onNavigateToTab});

  @override
  State<NotificationBellButton> createState() => _NotificationBellButtonState();
}

class _NotificationBellButtonState extends State<NotificationBellButton> {
  @override
  void initState() {
    super.initState();
    appNotificationService.addListener(_refresh);
    appNotificationService.refreshNotifications();
  }

  @override
  void dispose() {
    appNotificationService.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  void _showNotificationsSheet() {
    appNotificationService.refreshNotifications();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => NotificationsSheet(
        onNavigateToTab: widget.onNavigateToTab,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appNotificationService,
      builder: (context, _) {
        final unread = appNotificationService.unreadCount;

        return IconButton(
          tooltip: 'Thông báo mượn & trả sách',
          onPressed: _showNotificationsSheet,
          icon: Badge(
            isLabelVisible: unread > 0,
            label: Text('$unread', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
            backgroundColor: Colors.redAccent,
            child: const Icon(Icons.notifications_outlined, size: 24),
          ),
        );
      },
    );
  }
}

/// Giao diện danh sách thông báo
class NotificationsSheet extends StatelessWidget {
  final Function(int targetTab, int? subTab)? onNavigateToTab;

  const NotificationsSheet({super.key, this.onNavigateToTab});

  Color _getIconBgColor(NotificationType type) {
    switch (type) {
      case NotificationType.borrowRequestApproved:
        return const Color(0xFF43A047).withValues(alpha: 0.15);
      case NotificationType.borrowRequestRejected:
        return Colors.redAccent.withValues(alpha: 0.15);
      case NotificationType.borrowDueDateReminder:
        return Colors.amber.withValues(alpha: 0.2);
      case NotificationType.borrowRequestNew:
        return const Color(0xFF3F51B5).withValues(alpha: 0.15);
      case NotificationType.documentSharedWithMe:
        return const Color(0xFF00897B).withValues(alpha: 0.15);
    }
  }

  IconData _getIconData(NotificationType type) {
    switch (type) {
      case NotificationType.borrowRequestApproved:
        return Icons.check_circle_rounded;
      case NotificationType.borrowRequestRejected:
        return Icons.cancel_rounded;
      case NotificationType.borrowDueDateReminder:
        return Icons.alarm_rounded;
      case NotificationType.borrowRequestNew:
        return Icons.mark_email_unread_rounded;
      case NotificationType.documentSharedWithMe:
        return Icons.folder_shared_rounded;
    }
  }

  Color _getIconColor(NotificationType type) {
    switch (type) {
      case NotificationType.borrowRequestApproved:
        return const Color(0xFF43A047);
      case NotificationType.borrowRequestRejected:
        return Colors.redAccent;
      case NotificationType.borrowDueDateReminder:
        return Colors.amber.shade900;
      case NotificationType.borrowRequestNew:
        return const Color(0xFF3F51B5);
      case NotificationType.documentSharedWithMe:
        return const Color(0xFF00897B);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appNotificationService,
      builder: (context, _) {
        final notifs = appNotificationService.notifications;
        final isLoading = appNotificationService.isLoading;

        return ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Sheet handle
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 16, 10),
                child: Row(
                  children: [
                    const Icon(Icons.notifications_active_rounded, color: Color(0xFF3F51B5)),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Thông Báo',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Làm mới',
                      icon: const Icon(Icons.refresh_rounded, size: 20),
                      onPressed: () => appNotificationService.refreshNotifications(),
                    ),
                    if (notifs.isNotEmpty)
                      TextButton(
                        onPressed: () {
                          appNotificationService.markAllAsRead();
                        },
                        child: const Text('Đọc tất cả', style: TextStyle(fontSize: 12)),
                      ),
                  ],
                ),
              ),

              if (isLoading)
                const LinearProgressIndicator(minHeight: 2)
              else
                const Divider(height: 1),

              // Content
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => appNotificationService.refreshNotifications(),
                  child: notifs.isEmpty
                      ? ListView(
                          children: [
                            SizedBox(height: MediaQuery.of(context).size.height * 0.18),
                            Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.notifications_none_rounded,
                                      size: 56, color: Colors.grey.withValues(alpha: 0.4)),
                                  const SizedBox(height: 10),
                                  const Text(
                                    'Chưa có thông báo nào',
                                    style: TextStyle(color: Colors.grey, fontSize: 14),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Kéo xuống để cập nhật thông báo mới nhất',
                                    style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          itemCount: notifs.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final item = notifs[index];
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              leading: Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: _getIconBgColor(item.type),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(_getIconData(item.type), color: _getIconColor(item.type), size: 22),
                              ),
                              title: Text(
                                item.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: item.isRead ? FontWeight.w500 : FontWeight.bold,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  item.body,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700),
                                ),
                              ),
                              trailing: !item.isRead
                                  ? Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: Colors.redAccent,
                                        shape: BoxShape.circle,
                                      ),
                                    )
                                  : null,
                              onTap: () {
                                appNotificationService.markAsRead(item.id);
                                Navigator.pop(context);

                                // Chuyển hướng tab phù hợp
                                if (item.type == NotificationType.borrowRequestNew) {
                                  onNavigateToTab?.call(1, 1); // Tab Quản lý mượn -> Yêu cầu đã nhận
                                } else if (item.type == NotificationType.documentSharedWithMe) {
                                  onNavigateToTab?.call(0, 0); // Tab Tài liệu
                                } else {
                                  onNavigateToTab?.call(1, 0); // Tab Quản lý mượn -> Yêu cầu đã gửi
                                }
                              },
                            );
                          },
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
