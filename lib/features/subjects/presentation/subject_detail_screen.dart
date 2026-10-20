import 'package:flutter/material.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/database_global.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/cashew_bottom_sheet.dart';
import '../../../core/widgets/google_sync_dialog.dart';
import '../../documents/widgets/add_edit_document_sheet.dart';
import '../../documents/widgets/document_card.dart';
import '../widgets/add_edit_subject_sheet.dart';

class SubjectDetailScreen extends StatefulWidget {
  final Subject subject;

  const SubjectDetailScreen({super.key, required this.subject});

  @override
  State<SubjectDetailScreen> createState() => _SubjectDetailScreenState();
}

class _SubjectDetailScreenState extends State<SubjectDetailScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.subject.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            StreamBuilder<List<Document>>(
              stream: database.documentDao
                  .watchDocumentsBySubject(widget.subject.subjectPk),
              builder: (context, snapshot) {
                final count = snapshot.data?.length ?? 0;
                return Text(
                  '${widget.subject.code} • $count tài liệu',
                  style: TextStyle(
                    fontSize: 12,
                    color: textLightColor,
                    fontWeight: FontWeight.w500,
                  ),
                );
              },
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            tooltip: 'Sửa môn học',
            onPressed: () {
              showCashewModalBottomSheet(
                context: context,
                builder: (_) => AddEditSubjectSheet(subject: widget.subject),
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
            builder: (_) => AddEditDocumentSheet(
              initialSubjectPk: widget.subject.subjectPk,
            ),
          );
        },
      ),
      body: Column(
        children: [
          // Compact Search Box
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Tìm kiếm tài liệu...',
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
              ),
            ),
          ),

          // Category Filter Chips
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
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<DocumentType?>(
                    value: _selectedType,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Loại tài liệu',
                      isDense: true,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                                size: 16,
                                color: getColor(
                                  context,
                                  Formatters.getDocumentTypeColorToken(t),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(Formatters.getDocumentTypeShort(t)),
                            ],
                          ),
                        ),
                      ),
                    ],
                    onChanged: (val) => setState(() => _selectedType = val),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _sortBy,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Sắp xếp',
                      isDense: true,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                  ),
                ),
              ],
            ),
          ),

          // Reactive document stream in pure Grid View
          Expanded(
            child: StreamBuilder<List<Document>>(
              stream: database.documentDao.watchFilteredDocuments(
                subjectPk: widget.subject.subjectPk,
                query: _searchQuery,
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
                          Icons.folder_open_rounded,
                          size: 56,
                          color: textLightColor.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Chưa có tài liệu nào trong môn học này',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: textLightColor,
                          ),
                        ),
                        const SizedBox(height: 12),
                        FilledButton.tonalIcon(
                          onPressed: () {
                            showCashewModalBottomSheet(
                              context: context,
                              builder: (_) => AddEditDocumentSheet(
                                initialSubjectPk: widget.subject.subjectPk,
                              ),
                            );
                          },
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Thêm tài liệu ngay'),
                        ),
                      ],
                    ),
                  );
                }

                final isWide = MediaQuery.of(context).size.width >= 600;
                if (!isWide) {
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
                    itemCount: docs.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return DocumentCard(document: docs[index]);
                    },
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
                  gridDelegate:
                      const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 460,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    mainAxisExtent: 132,
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
