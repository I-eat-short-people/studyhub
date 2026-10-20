import 'package:flutter/material.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/database_global.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/cashew_bottom_sheet.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/auth_sync_service.dart';
import '../../../core/services/firebase_service.dart';
import '../widgets/add_edit_document_sheet.dart';
import '../widgets/document_card.dart';

class DocumentsScreen extends StatefulWidget {
  final bool showAppBar;

  const DocumentsScreen({super.key, this.showAppBar = false});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedSubjectPk;
  DocumentType? _selectedType;
  DocumentCategory? _selectedCategory;
  String? _selectedTag;
  bool _isPhysicalFilter = false;
  bool _isSharedWithMeFilter = false;
  String _sortBy = 'date_desc'; // 'date_desc', 'date_asc', 'name_asc', 'name_desc'

  final List<String> _popularTags = const [
    '#CNTT',
    '#GiaiTich',
    '#DeThi',
    '#Slide',
    '#GiaoTrinh',
    '#LapTrinhDiDong',
    '#AI',
  ];

  @override
  void initState() {
    super.initState();
    authSyncService.addListener(_onAuthChange);
    supabaseService.addListener(_onAuthChange);
    if (supabaseService.isConfigured && authSyncService.isLoggedIn) {
      supabaseService.syncDocumentsForCurrentAccount();
    }
  }

  @override
  void dispose() {
    authSyncService.removeListener(_onAuthChange);
    supabaseService.removeListener(_onAuthChange);
    _searchController.dispose();
    super.dispose();
  }

  void _onAuthChange() {
    if (mounted) setState(() {});
  }

  int get _activeFilterCount {
    int count = 0;
    if (_selectedCategory != null) count++;
    if (_selectedSubjectPk != null) count++;
    if (_selectedType != null) count++;
    if (_selectedTag != null) count++;
    if (_isPhysicalFilter) count++;
    if (_isSharedWithMeFilter) count++;
    if (_sortBy != 'date_desc') count++;
    return count;
  }

  void _resetAllFilters() {
    setState(() {
      _selectedCategory = null;
      _selectedSubjectPk = null;
      _selectedType = null;
      _selectedTag = null;
      _isPhysicalFilter = false;
      _isSharedWithMeFilter = false;
      _sortBy = 'date_desc';
    });
  }

