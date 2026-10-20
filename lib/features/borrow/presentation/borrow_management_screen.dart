import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/app_notification_service.dart';
import '../../../core/services/auth_sync_service.dart';

class BorrowManagementScreen extends StatefulWidget {
  final int initialSubTab;
  final bool showAppBar;

  const BorrowManagementScreen({
    super.key,
    this.initialSubTab = 0,
    this.showAppBar = false,
  });

  @override
  State<BorrowManagementScreen> createState() => _BorrowManagementScreenState();
}

class _BorrowManagementScreenState extends State<BorrowManagementScreen>
 // ============================================================================
   // MODULE QUẢN LÝ MƯỢN TRẢ TÀI LIỆU (BORROW MANAGEMENT)
   // - Xử lý 2 luồng: Yêu cầu tôi gửi đi (Outgoing) và Yêu cầu tôi nhận được (Incoming)
   // - Tự động đồng bộ trạng thái: PENDING -> ACCEPTED / REJECTED -> RETURNED
   // ============================================================================
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<SupabaseBorrowRequest> _outgoingRequests = [];
  List<SupabaseBorrowRequest> _incomingRequests = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialSubTab.clamp(0, 1),
    );
    authSyncService.addListener(_onServiceChanged);
    supabaseService.addListener(_onServiceChanged);
    _loadData();
  }

  @override
  void dispose() {
    authSyncService.removeListener(_onServiceChanged);
    supabaseService.removeListener(_onServiceChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onServiceChanged() {
    if (mounted) {
      _loadData(); // Tải danh sách yêu cầu mượn song song để tối ưu tốc độ phản hồi UI
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final email = supabaseService.currentUserEmail;
    debugPrint('[BorrowManagementScreen] Đang nạp dữ liệu mượn cho email: $email');
    final outgoing = await supabaseService.getMyBorrowRequests();
    final incoming = await supabaseService.getBorrowRequestsForMyDocuments();
    if (mounted) {
      setState(() {
        _outgoingRequests = outgoing;
        _incomingRequests = incoming;
        _isLoading = false;
      });
    }
  }


  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return const Color(0xFF43A047); // Xanh lá
      case 'rejected':
        return Colors.redAccent;
      case 'returned':
        return Colors.blueGrey;
      case 'borrowed':
        return const Color(0xFF3F51B5);
      case 'pending':
      default:
        return const Color(0xFFFFA000); // Cam vàng
    }
  }

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return 'Đã duyệt mượn';
      case 'rejected':
        return 'Bị từ chối';
      case 'returned':
        return 'Đã trả sách';
      case 'borrowed':
        return 'Đang mượn';
      case 'pending':
      default:
        return 'Chờ phê duyệt';
    }
  }

  Future<void> _updateStatus(String requestId, String newStatus, String message) async {
    final ok = await supabaseService.updateBorrowRequestStatus(requestId, newStatus);
    if (mounted) {
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: const Color(0xFF43A047)),
        );
        _loadData();
        appNotificationService.refreshNotifications();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật trạng thái thất bại')),
        );
      }
    }
  }

  Future<void> _handleCancelRequest(SupabaseBorrowRequest req) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Hủy yêu cầu mượn?',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Text(
          'Bạn có chắc chắn muốn hủy yêu cầu mượn cuốn sách "${req.documentName ?? 'Tài liệu'}" không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Giữ lại'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hủy yêu cầu'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final ok = await supabaseService.cancelBorrowRequest(req.id);
      if (mounted) {
        if (ok) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã hủy yêu cầu mượn thành công'),
              backgroundColor: Color(0xFF43A047),
            ),
          );
          _loadData();
          appNotificationService.refreshNotifications();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không thể hủy yêu cầu mượn')),
          );
        }
      }
    }
  }

  void _showApprovalDialog(SupabaseBorrowRequest req) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.approval_rounded, color: Color(0xFF3F51B5)),
            SizedBox(width: 10),
            Text('Phê Duyệt Mượn Sách', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  req.documentName ?? 'Tài liệu của bạn',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blueGrey.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.person_rounded, size: 16, color: Color(0xFF3F51B5)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Người mượn: ${req.borrowerName ?? req.borrowerEmail}',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.email_outlined, size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              req.borrowerEmail,
                              style: const TextStyle(fontSize: 12.5, color: Colors.grey),
                            ),
                          ),
                        ],
                      ),
                      if (req.dueDate != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.event_available_rounded, size: 16, color: Color(0xFF43A047)),
                            const SizedBox(width: 8),
                            Text(
                              'Hẹn trả: ${dateFormat.format(req.dueDate!)}',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                if (req.note != null && req.note!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text('Lời nhắn từ người mượn:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '"${req.note}"',
                      style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: Colors.amber, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Khi bạn chấp nhận, vị trí chi tiết (kệ tủ, khuôn viên) sẽ được chia sẻ cho người mượn đến nhận sách.',
                          style: TextStyle(fontSize: 11.5, color: Colors.black87),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _updateStatus(req.id, 'rejected', 'Đã từ chối yêu cầu mượn');
            },
            child: const Text('Từ chối'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF43A047),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.check_rounded, size: 18),
            label: const Text('Chấp nhận cho mượn'),
            onPressed: () {
              Navigator.pop(ctx);
              _updateStatus(req.id, 'approved', 'Đã đồng ý cho ${req.borrowerEmail} mượn sách!');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAccountHeader(String? email) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (email == null || email.isEmpty) {
      return Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.amber.withValues(alpha: isDark ? 0.2 : 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline_rounded, color: Colors.amber, size: 20),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Bạn chưa đăng nhập. Vui lòng đăng nhập Google để đồng bộ yêu cầu mượn.',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.tonal(
              style: FilledButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              ),
              onPressed: () => authSyncService.signInWithGoogle(),
              child: const Text('Đăng nhập', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF3F51B5).withValues(alpha: isDark ? 0.2 : 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF3F51B5).withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.account_circle_rounded, size: 20, color: Color(0xFF3F51B5)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Tài khoản: $email',
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF3F51B5),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 20, color: Color(0xFF3F51B5)),
            tooltip: 'Làm mới dữ liệu từ máy chủ',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: _loadData,
          ),
        ],
      ),
    );
  }

  Widget _buildNotLoggedInView() {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF3F51B5).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.account_circle_outlined, size: 64, color: Color(0xFF3F51B5)),
            ),
            const SizedBox(height: 16),
            const Text(
              'Chưa đăng nhập tài khoản',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Dữ liệu mượn sách được lưu trữ trên đám mây. Vui lòng đăng nhập Google để xem yêu cầu mượn gửi đến bạn.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF3F51B5),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.login_rounded, size: 20),
              label: const Text('Đăng nhập với Google', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () => authSyncService.signInWithGoogle(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyOutgoingView() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 60),
        Icon(Icons.mark_email_read_outlined,
            size: 64, color: Colors.grey.withValues(alpha: 0.5)),
        const SizedBox(height: 12),
        const Text(
          'Bạn chưa gửi yêu cầu mượn tài liệu nào',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey, fontSize: 15, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        const Text(
          'Mở tab "Mượn tài liệu" để tìm sách quanh bạn',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildEmptyIncomingView() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 60),
        Icon(Icons.inbox_outlined,
            size: 64, color: Colors.grey.withValues(alpha: 0.5)),
        const SizedBox(height: 12),
        const Text(
          'Không có yêu cầu mượn nào gửi đến bạn',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey, fontSize: 15, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        const Text(
          'Bật tính năng "Sẵn sàng cho mượn" khi thêm sách để chia sẻ',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final currentEmail = supabaseService.currentUserEmail;

    final tabBar = TabBar(
      controller: _tabController,
      labelColor: const Color(0xFF3F51B5),
      indicatorColor: const Color(0xFF3F51B5),
      labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
      labelPadding: const EdgeInsets.symmetric(horizontal: 4),
      tabs: [
        Tab(
          icon: const Icon(Icons.outbox_rounded, size: 20),
          text: 'Yêu cầu tôi đã gửi (${_outgoingRequests.length})',
        ),
        Tab(
          icon: const Icon(Icons.inbox_rounded, size: 20),
          text: 'Yêu cầu gửi đến tôi (${_incomingRequests.length})',
        ),
      ],
    );

    final content = _isLoading
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              _buildAccountHeader(currentEmail),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // TAB 1: YÊU CẦU TÔI ĐÃ GỬI
                    currentEmail == null
                        ? _buildNotLoggedInView()
                        : RefreshIndicator(
                            onRefresh: _loadData,
                            child: _outgoingRequests.isEmpty
                                ? _buildEmptyOutgoingView()
                                : ListView.builder(
                                    physics: const AlwaysScrollableScrollPhysics(),
                                    padding: const EdgeInsets.all(16),
                                    itemCount: _outgoingRequests.length,
                                    itemBuilder: (ctx, i) {
                                      final req = _outgoingRequests[i];
                                      final statusColor = _getStatusColor(req.status);
                                      final isPending = req.status.toLowerCase() == 'pending';
                                      final isApproved = req.status.toLowerCase() == 'approved';

                                      return Card(
                                        margin: const EdgeInsets.only(bottom: 14),
                                        shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(18)),
                                        child: Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      req.documentName ?? 'Tài liệu mượn',
                                                      style: const TextStyle(
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 16),
                                                    ),
                                                  ),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(
                                                        horizontal: 10, vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: statusColor.withValues(alpha: 0.12),
                                                      borderRadius: BorderRadius.circular(12),
                                                      border: Border.all(
                                                          color: statusColor.withValues(alpha: 0.3)),
                                                    ),
                                                    child: Text(
                                                      _getStatusLabel(req.status),
                                                      style: TextStyle(
                                                          color: statusColor,
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 12),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                'Chủ sách: ${req.ownerEmail}',
                                                style: const TextStyle(
                                                    fontSize: 13, color: Colors.grey),
                                              ),
                                              if (req.dueDate != null) ...[
                                                const SizedBox(height: 6),
                                                Row(
                                                  children: [
                                                    const Icon(Icons.event_rounded,
                                                        size: 16, color: Color(0xFF3F51B5)),
                                                    const SizedBox(width: 6),
                                                    Text(
                                                      'Hạn hẹn trả: ${dateFormat.format(req.dueDate!)}',
                                                      style: const TextStyle(
                                                          fontSize: 13,
                                                          fontWeight: FontWeight.w600),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                              if (req.note != null && req.note!.isNotEmpty) ...[
                                                const SizedBox(height: 8),
                                                Container(
                                                  width: double.infinity,
                                                  padding: const EdgeInsets.all(10),
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey.withValues(alpha: 0.06),
                                                    borderRadius: BorderRadius.circular(10),
                                                  ),
                                                  child: Text(
                                                    'Lời nhắn của bạn: "${req.note}"',
                                                    style: const TextStyle(
                                                        fontSize: 12,
                                                        fontStyle: FontStyle.italic),
                                                  ),
                                                ),
                                              ],

                                              // NẾU ĐƯỢC CHẤP NHẬN: HIỂN THỊ VỊ TRÍ CHIA SẺ ĐỂ ĐẾN LẤY
                                              if (isApproved) ...[
                                                const SizedBox(height: 12),
                                                Container(
                                                  padding: const EdgeInsets.all(12),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFF43A047).withValues(alpha: 0.1),
                                                    borderRadius: BorderRadius.circular(12),
                                                    border: Border.all(color: const Color(0xFF43A047).withValues(alpha: 0.3)),
                                                  ),
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      const Row(
                                                        children: [
                                                          Icon(Icons.location_on_rounded, size: 18, color: Color(0xFF2E7D32)),
                                                          SizedBox(width: 6),
                                                          Text(
                                                            'Vị trí đến nhận sách:',
                                                            style: TextStyle(
                                                              fontWeight: FontWeight.bold,
                                                              fontSize: 13,
                                                              color: Color(0xFF2E7D32),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 6),
                                                      Text(
                                                        req.physicalLocation ?? (req.address ?? 'Liên hệ chủ sách để hẹn điểm lấy'),
                                                        style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                                                      ),
                                                      if (req.address != null && req.physicalLocation != null)
                                                        Text(
                                                          'Khuôn viên: ${req.address}',
                                                          style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                              ],

                                              // NẾU ĐANG CHỜ DUYỆT: NÚT HỦY YÊU CẦU
                                              if (isPending) ...[
                                                const SizedBox(height: 12),
                                                Align(
                                                  alignment: Alignment.centerRight,
                                                  child: OutlinedButton.icon(
                                                    style: OutlinedButton.styleFrom(
                                                      foregroundColor: Colors.redAccent,
                                                      side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.4)),
                                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                    ),
                                                    icon: const Icon(Icons.cancel_outlined, size: 16),
                                                    label: const Text('Hủy yêu cầu'),
                                                    onPressed: () => _handleCancelRequest(req),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),

                    // TAB 2: YÊU CẦU GỬI ĐẾN TÔI (CHỦ SÁCH DUYỆT)
                    currentEmail == null
                        ? _buildNotLoggedInView()
                        : RefreshIndicator(
                            onRefresh: _loadData,
                            child: _incomingRequests.isEmpty
                                ? _buildEmptyIncomingView()
                                : ListView.builder(
                                    physics: const AlwaysScrollableScrollPhysics(),
                                    padding: const EdgeInsets.all(16),
                                    itemCount: _incomingRequests.length,
                                    itemBuilder: (ctx, i) {
                                      final req = _incomingRequests[i];
                                      final statusColor = _getStatusColor(req.status);
                                      final isPending = req.status.toLowerCase() == 'pending';
                                      final isApproved = req.status.toLowerCase() == 'approved';

                                      return Card(
                                        margin: const EdgeInsets.only(bottom: 14),
                                        shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(18)),
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(18),
                                          onTap: isPending ? () => _showApprovalDialog(req) : null,
                                          child: Padding(
                                            padding: const EdgeInsets.all(16),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        req.documentName ?? 'Tài liệu của bạn',
                                                        style: const TextStyle(
                                                            fontWeight: FontWeight.bold,
                                                            fontSize: 16),
                                                      ),
                                                    ),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(
                                                          horizontal: 10, vertical: 4),
                                                      decoration: BoxDecoration(
                                                        color: statusColor.withValues(alpha: 0.12),
                                                        borderRadius: BorderRadius.circular(12),
                                                        border: Border.all(
                                                            color: statusColor.withValues(alpha: 0.3)),
                                                      ),
                                                      child: Text(
                                                        _getStatusLabel(req.status),
                                                        style: TextStyle(
                                                            color: statusColor,
                                                            fontWeight: FontWeight.bold,
                                                            fontSize: 12),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 8),
                                                Row(
                                                  children: [
                                                    const Icon(Icons.person_rounded,
                                                        size: 16, color: Colors.grey),
                                                    const SizedBox(width: 6),
                                                    Expanded(
                                                      child: Text(
                                                        'Người mượn: ${req.borrowerName ?? req.borrowerEmail}',
                                                        style: const TextStyle(
                                                            fontSize: 13, color: Colors.grey),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                if (req.dueDate != null) ...[
                                                  const SizedBox(height: 4),
                                                  Row(
                                                    children: [
                                                      const Icon(Icons.event_rounded,
                                                          size: 16, color: Color(0xFF3F51B5)),
                                                      const SizedBox(width: 6),
                                                      Text(
                                                        'Hạn hẹn trả: ${dateFormat.format(req.dueDate!)}',
                                                        style: const TextStyle(
                                                            fontSize: 13,
                                                            fontWeight: FontWeight.w600),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                                if (req.note != null && req.note!.isNotEmpty) ...[
                                                  const SizedBox(height: 8),
                                                  Container(
                                                    width: double.infinity,
                                                    padding: const EdgeInsets.all(10),
                                                    decoration: BoxDecoration(
                                                      color: Colors.grey.withValues(alpha: 0.06),
                                                      borderRadius: BorderRadius.circular(10),
                                                    ),
                                                    child: Text(
                                                      'Lời nhắn: "${req.note}"',
                                                      style: const TextStyle(
                                                          fontSize: 12,
                                                          fontStyle: FontStyle.italic),
                                                    ),
                                                  ),
                                                ],

                                                // HÀNH ĐỘNG DÀNH CHO CHỦ SÁCH
                                                if (isPending) ...[
                                                  const SizedBox(height: 14),
                                                  SizedBox(
                                                    width: double.infinity,
                                                    child: FilledButton.icon(
                                                      style: FilledButton.styleFrom(
                                                        backgroundColor: const Color(0xFF3F51B5),
                                                        shape: RoundedRectangleBorder(
                                                            borderRadius: BorderRadius.circular(12)),
                                                      ),
                                                      icon: const Icon(Icons.open_in_new_rounded, size: 18),
                                                      label: const Text('Xem chi tiết & Phê duyệt'),
                                                      onPressed: () => _showApprovalDialog(req),
                                                    ),
                                                  ),
                                                ] else if (isApproved) ...[
                                                  const SizedBox(height: 14),
                                                  SizedBox(
                                                    width: double.infinity,
                                                    child: ElevatedButton.icon(
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor: Colors.blueGrey,
                                                        foregroundColor: Colors.white,
                                                        shape: RoundedRectangleBorder(
                                                            borderRadius: BorderRadius.circular(12)),
                                                      ),
                                                      icon: const Icon(
                                                          Icons.assignment_turned_in_rounded,
                                                          size: 18),
                                                      label: const Text('Xác Nhận Đã Nhận Lại Sách'),
                                                      onPressed: () => _updateStatus(
                                                        req.id,
                                                        'returned',
                                                        'Đã cập nhật trạng thái đã nhận lại sách hoàn tất',
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                  ],
                ),
              ),
            ],
          );

    if (!widget.showAppBar) {
      return Column(
        children: [
          Material(
            color: Theme.of(context).cardColor,
            elevation: 1,
            child: tabBar,
          ),
          Expanded(child: content),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản Lý Mượn & Trả Sách'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Làm mới danh sách mượn',
            onPressed: _loadData,
          ),
        ],
        bottom: tabBar,
      ),
      body: content,
    );
  }
}
