import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/services/auth_sync_service.dart';
import '../../../core/services/app_notification_service.dart';

class BorrowRequestDialog extends StatefulWidget {
  final String documentId;
  final String documentName;
  final String ownerEmail;
  final String ownerUid;
  final String? address;
  final String? physicalLocation;

  const BorrowRequestDialog({
    super.key,
    required this.documentId,
    required this.documentName,
    required this.ownerEmail,
    required this.ownerUid,
    this.address,
    this.physicalLocation,
  });

  @override
  State<BorrowRequestDialog> createState() => _BorrowRequestDialogState();
}

class _BorrowRequestDialogState extends State<BorrowRequestDialog> {
  final _noteController = TextEditingController();
  DateTime _selectedDueDate = DateTime.now().add(const Duration(days: 7));
  bool _isSubmitting = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate,
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      helpText: 'CHỌN NGÀY HẸN TRẢ TÀI LIỆU',
    );
    if (picked != null) {
      setState(() => _selectedDueDate = picked);
    }
  }

  Future<void> _handleSubmit() async {
    final isLoggedIn = firebaseService.isLoggedIn || authSyncService.isLoggedIn;
    if (!isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập Google trước khi gửi yêu cầu mượn')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final ok = await supabaseService.createBorrowRequest(
      documentId: widget.documentId,
      documentName: widget.documentName,
      ownerEmail: widget.ownerEmail,
      ownerUid: widget.ownerUid,
      dueDate: _selectedDueDate,
      note: _noteController.text.trim().isNotEmpty ? _noteController.text.trim() : null,
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (ok) {
        appNotificationService.refreshNotifications();
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF43A047),
            content: Text('Đã gửi yêu cầu mượn "${widget.documentName}" thành công!'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text(supabaseService.lastError ?? 'Lỗi gửi yêu cầu mượn'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: SingleChildScrollView(
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
                      color: const Color(0xFF3F51B5).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.handshake_rounded, color: Color(0xFF3F51B5)),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Yêu Cầu Mượn Tài Liệu',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Gửi đề nghị mượn tới chủ sở hữu',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
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

              // Thông tin sách
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.withOpacity(0.15)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.documentName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.person_outline_rounded, size: 16, color: Colors.grey),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Chủ sách: ${widget.ownerEmail}',
                            style: const TextStyle(fontSize: 13, color: Colors.grey),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (widget.address != null && widget.address!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.location_on_outlined, size: 16, color: Color(0xFF3F51B5)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Địa điểm: ${widget.address}${widget.physicalLocation != null ? ' (${widget.physicalLocation})' : ''}',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF3F51B5)),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Chọn ngày hẹn trả
              const Text(
                'Ngày dự kiến trả:',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(height: 6),
              InkWell(
                onTap: _pickDueDate,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.calendar_month_rounded, color: Color(0xFF3F51B5), size: 20),
                          const SizedBox(width: 10),
                          Text(
                            dateFormat.format(_selectedDueDate),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                      const Text(
                        'Đổi ngày',
                        style: TextStyle(color: Color(0xFF3F51B5), fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Lời nhắn gửi chủ sách
              TextField(
                controller: _noteController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Lời nhắn gửi chủ tài liệu (tùy chọn)',
                  hintText: 'Chào bạn, mình muốn mượn sách để ...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 20),

              // Nút Gửi yêu cầu
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3F51B5),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.send_rounded),
                label: Text(
                  _isSubmitting ? 'Đang gửi đề nghị...' : 'Gửi Yêu Cầu Mượn',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                onPressed: _isSubmitting ? null : _handleSubmit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
