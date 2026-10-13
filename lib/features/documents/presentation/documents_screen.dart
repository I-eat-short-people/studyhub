import 'package:flutter/material.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/database_global.dart';
import '../../../core/database/tables/documents_table.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/cashew_bottom_sheet.dart';
import '../../../core/widgets/google_sync_dialog.dart';
import '../widgets/add_edit_document_sheet.dart';
import '../widgets/document_card.dart';
import 'shared_documents_screen.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedSubjectPk;
  DocumentType? _selectedType;
  DocumentCategory? _selectedCategory;
  String _sortBy = 'date_desc'; // 'date_desc', 'date_asc', 'name_asc', 'name_desc'

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textLightColor = getColor(context, 'textLight');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kho Tài Liệu Học Tập'),
        actions: [
          IconButton(
            icon: const Icon(Icons.folder_shared_outlined),
            tooltip: 'Tài liệu được chia sẻ với tôi',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SharedDocumentsScreen(),
                ),
              );
            },
          ),
          const GoogleProfileAppBarButton(),
          const SizedBox(width: 8),
        ],
      ),
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
          // Search box
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Tìm kiếm theo tên tài liệu hoặc ghi chú...',
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
              ),
            ),
          ),

          // Category Filter Chips (Bài giảng, Tài liệu tham khảo, Bài tập, Đề kiểm tra)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                ChoiceChip(
                  selected: _selectedCategory == null,
                  label: const Text('Tất cả'),
                  onSelected: (val) =>
                      setState(() => _selectedCategory = null),
                ),
                const SizedBox(width: 8),
                ...DocumentCategory.values.map((cat) {
                  final isSelected = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      selected: isSelected,
                      avatar: Icon(Formatters.getCategoryIcon(cat), size: 16),
                      label: Text(Formatters.getCategoryName(cat)),
                      onSelected: (val) => setState(
                          () => _selectedCategory = val ? cat : null),
                    ),
                  );
                }),
              ],
            ),
          ),

          // Unified Dropdown Filter Row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 600;

                final subjectDropdown = StreamBuilder<List<Subject>>(
                  stream: database.subjectDao.watchAllSubjects(),
                  builder: (context, snapshot) {
                    final subjects = snapshot.data ?? [];
                    return DropdownButtonFormField<String?>(
                      value: _selectedSubjectPk,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Môn học',
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Tất cả môn học'),
                        ),
                        ...subjects.map(
                          (s) => DropdownMenuItem<String?>(
                            value: s.subjectPk,
                            child: Text(
                              '${s.code} - ${s.name}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                      onChanged: (val) => setState(() => _selectedSubjectPk = val),
                    );
                  },
                );

                final typeDropdown = DropdownButtonFormField<DocumentType?>(
                  value: _selectedType,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Loại tài liệu',
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  items: [
                    const DropdownMenuItem<DocumentType?>(
                      value: null,
                      child: Text('Tất cả loại'),
                    ),
                    ...DocumentType.values.map(
                      (t) => DropdownMenuItem<DocumentType?>(
                        value: t,
                        child: Row(
                          children: [
                            Icon(
                              Formatters.getDocumentTypeIcon(t),
                              size: 18,
                              color: getColor(
                                context,
                                Formatters.getDocumentTypeColorToken(t),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(Formatters.getDocumentTypeShort(t)),
                          ],
                        ),
                      ),
                    ),
                  ],
                  onChanged: (val) => setState(() => _selectedType = val),
                );

                final sortDropdown = DropdownButtonFormField<String>(
                  value: _sortBy,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Sắp xếp',
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'date_desc',
                      child: Text('Mới nhất'),
                    ),
                    DropdownMenuItem(
                      value: 'date_asc',
                      child: Text('Cũ nhất'),
                    ),
                    DropdownMenuItem(
                      value: 'name_asc',
                      child: Text('Tên: A → Z'),
                    ),
                    DropdownMenuItem(
                      value: 'name_desc',
                      child: Text('Tên: Z → A'),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _sortBy = val);
                  },
                );

                if (isNarrow) {
                  return Column(
                    children: [
                      subjectDropdown,
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(child: typeDropdown),
                          const SizedBox(width: 10),
                          Expanded(child: sortDropdown),
                        ],
                      ),
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(flex: 4, child: subjectDropdown),
                    const SizedBox(width: 12),
                    Expanded(flex: 3, child: typeDropdown),
                    const SizedBox(width: 12),
                    Expanded(flex: 3, child: sortDropdown),
                  ],
                );
              },
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
                sortBy: _sortBy.startsWith('name') ? 'name' : 'date',
                ascending: _sortBy.endsWith('asc'),
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data ?? [];

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

                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
                  gridDelegate:
                      const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 460,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    mainAxisExtent: 220,
                  ),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    return DocumentCard(document: docs[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