  void _showAdvancedFilterSheet(BuildContext context) {
    String? tempSubjectPk = _selectedSubjectPk;
    DocumentCategory? tempCategory = _selectedCategory;
    DocumentType? tempType = _selectedType;
    String? tempTag = _selectedTag;
    bool tempPhysical = _isPhysicalFilter;
    bool tempSharedWithMe = _isSharedWithMeFilter;
    String tempSortBy = _sortBy;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          int tempActiveCount = 0;
          if (tempCategory != null) tempActiveCount++;
          if (tempType != null) tempActiveCount++;
          if (tempSubjectPk != null) tempActiveCount++;
          if (tempTag != null) tempActiveCount++;
          if (tempPhysical) tempActiveCount++;
          if (tempSharedWithMe) tempActiveCount++;
          if (tempSortBy != 'date_desc') tempActiveCount++;

          return ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.tune_rounded, color: Color(0xFF3F51B5)),
                            SizedBox(width: 8),
                            Text(
                              'Bộ Lọc Nâng Cao',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        if (tempActiveCount > 0)
                          TextButton(
                            onPressed: () {
                              setModalState(() {
                                tempCategory = null;
                                tempSubjectPk = null;
                                tempType = null;
                                tempTag = null;
                                tempPhysical = false;
                                tempSortBy = 'date_desc';
                              });
                            },
                            child: const Text('Đặt lại tất cả'),
                          ),
                      ],
                    ),
                    const Divider(height: 20),

                    // 1. Môn học
                    const Text('Môn học', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    StreamBuilder<List<Subject>>(
                      stream: database.subjectDao.watchAllSubjects(),
                      builder: (context, snapshot) {
                        final subjects = snapshot.data ?? [];
                        return DropdownButtonFormField<String?>(
                          value: tempSubjectPk,
                          isExpanded: true,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('Tất cả môn học'),
                            ),
                            ...subjects.map(
                              (s) => DropdownMenuItem<String?>(
                                value: s.subjectPk,
                                child: Text('${s.code} - ${s.name}', overflow: TextOverflow.ellipsis),
                              ),
                            ),
                          ],
                          onChanged: (val) {
                            setModalState(() => tempSubjectPk = val);
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 18),

                    // 2. Phân loại tài liệu
                    const Text('Phân loại tài liệu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ChoiceChip(
                          selected: tempCategory == null,
                          label: const Text('Tất cả'),
                          onSelected: (_) {
                            setModalState(() => tempCategory = null);
                          },
                        ),
                        ...DocumentCategory.values.map((cat) {
                          final isSelected = tempCategory == cat;
                          return ChoiceChip(
                            selected: isSelected,
                            avatar: Icon(Formatters.getCategoryIcon(cat), size: 16),
                            label: Text(Formatters.getCategoryName(cat)),
                            onSelected: (val) {
                              setModalState(() => tempCategory = val ? cat : null);
                            },
                          );
                        }),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // 3. Định dạng tệp
                    const Text('Định dạng tệp', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ChoiceChip(
                          selected: tempType == null,
                          label: const Text('Tất cả định dạng'),
                          onSelected: (_) {
                            setModalState(() => tempType = null);
                          },
                        ),
                        ...DocumentType.values.map((t) {
                          final isSelected = tempType == t;
                          return ChoiceChip(
                            selected: isSelected,
                            avatar: Icon(
                              Formatters.getDocumentTypeIcon(t),
                              size: 16,
                              color: isSelected
                                  ? Colors.white
                                  : getColor(context, Formatters.getDocumentTypeColorToken(t)),
                            ),
                            label: Text(Formatters.getDocumentTypeShort(t)),
                            onSelected: (val) {
                              setModalState(() => tempType = val ? t : null);
                            },
                          );
                        }),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // 4. Sách giấy & Vị trí
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      secondary: const Icon(Icons.location_on_rounded, color: Colors.redAccent),
                      title: const Text('Chỉ hiện sách giấy có vị trí', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      subtitle: const Text('Tài liệu vật lý được lưu trữ ở tủ / thư viện', style: TextStyle(fontSize: 12)),
                      value: tempPhysical,
                      onChanged: (val) {
                        setModalState(() => tempPhysical = val);
                      },
                    ),
                    const SizedBox(height: 12),

                    // 4.1. Được chia sẻ với tôi
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      secondary: const Icon(Icons.folder_shared_rounded, color: Color(0xFF1976D2)),
                      title: const Text('Chỉ hiện tài liệu được chia sẻ với tôi', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      subtitle: const Text('Tài liệu do bạn bè / chủ sở hữu khác cấp quyền cho bạn', style: TextStyle(fontSize: 12)),
                      value: tempSharedWithMe,
                      onChanged: (val) {
                        setModalState(() => tempSharedWithMe = val);
                      },
                    ),
                    const SizedBox(height: 12),

                    // 5. Thẻ tag
                    const Text('Lọc theo Tag', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        ChoiceChip(
                          selected: tempTag == null,
                          label: const Text('Tất cả tag', style: TextStyle(fontSize: 12)),
                          onSelected: (_) {
                            setModalState(() => tempTag = null);
                          },
                        ),
                        ..._popularTags.map((tag) {
                          final isSelected = tempTag == tag;
                          return ChoiceChip(
                            selected: isSelected,
                            label: Text(tag, style: const TextStyle(fontSize: 12)),
                            onSelected: (val) {
                              setModalState(() => tempTag = val ? tag : null);
                            },
                          );
                        }),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // 6. Sắp xếp
                    const Text('Sắp xếp theo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: tempSortBy,
                      isExpanded: true,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'date_desc', child: Text('Mới nhất (Ngày tạo giảm dần)')),
                        DropdownMenuItem(value: 'date_asc', child: Text('Cũ nhất (Ngày tạo tăng dần)')),
                        DropdownMenuItem(value: 'name_asc', child: Text('Tên: A → Z')),
                        DropdownMenuItem(value: 'name_desc', child: Text('Tên: Z → A')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() => tempSortBy = val);
                        }
                      },
                    ),
                    const SizedBox(height: 24),

                    // Nút Áp dụng
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF3F51B5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () {
                          setState(() {
                            _selectedSubjectPk = tempSubjectPk;
                            _selectedCategory = tempCategory;
                            _selectedType = tempType;
                            _selectedTag = tempTag;
                            _isPhysicalFilter = tempPhysical;
                            _isSharedWithMeFilter = tempSharedWithMe;
                            _sortBy = tempSortBy;
                          });
                          Navigator.pop(ctx);
                        },
                        child: const Text('Áp dụng bộ lọc', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textLightColor = getColor(context, 'textLight');

    return Scaffold(
      appBar: widget.showAppBar
          ? AppBar(
              title: const Text('Kho Tài Liệu'),
            )
          : null,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF3F51B5),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Thêm tài liệu'),
        onPressed: () {
          showCashewModalBottomSheet(
            context: context,
            builder: (_) => const AddEditDocumentSheet(),
          );
        },
      ),
      body: Column(
        children: [
          // Search box & Nút Lọc nâng cao
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm theo tên tài liệu hoặc ghi chú...',
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
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Badge(
                  isLabelVisible: _activeFilterCount > 0,
                  label: Text('$_activeFilterCount'),
                  child: FilledButton.tonalIcon(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.tune_rounded, size: 20),
                    label: const Text('Lọc nâng cao',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    onPressed: () => _showAdvancedFilterSheet(context),
                  ),
                ),
              ],
            ),
          ),

          // Thanh hiển thị các tiêu chí lọc đang được áp dụng (nếu có)
          if (_activeFilterCount > 0)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  ActionChip(
                    avatar: const Icon(Icons.close_rounded, size: 14),
                    label: const Text('Xóa bộ lọc',
                        style: TextStyle(
                            fontSize: 11.5, fontWeight: FontWeight.bold)),
                    onPressed: _resetAllFilters,
                  ),
                  const SizedBox(width: 8),
                  if (_selectedCategory != null) ...[
                    Chip(
                      label: Text(
                          Formatters.getCategoryName(_selectedCategory!),
                          style: const TextStyle(fontSize: 11)),
                      onDeleted: () => setState(() => _selectedCategory = null),
                    ),
                    const SizedBox(width: 6),
                  ],
                  if (_selectedType != null) ...[
                    Chip(
                      label: Text(
                          Formatters.getDocumentTypeShort(_selectedType!),
                          style: const TextStyle(fontSize: 11)),
                      onDeleted: () => setState(() => _selectedType = null),
                    ),
                    const SizedBox(width: 6),
                  ],
                  if (_isPhysicalFilter) ...[
                    const Chip(
                      avatar: Icon(Icons.location_on_rounded,
                          size: 12, color: Colors.redAccent),
                      label: Text('Sách vật lý',
                          style: TextStyle(fontSize: 11)),
                    ),
                    const SizedBox(width: 6),
                  ],
                  if (_isSharedWithMeFilter) ...[
                    Chip(
                      avatar: const Icon(Icons.folder_shared_rounded,
                          size: 12, color: Color(0xFF1976D2)),
                      label: const Text('Được chia sẻ với tôi',
                          style: TextStyle(fontSize: 11)),
                      onDeleted: () => setState(() => _isSharedWithMeFilter = false),
                    ),
                    const SizedBox(width: 6),
                  ],
                  if (_selectedTag != null) ...[
                    Chip(
                      label: Text(_selectedTag!,
                          style: const TextStyle(fontSize: 11)),
                      onDeleted: () => setState(() => _selectedTag = null),
                    ),
                    const SizedBox(width: 6),
                  ],
                  if (_selectedSubjectPk != null) ...[
                    Chip(
                      label: const Text('Đã lọc theo môn',
                          style: TextStyle(fontSize: 11)),
                      onDeleted: () => setState(() => _selectedSubjectPk = null),
                    ),
                    const SizedBox(width: 6),
                  ],
                  if (_sortBy != 'date_desc') ...[
                    Chip(
                      label: Text(
                          _sortBy == 'date_asc'
                              ? 'Cũ nhất'
                              : (_sortBy == 'name_asc' ? 'A → Z' : 'Z → A'),
                          style: const TextStyle(fontSize: 11)),
                      onDeleted: () => setState(() => _sortBy = 'date_desc'),
                    ),
                  ],
                ],
              ),
            ),

          // Reactive document stream
          Expanded(
            child: StreamBuilder<List<Document>>(
              stream: database.documentDao.watchFilteredDocuments(
                query: _searchQuery,
                subjectPk: _selectedSubjectPk,
                type: _selectedType,
                category: _selectedCategory,
                tag: _selectedTag,
                isPhysicalOnly: _isPhysicalFilter ? true : null,
                sortBy: _sortBy.startsWith('name') ? 'name' : 'date',
                ascending: _sortBy.endsWith('asc'),
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allDocs = snapshot.data ?? [];
                final myEmail = (authSyncService.user?.email ?? firebaseService.userEmail ?? '').trim().toLowerCase();

                // Lọc danh sách tài liệu hiển thị cho tài khoản hiện tại
                final docs = allDocs.where((doc) {
                  if (myEmail.isEmpty) {
                    final creator = supabaseService.getDocumentCreator(doc);
                    return creator == null || creator.isEmpty;
                  }
                  final creator = supabaseService.getDocumentCreator(doc);

                  // Nếu đang bật bộ lọc "Chỉ xem tài liệu được chia sẻ với tôi"
                  if (_isSharedWithMeFilter) {
                    return supabaseService.isDocumentSharedWithMe(doc.documentPk);
                  }

                  // 1. Nếu do chính myEmail tạo: luôn luôn hiển thị trên tài khoản này
                  if (creator == myEmail) return true;

                  // 2. Tra cứu quyền: nếu được chia sẻ cho myEmail (view/edit)
                  if (supabaseService.isDocumentSharedWithMe(doc.documentPk)) {
                    return true;
                  }

                  // 3. Tra cứu cache quyền truy cập: hiển thị nếu là chủ sở hữu hoặc có quyền xem/sửa
                  final access = supabaseService.getCachedAccessInfo(doc.documentPk);
                  if (access != null) {
                    if (access.isOwner) return true;
                    if (access.permission != 'none') return true;
                    if ((access.ownerEmail ?? '').trim().toLowerCase() == myEmail) return true;
                    return false;
                  }

                  // 4. Nếu tài liệu có người tạo là tài khoản khác và không được chia sẻ: ẩn khỏi thư viện tài liệu cá nhân
                  if (creator != null && creator.isNotEmpty && creator != myEmail) {
                    return false;
                  }
                  return true;
                }).toList();

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.menu_book_outlined,
                          size: 64,
                          color: textLightColor.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Không có tài liệu nào phù hợp',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: textLightColor,
                          ),
                        ),
                        const SizedBox(height: 12),
                        FilledButton.tonalIcon(
                          onPressed: () {
                            showCashewModalBottomSheet(
                              context: context,
                              builder: (_) => const AddEditDocumentSheet(),
                            );
                          },
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Thêm tài liệu mới'),
                        ),
                      ],
                    ),
                  );
                }

                final currentEmail = authSyncService.user?.email ?? 'guest';
                final isWide = MediaQuery.of(context).size.width >= 600;
                final listWidget = !isWide
                    ? ListView.separated(
                        key: ValueKey('docs_list_$currentEmail'),
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
                        itemCount: docs.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          return DocumentCard(document: docs[index]);
                        },
                      )
                    : GridView.builder(
                        key: ValueKey('docs_grid_$currentEmail'),
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 480,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          mainAxisExtent: 195,
                        ),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          return DocumentCard(document: docs[index]);
                        },
                      );

                return RefreshIndicator(
                  onRefresh: () async {
                    await supabaseService.syncDocumentsForCurrentAccount();
                  },
                  child: listWidget,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
