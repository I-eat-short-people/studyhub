import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/services/recommendation_service.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/auth_sync_service.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/database/database_global.dart';
import '../../../core/database/app_database.dart';
import '../../../core/theme/app_colors.dart';
import '../widgets/borrow_request_dialog.dart';

/// Màn hình Mượn Tài Liệu & Khám Phá Cộng Đồng
/// - Đầu trang: Top 10 Gợi ý thông minh (Smart Recommendations) theo sở thích và Tag
/// - Tìm kiếm theo Tag, tên sách
/// - Xem chi tiết tài liệu và gửi yêu cầu mượn kèm hạn trả & lời nhắn
class BorrowCatalogScreen extends StatefulWidget {
  final bool showAppBar;

  const BorrowCatalogScreen({super.key, this.showAppBar = false});

  @override
  State<BorrowCatalogScreen> createState() => _BorrowCatalogScreenState();
}

class _BorrowCatalogScreenState extends State<BorrowCatalogScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedTag;
  bool _isLoading = true;
  bool _isFetching = false;

  List<CommunityRecommendedItem> _recommendations = [];
  List<SupabaseDocument> _cloudDocuments = [];
  List<Document> _localPhysicalDocuments = [];
  Map<String, SupabaseBorrowRequest> _pendingRequests = {};

  final List<String> _popularTags = const [
    '#CNTT',
    '#GiaiTich',
    '#DeThi',
    '#GiaoTrinh',
    '#LapTrinhDiDong',
    '#Flutter',
    '#AI',
  ];

  @override
  void initState() {
    super.initState();
    recommendationService.addListener(_onPreferencesChanged);
    supabaseService.addListener(_onSupabaseUpdated);
    _loadCatalog();
  }

  @override
  void dispose() {
    recommendationService.removeListener(_onPreferencesChanged);
    supabaseService.removeListener(_onSupabaseUpdated);
    _searchController.dispose();
    super.dispose();
  }

  void _onSupabaseUpdated() {
    if (mounted && !_isLoading) {
      _loadCatalog();
    }
  }

  void _onPreferencesChanged() {
    _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
    final myEmail = (authSyncService.user?.email ?? firebaseService.currentUser?.email ?? '').trim().toLowerCase();
    final myUid = firebaseService.currentUser?.uid ?? '';
    final myLocalDocPks = _localPhysicalDocuments.map((d) => d.documentPk).toSet();

    final recs = await recommendationService.getCommunityRecommendations(
      communityDocs: _cloudDocuments,
      myEmail: myEmail,
      myUid: myUid,
      myLocalDocIds: myLocalDocPks,
      limit: 10,
    );
    if (mounted) {
      setState(() => _recommendations = recs);
    }
  }

  Future<void> _loadCatalog() async {
    if (_isFetching) return;
    _isFetching = true;
    if (!_isLoading) {
      setState(() => _isLoading = true);
    }

    try {
      await _fetchCatalogInternal().timeout(
        const Duration(seconds: 4),
        onTimeout: () {
          debugPrint('[BorrowCatalogScreen] Tải danh mục quá 4s, tự động mở khóa giao diện');
        },
      );
    } catch (e) {
      debugPrint('[BorrowCatalogScreen] Lỗi nạp catalog: $e');
    } finally {
      _isFetching = false;
      if (mounted && _isLoading) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _fetchCatalogInternal() async {
    final deletedPks = await database.documentDao.getDeletedDocumentPks();

    final cloudDocs = await supabaseService.getPublicPhysicalDocuments();
    final localDocs = await database.documentDao.getAllPhysicalDocuments();

    final myEmail = (authSyncService.user?.email ?? firebaseService.currentUser?.email ?? '').trim().toLowerCase();
    final myUid = firebaseService.currentUser?.uid ?? '';

    // Tải danh sách các yêu cầu mượn mà tôi đã gửi (đang chờ duyệt hoặc đã duyệt)
    final myRequests = await supabaseService.getMyBorrowRequests();
    final pendingMap = <String, SupabaseBorrowRequest>{};
    for (final req in myRequests) {
      final st = req.status.toLowerCase();
      if (st == 'pending' || st == 'approved') {
        pendingMap[req.documentId] = req;
      }
    }

    // Nhận diện tài liệu của chính tôi trên máy
    final myLocalDocs = localDocs.where((d) {
      if (deletedPks.contains(d.documentPk)) return false;
      final creator = supabaseService.getDocumentCreator(d);
      if (myEmail.isNotEmpty) {
        return creator == myEmail;
      }
      return creator == null || creator.isEmpty;
    }).toList();
    final myLocalDocPks = myLocalDocs.map((d) => d.documentPk).toSet();

    // MỤC MƯỢN TÀI LIỆU CHỈ CHỨA SÁCH CÔNG KHAI CỦA NGƯỜI KHÁC TRÊN CLOUD (LOẠI BỎ SÁCH CỦA CHÍNH TÔI VÀ TÀI LIỆU ĐÃ XOÁ)
    final otherCommunityDocs = <SupabaseDocument>[];
    final seenIds = <String>{};

    for (final d in cloudDocs) {
      if (deletedPks.contains(d.id)) continue;
      final docOwner = d.ownerEmail.trim().toLowerCase();
      if (myEmail.isNotEmpty && docOwner == myEmail) continue;
      if (myUid.isNotEmpty && d.ownerUid == myUid) continue;
      if (myLocalDocPks.contains(d.id)) continue;
      if (d.isAvailableForBorrow != true) continue;

      if (seenIds.add(d.id)) {
        otherCommunityDocs.add(d);
      }
    }

    final recs = await recommendationService.getCommunityRecommendations(
      communityDocs: otherCommunityDocs,
      myEmail: myEmail,
      myUid: myUid,
      myLocalDocIds: myLocalDocPks,
      limit: 10,
    );

    if (mounted) {
      setState(() {
        _cloudDocuments = otherCommunityDocs;
        _localPhysicalDocuments = myLocalDocs.where((d) => d.isAvailableForBorrow).toList();
        _recommendations = recs;
        _pendingRequests = pendingMap;
        _isLoading = false;
      });
    }
  }

  void _showDocumentDetailModal({
    required String documentId,
    required String name,
    required String? subjectName,
    required String ownerEmail,
    required String ownerUid,
    required String tags,
    required String? note,
    required String? address,
    required bool isPhysical,
    String? physicalLocation,
  }) async {
    final myEmail = (authSyncService.user?.email ?? firebaseService.currentUser?.email ?? '').trim().toLowerCase();
    final myUid = firebaseService.currentUser?.uid ?? '';
    final cleanOwnerEmail = ownerEmail.trim().toLowerCase();

    bool isMyBook = (cleanOwnerEmail.isNotEmpty && cleanOwnerEmail == myEmail) ||
                    (myUid.isNotEmpty && ownerUid.isNotEmpty && ownerUid == myUid);
    if (!isMyBook) {
      final local = await database.documentDao.getDocument(documentId);
      if (local != null) {
        final localOwner = supabaseService.getLocalDocumentOwner(documentId);
        if (localOwner == null || localOwner.isEmpty || localOwner == myEmail) {
          isMyBook = true;
        }
      }
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3F51B5).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.menu_book_rounded, color: Color(0xFF3F51B5), size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (subjectName != null && subjectName.isNotEmpty)
                        Text(
                          subjectName,
                          style: const TextStyle(color: Color(0xFF3F51B5), fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 14),

            // Thông tin chủ sở hữu & khu vực
            Row(
              children: [
                const Icon(Icons.account_circle_outlined, size: 18, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isMyBook ? 'Chủ sách: Bạn (Chính bạn)' : 'Chủ sách: $ownerEmail',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isMyBook ? FontWeight.bold : FontWeight.normal,
                      color: isMyBook ? const Color(0xFF2E7D32) : Colors.grey,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (isMyBook && physicalLocation != null && physicalLocation.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.inventory_2_outlined, size: 18, color: Color(0xFF3F51B5)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Vị trí ngăn kệ: $physicalLocation',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF3F51B5)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            if (address != null && address.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.place_outlined, size: 18, color: Colors.redAccent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Khuôn viên: $address',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],

            // Ghi chú mô tả (lọc bỏ metadata)
            Builder(
              builder: (_) {
                final cleanNote = SupabaseService.unpackCleanNote(note);
                if (cleanNote.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    const Text('Mô tả tài liệu:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 4),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(cleanNote, style: const TextStyle(fontSize: 13)),
                    ),
                  ],
                );
              },
            ),

            // Tags
            if (tags.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: tags
                    .split(',')
                    .map((t) => t.trim())
                    .where((t) => t.isNotEmpty)
                    .map((t) => Chip(
                          label: Text(t.startsWith('#') ? t : '#$t', style: const TextStyle(fontSize: 11)),
                          backgroundColor: const Color(0xFF3F51B5).withValues(alpha: 0.08),
                          side: BorderSide.none,
                        ))
                    .toList(),
              ),
            ],

            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.shield_outlined, color: Colors.amber, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Bảo mật vị trí: Vị trí ngăn kệ cụ thể sẽ được chia sẻ cho bạn ngay khi chủ sách duyệt yêu cầu mượn.',
                      style: TextStyle(fontSize: 11.5),
                    ),
                  ),
                ],
              ),
            ),

            // Banner thông báo nếu đã gửi yêu cầu mượn trước đó
            if (_pendingRequests.containsKey(documentId)) ...[
              const SizedBox(height: 14),
              Builder(builder: (_) {
                final req = _pendingRequests[documentId]!;
                final isApproved = req.status.toLowerCase() == 'approved';
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isApproved
                        ? Colors.green.withValues(alpha: 0.12)
                        : Colors.orange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isApproved
                          ? Colors.green.withValues(alpha: 0.3)
                          : Colors.orange.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isApproved ? Icons.check_circle_rounded : Icons.pending_actions_rounded,
                        color: isApproved ? Colors.green : Colors.orange,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          isApproved
                              ? 'Yêu cầu mượn của bạn đã được chủ sách phê duyệt!'
                              : 'Bạn đã gửi yêu cầu mượn cuốn sách này (đang chờ chủ sách duyệt). Bạn không thể gửi thêm yêu cầu mới khi chưa được phản hồi.',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: isApproved ? Colors.green.shade800 : Colors.orange.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
            const SizedBox(height: 20),

            // Nút yêu cầu mượn
            Builder(builder: (_) {
              final activeReq = _pendingRequests[documentId];
              final hasActiveReq = activeReq != null;
              final isApproved = activeReq?.status.toLowerCase() == 'approved';

              return SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: isMyBook
                        ? Colors.grey.shade400
                        : (hasActiveReq
                            ? (isApproved ? const Color(0xFF43A047) : const Color(0xFFFFA000))
                            : const Color(0xFF3F51B5)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: Icon(
                    isMyBook
                        ? Icons.check_circle_rounded
                        : (hasActiveReq
                            ? (isApproved ? Icons.verified_rounded : Icons.hourglass_top_rounded)
                            : Icons.handshake_rounded),
                  ),
                  label: Text(
                    isMyBook
                        ? 'Tài liệu thuộc sở hữu của bạn'
                        : (hasActiveReq
                            ? (isApproved ? 'Đã được duyệt mượn' : 'Đã gửi yêu cầu mượn')
                            : 'Gửi yêu cầu mượn sách'),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  onPressed: (isMyBook || hasActiveReq)
                      ? null
                      : () async {
                          Navigator.pop(ctx);
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (_) => BorrowRequestDialog(
                              documentId: documentId,
                              documentName: name,
                              ownerEmail: ownerEmail,
                              ownerUid: ownerUid,
                              address: address,
                              physicalLocation: physicalLocation,
                            ),
                          );
                          if (ok == true) {
                            _loadCatalog();
                          }
                        },
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final myEmail = (authSyncService.user?.email ?? firebaseService.currentUser?.email ?? '').trim().toLowerCase();
    final myUid = firebaseService.currentUser?.uid ?? '';

    // Lọc theo query, tag và đảm bảo không chứa sách của chính người dùng
    final filteredCloud = _cloudDocuments.where((doc) {
      final docOwner = doc.ownerEmail.trim().toLowerCase();
      if (myEmail.isNotEmpty && docOwner == myEmail) return false;
      if (myUid.isNotEmpty && doc.ownerUid == myUid) return false;

      final matchesQuery = _searchQuery.isEmpty ||
          doc.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          doc.tags.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesTag = _selectedTag == null || doc.tags.contains(_selectedTag!);
      return matchesQuery && matchesTag;
    }).toList();

    return Scaffold(
      appBar: widget.showAppBar
          ? AppBar(
              title: const Text('Mượn Tài Liệu & Sách'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  tooltip: 'Làm mới',
                  onPressed: _loadCatalog,
                ),
              ],
            )
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadCatalog,
              child: ListView(
                padding: const EdgeInsets.only(bottom: 90),
                children: [
                  // 1. KHỐI GỢI Ý THÔNG MINH (TOP 10 RECOMMENDATIONS)
                  if (_recommendations.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.auto_awesome_rounded, color: Colors.amber, size: 20),
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Gợi Ý Cho Bạn (Top Match)',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${_recommendations.length} tài liệu',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 148,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        scrollDirection: Axis.horizontal,
                        itemCount: _recommendations.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (ctx, idx) {
                          final item = _recommendations[idx];
                          final doc = item.document;
                          final matchPercent = (item.score * 100).toInt().clamp(50, 99);
                          final hasReq = _pendingRequests.containsKey(doc.id);
                          final activeReq = _pendingRequests[doc.id];
                          final isApproved = activeReq?.status.toLowerCase() == 'approved';

                          return InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              _showDocumentDetailModal(
                                documentId: doc.id,
                                name: doc.name,
                                subjectName: doc.subjectName,
                                ownerEmail: doc.ownerEmail,
                                ownerUid: doc.ownerUid,
                                tags: doc.tags,
                                note: doc.note,
                                address: doc.address,
                                isPhysical: doc.isPhysical,
                                physicalLocation: doc.physicalLocation,
                              );
                            },
                            child: Container(
                              width: 230,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: getColor(context, 'lightDarkAccent'),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: hasReq
                                      ? (isApproved ? Colors.green : Colors.orange)
                                      : const Color(0xFF3F51B5).withValues(alpha: 0.25),
                                  width: 1.2,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: hasReq
                                              ? (isApproved
                                                  ? Colors.green.withValues(alpha: 0.15)
                                                  : Colors.orange.withValues(alpha: 0.15))
                                              : Colors.green.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          hasReq
                                              ? (isApproved ? 'Đã duyệt' : 'Đã yêu cầu')
                                              : '$matchPercent% phù hợp',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: hasReq
                                                ? (isApproved ? Colors.green.shade800 : Colors.orange.shade900)
                                                : Colors.green,
                                          ),
                                        ),
                                      ),
                                      const Spacer(),
                                      Icon(
                                        hasReq
                                            ? (isApproved ? Icons.check_circle_outline : Icons.hourglass_top_rounded)
                                            : Icons.handshake_outlined,
                                        size: 16,
                                        color: hasReq
                                            ? (isApproved ? Colors.green : Colors.orange)
                                            : const Color(0xFF3F51B5),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    doc.name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  const Spacer(),
                                  Text(
                                    item.reason,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 10.5, color: Colors.blueGrey, fontStyle: FontStyle.italic),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // 2. THANH TÌM KIẾM THEO TÊN & TAG
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) => setState(() => _searchQuery = val),
                      decoration: InputDecoration(
                        hintText: 'Tìm sách mượn theo tên hoặc tag (#AI, #CNTT)...',
                        hintStyle: const TextStyle(fontSize: 13),
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),

                  // 3. TAG FILTER CHIPS
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        FilterChip(
                          label: const Text('Tất cả'),
                          selected: _selectedTag == null,
                          onSelected: (_) => setState(() => _selectedTag = null),
                        ),
                        const SizedBox(width: 8),
                        ..._popularTags.map((tag) {
                          final isSelected = _selectedTag == tag;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: FilterChip(
                              label: Text(tag),
                              selected: isSelected,
                              onSelected: (_) {
                                setState(() {
                                  _selectedTag = isSelected ? null : tag;
                                });
                              },
                            ),
                          );
                        }),
                      ],
                    ),
                  ),

                  // 4. DANH SÁCH SÁCH CÔNG KHAI CÓ THỂ MƯỢN
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                    child: Text(
                      'Sách Sẵn Sàng Cho Mượn (${filteredCloud.length})',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),

                  if (filteredCloud.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          children: [
                            Icon(Icons.library_books_outlined, size: 56, color: Colors.grey.withValues(alpha: 0.5)),
                            const SizedBox(height: 12),
                            const Text(
                              'Không tìm thấy tài liệu phù hợp để mượn',
                              style: TextStyle(color: Colors.grey, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      itemCount: filteredCloud.length,
                      itemBuilder: (ctx, index) {
                        final doc = filteredCloud[index];
                        final hasReq = _pendingRequests.containsKey(doc.id);
                        final activeReq = _pendingRequests[doc.id];
                        final isApproved = activeReq?.status.toLowerCase() == 'approved';

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              _showDocumentDetailModal(
                                documentId: doc.id,
                                name: doc.name,
                                subjectName: doc.subjectName,
                                ownerEmail: doc.ownerEmail,
                                ownerUid: doc.ownerUid,
                                tags: doc.tags,
                                note: doc.note,
                                address: doc.address,
                                isPhysical: doc.isPhysical,
                                physicalLocation: doc.physicalLocation,
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF3F51B5).withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.book_rounded, color: Color(0xFF3F51B5)),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          doc.name,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Chủ sách: ${doc.ownerEmail}',
                                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                                        ),
                                        if (doc.address != null && doc.address!.isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Row(
                                            children: [
                                              const Icon(Icons.place_outlined, size: 14, color: Colors.redAccent),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  doc.address!,
                                                  style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                        if (doc.tags.isNotEmpty) ...[
                                          const SizedBox(height: 6),
                                          Wrap(
                                            spacing: 4,
                                            children: doc.tags
                                                .split(',')
                                                .take(3)
                                                .map((t) => Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: const Color(0xFF3F51B5).withValues(alpha: 0.08),
                                                        borderRadius: BorderRadius.circular(4),
                                                      ),
                                                      child: Text(
                                                        t.trim().startsWith('#') ? t.trim() : '#${t.trim()}',
                                                        style: const TextStyle(fontSize: 10, color: Color(0xFF3F51B5)),
                                                      ),
                                                    ))
                                                .toList(),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  FilledButton.tonal(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: hasReq
                                          ? (isApproved
                                              ? Colors.green.withValues(alpha: 0.15)
                                              : Colors.amber.withValues(alpha: 0.2))
                                          : null,
                                      foregroundColor: hasReq
                                          ? (isApproved ? Colors.green.shade800 : Colors.orange.shade900)
                                          : null,
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    ),
                                    onPressed: () {
                                      _showDocumentDetailModal(
                                        documentId: doc.id,
                                        name: doc.name,
                                        subjectName: doc.subjectName,
                                        ownerEmail: doc.ownerEmail,
                                        ownerUid: doc.ownerUid,
                                        tags: doc.tags,
                                        note: doc.note,
                                        address: doc.address,
                                        isPhysical: doc.isPhysical,
                                        physicalLocation: doc.physicalLocation,
                                      );
                                    },
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (hasReq) ...[
                                          Icon(
                                            isApproved ? Icons.check_circle_outline : Icons.hourglass_top_rounded,
                                            size: 14,
                                          ),
                                          const SizedBox(width: 4),
                                        ],
                                        Text(hasReq ? (isApproved ? 'Đã duyệt' : 'Đã yêu cầu') : 'Mượn'),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
    );
  }
}
