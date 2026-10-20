import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/database/database_global.dart';
import '../../../core/database/app_database.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/auth_sync_service.dart';
import '../../../core/services/firebase_service.dart';
import '../../borrow/widgets/borrow_request_dialog.dart';

class DocumentMapScreen extends StatefulWidget {
  final bool showAppBar;

  const DocumentMapScreen({super.key, this.showAppBar = false});

  @override
  State<DocumentMapScreen> createState() => _DocumentMapScreenState();
}

class _DocumentMapScreenState extends State<DocumentMapScreen> {
  final MapController _mapController = MapController();
  List<SupabaseDocument> _cloudPhysicalDocs = [];
  bool _isLoadingCloud = false;
  dynamic _selectedDoc; // Document or SupabaseDocument

  Set<String> _deletedPks = {};

  // Điểm mặc định: Khuôn viên Bách Khoa / Hà Nội
  final LatLng _defaultCenter = const LatLng(21.0049, 105.8458);

  @override
  void initState() {
    super.initState();
    supabaseService.addListener(_onSupabaseUpdated);
    _loadCloudPhysicalDocs();
  }

  @override
  void dispose() {
    supabaseService.removeListener(_onSupabaseUpdated);
    super.dispose();
  }

  void _onSupabaseUpdated() {
    if (mounted && !_isLoadingCloud) {
      _loadCloudPhysicalDocs();
    }
  }

  Future<void> _loadCloudPhysicalDocs() async {
    if (_isLoadingCloud) return;
    setState(() => _isLoadingCloud = true);
    try {
      final deletedPks = await database.documentDao.getDeletedDocumentPks();
      final docs = await supabaseService
          .getPublicPhysicalDocuments()
          .timeout(const Duration(seconds: 4), onTimeout: () => []);
      if (mounted) {
        setState(() {
          _deletedPks = deletedPks;
          _cloudPhysicalDocs = docs.where((d) => !deletedPks.contains(d.id)).toList();
          _isLoadingCloud = false;
        });
      }
    } catch (e) {
      debugPrint('[DocumentMapScreen] Lỗi nạp dữ liệu vị trí: $e');
      if (mounted) {
        setState(() => _isLoadingCloud = false);
      }
    }
  }

  void _onMarkerTapped(dynamic doc, LatLng point) {
    setState(() {
      _selectedDoc = doc;
    });
    _mapController.move(point, 16.5);
  }

  void _showBorrowDialog(dynamic doc) {
    final docId = doc is Document ? doc.documentPk : (doc as SupabaseDocument).id;
    final docName = doc.name;
    final ownerEmail = doc is Document
        ? (supabaseService.getDocumentCreator(doc) ?? (firebaseService.userEmail ?? 'Chủ sách'))
        : (doc as SupabaseDocument).ownerEmail;
    final ownerUid = doc is Document
        ? ''
        : (doc as SupabaseDocument).ownerUid;
    final address = doc.address;
    final physicalLocation = doc.physicalLocation;

    showDialog(
      context: context,
      builder: (_) => BorrowRequestDialog(
        documentId: docId,
        documentName: docName,
        ownerEmail: ownerEmail,
        ownerUid: ownerUid,
        address: address,
        physicalLocation: physicalLocation,
      ),
    );
  }

  bool _computeIsMyBook(dynamic doc) {
    if (doc == null) return false;
    final myEmail = (authSyncService.user?.email ??
            firebaseService.currentUser?.email ??
            '')
        .trim()
        .toLowerCase();
    final myUid = firebaseService.currentUser?.uid ?? '';

    final docOwnerEmail = (doc is SupabaseDocument)
        ? doc.ownerEmail.trim().toLowerCase()
        : (doc is Document
            ? (supabaseService.getDocumentCreator(doc) ?? '').trim().toLowerCase()
            : '');
    final docOwnerUid = (doc is SupabaseDocument) ? doc.ownerUid : '';

    if (myEmail.isNotEmpty && docOwnerEmail.isNotEmpty) {
      return docOwnerEmail == myEmail;
    }
    if (myUid.isNotEmpty && docOwnerUid.isNotEmpty) {
      return docOwnerUid == myUid;
    }
    if (myEmail.isEmpty && doc is Document && docOwnerEmail.isEmpty) {
      return true;
    }
    return false;
  }

  void _showMyBookDetailDialog(dynamic doc) {
    final name = doc.name;
    final address = doc.address ?? 'Chưa rõ địa chỉ';
    final physicalLocation = (doc.physicalLocation != null && doc.physicalLocation!.isNotEmpty)
        ? doc.physicalLocation!
        : 'Chưa có mô tả ngăn kệ';
    final isAvailable = doc.isAvailableForBorrow == true;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF3F51B5).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.menu_book_rounded, color: Color(0xFF3F51B5)),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Thông tin sách của bạn',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isAvailable ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isAvailable ? const Color(0xFF4CAF50) : const Color(0xFFFF9800)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isAvailable ? Icons.check_circle_outline_rounded : Icons.pending_actions_rounded,
                    size: 16,
                    color: isAvailable ? const Color(0xFF2E7D32) : const Color(0xFFE65100),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isAvailable ? 'Tình trạng: Sẵn sàng cho mượn' : 'Tình trạng: Đang cho mượn',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: isAvailable ? const Color(0xFF2E7D32) : const Color(0xFFE65100),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on_rounded, size: 18, color: Colors.redAccent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Địa chỉ: $address', style: const TextStyle(fontSize: 13)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.inventory_2_outlined, size: 18, color: Color(0xFF3F51B5)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Vị trí ngăn kệ: $physicalLocation',
                      style: const TextStyle(fontSize: 13, color: Color(0xFF3F51B5))),
                ),
              ],
            ),
            Builder(
              builder: (_) {
                final cleanNote = SupabaseService.unpackCleanNote(doc.note);
                if (cleanNote.isEmpty) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.notes_rounded, size: 18, color: Colors.blueGrey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Ghi chú: $cleanNote',
                          style: const TextStyle(fontSize: 13, color: Colors.blueGrey),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            icon: const Icon(Icons.delete_outline_rounded, size: 18),
            label: const Text('Xoá sách này'),
            onPressed: () {
              Navigator.pop(ctx);
              _deleteBookFromMap(doc);
            },
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteBookFromMap(dynamic doc) async {
    final docId = doc is Document ? doc.documentPk : (doc as SupabaseDocument).id;
    final name = doc.name;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xoá sách'),
        content: Text('Bạn có chắc chắn muốn xoá "$name" khỏi bản đồ và hệ thống không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xoá'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      if (supabaseService.isConfigured) {
        await supabaseService.deleteCloudDocument(docId);
      }
      await database.documentDao.deleteDocumentSafely(docId);
      setState(() {
        _selectedDoc = null;
      });
      await _loadCloudPhysicalDocs();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã xoá "$name" thành công!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.showAppBar
          ? AppBar(
              title: const Text('Bản Đồ Vị Trí Tài Liệu & Sách'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  tooltip: 'Tải lại vị trí sách trên Cloud',
                  onPressed: _loadCloudPhysicalDocs,
                ),
              ],
            )
          : null,
      body: StreamBuilder<List<Document>>(
        stream: database.documentDao.watchPhysicalDocuments(),
        builder: (context, snapshot) {
          final localDocs = snapshot.data ?? [];

          // Gộp các tài liệu có tọa độ hợp lệ
          final markers = <Marker>[];
          final processedDocIds = <String>{};

          bool isSelectedDoc(String id) {
            if (_selectedDoc == null) return false;
            if (_selectedDoc is Document) {
              return (_selectedDoc as Document).documentPk == id;
            } else if (_selectedDoc is SupabaseDocument) {
              return (_selectedDoc as SupabaseDocument).id == id;
            }
            return false;
          }

          // 1. Thêm từ local: CHỈ HIỂN THỊ SÁCH CỦA CHÍNH TÔI (và chưa bị xoá)
          for (final doc in localDocs) {
            if (doc.latitude != null && doc.longitude != null) {
              if (_deletedPks.contains(doc.documentPk)) continue;
              final isMyBook = _computeIsMyBook(doc);
              // Nếu không phải sách của tài khoản hiện tại, không hiển thị từ local (chỉ hiển thị nếu tồn tại trên Cloud)
              if (!isMyBook) continue;

              processedDocIds.add(doc.documentPk);
              final pt = LatLng(doc.latitude!, doc.longitude!);
              final isSelected = isSelectedDoc(doc.documentPk);

              markers.add(
                Marker(
                  point: pt,
                  width: 50,
                  height: 50,
                  child: GestureDetector(
                    onTap: () => _onMarkerTapped(doc, pt),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFE91E63)
                            : (isMyBook ? const Color(0xFF3F51B5) : const Color(0xFF43A047)),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(
                        isMyBook ? Icons.menu_book_rounded : Icons.share_location_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                  ),
                ),
              );
            }
          }

          // 2. Thêm từ cloud
          for (final doc in _cloudPhysicalDocs) {
            // Tránh trùng nếu đã xử lý từ local
            if (processedDocIds.contains(doc.id)) continue;
            processedDocIds.add(doc.id);

            if (doc.latitude != null && doc.longitude != null) {
              final isMyBook = _computeIsMyBook(doc);
              final pt = LatLng(doc.latitude!, doc.longitude!);
              final isSelected = isSelectedDoc(doc.id);

              markers.add(
                Marker(
                  point: pt,
                  width: 50,
                  height: 50,
                  child: GestureDetector(
                    onTap: () => _onMarkerTapped(doc, pt),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFE91E63)
                            : (isMyBook ? const Color(0xFF3F51B5) : const Color(0xFF43A047)),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(
                        isMyBook ? Icons.menu_book_rounded : Icons.share_location_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                  ),
                ),
              );
            }
          }

          // Xác định điểm trung tâm khởi tạo
          LatLng initialCenter = _defaultCenter;
          if (markers.isNotEmpty) {
            initialCenter = markers.first.point;
          }

          return Stack(
            children: [
              // Bản đồ OpenStreetMap
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: initialCenter,
                  initialZoom: 15.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.studyhub.app',
                  ),
                  MarkerLayer(markers: markers),
                ],
              ),

              // Thanh chú thích (Legend)
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.92),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: Color(0xFF3F51B5),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text('Sách của bạn', style: TextStyle(fontSize: 12, color: Colors.black87)),
                      const SizedBox(width: 12),
                      Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: Color(0xFF43A047),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text('Cộng đồng chia sẻ', style: TextStyle(fontSize: 12, color: Colors.black87)),
                    ],
                  ),
                ),
              ),

              // Loading indicator khi tải vị trí sách từ Supabase
              if (_isLoadingCloud)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      shape: BoxShape.circle,
                    ),
                    child: const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),

              // Card chi tiết khi người dùng chạm vào một ghim sách
              if (_selectedDoc != null)
                Positioned(
                  bottom: 20,
                  left: 16,
                  right: 16,
                  child: Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF3F51B5).withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(Icons.menu_book_rounded, color: Color(0xFF3F51B5)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _selectedDoc.name,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                     Builder(
                                       builder: (_) {
                                         final bool isMyBook = _computeIsMyBook(_selectedDoc);
                                         final bool isAvailable =
                                             _selectedDoc.isAvailableForBorrow == true;

                                         return Wrap(
                                           spacing: 6,
                                           runSpacing: 4,
                                           crossAxisAlignment: WrapCrossAlignment.center,
                                           children: [
                                             Container(
                                               padding: const EdgeInsets.symmetric(
                                                   horizontal: 8, vertical: 2),
                                               decoration: BoxDecoration(
                                                 color: isMyBook
                                                     ? const Color(0xFF3F51B5)
                                                         .withValues(alpha: 0.12)
                                                     : const Color(0xFF43A047)
                                                         .withValues(alpha: 0.12),
                                                 borderRadius: BorderRadius.circular(6),
                                               ),
                                               child: Text(
                                                 isMyBook ? 'Sách của bạn' : 'Cộng đồng',
                                                 style: TextStyle(
                                                   fontSize: 11,
                                                   fontWeight: FontWeight.bold,
                                                   color: isMyBook
                                                       ? const Color(0xFF3F51B5)
                                                       : const Color(0xFF43A047),
                                                 ),
                                               ),
                                             ),
                                             Container(
                                               padding: const EdgeInsets.symmetric(
                                                   horizontal: 8, vertical: 2),
                                               decoration: BoxDecoration(
                                                 color: isAvailable
                                                     ? const Color(0xFFE8F5E9)
                                                     : const Color(0xFFFFF3E0),
                                                 borderRadius: BorderRadius.circular(6),
                                               ),
                                               child: Text(
                                                 isAvailable
                                                     ? 'Sẵn sàng cho mượn'
                                                     : 'Đang cho mượn',
                                                 style: TextStyle(
                                                   fontSize: 11,
                                                   fontWeight: FontWeight.bold,
                                                   color: isAvailable
                                                       ? const Color(0xFF2E7D32)
                                                       : const Color(0xFFE65100),
                                                 ),
                                               ),
                                             ),
                                           ],
                                         );
                                       },
                                     ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close_rounded, size: 20),
                                onPressed: () => setState(() => _selectedDoc = null),
                              ),
                            ],
                          ),
                          const Divider(height: 18),

                          // Vị trí vĩ mô & vi mô
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.location_on_rounded, size: 18, color: Colors.redAccent),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _selectedDoc.address ?? 'Chưa rõ địa chỉ',
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                    ),
                                    if (_selectedDoc.physicalLocation != null &&
                                        _selectedDoc.physicalLocation!.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        'Vị trí chi tiết: ${_selectedDoc.physicalLocation}',
                                        style: const TextStyle(fontSize: 12, color: Color(0xFF3F51B5)),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),

                          // Tags
                          if (_selectedDoc.tags != null && _selectedDoc.tags.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 6,
                              children: (_selectedDoc.tags as String)
                                  .split(',')
                                  .map((t) => t.trim())
                                  .where((t) => t.isNotEmpty)
                                  .map(
                                    (tag) => Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF3F51B5).withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        tag.startsWith('#') ? tag : '#$tag',
                                        style: const TextStyle(fontSize: 11, color: Color(0xFF3F51B5)),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ],
                          const SizedBox(height: 16),

                          // Hàng nút tương tác theo vai trò người dùng (Chủ sách vs Người mượn)
                          Builder(
                            builder: (context) {
                              final bool isMyBook = _computeIsMyBook(_selectedDoc);
                              final bool isAvailable =
                                  _selectedDoc.isAvailableForBorrow == true;

                              if (isMyBook) {
                                return SizedBox(
                                  width: double.infinity,
                                  height: 46,
                                  child: FilledButton.icon(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: const Color(0xFF3F51B5),
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(14)),
                                    ),
                                    icon: const Icon(Icons.info_outline_rounded, size: 18),
                                    label: const Text('Xem thông tin sách của bạn',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                    onPressed: () => _showMyBookDetailDialog(_selectedDoc),
                                  ),
                                );
                              }

                              // Sách của người khác: Hiển thị nút Yêu Cầu Mượn
                              return SizedBox(
                                width: double.infinity,
                                height: 46,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isAvailable
                                        ? const Color(0xFF43A047)
                                        : Colors.grey.shade400,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14)),
                                  ),
                                  icon: const Icon(Icons.handshake_rounded, size: 18),
                                  label: Text(
                                    isAvailable ? 'Yêu Cầu Mượn Sách' : 'Sách hiện đang được mượn',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  onPressed: isAvailable
                                      ? () => _showBorrowDialog(_selectedDoc)
                                      : null,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}