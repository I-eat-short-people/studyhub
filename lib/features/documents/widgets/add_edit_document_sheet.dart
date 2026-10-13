import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import '../../../core/database/app_database.dart';
import '../../../core/database/database_global.dart';
import '../../../core/services/file_storage_service.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/services/auth_sync_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/cashew_bottom_sheet.dart';

enum DocumentSourceType { file, link }

class AddEditDocumentSheet extends StatefulWidget {
  final Document? document;
  final String? initialSubjectPk;

  const AddEditDocumentSheet({
    super.key,
    this.document,
    this.initialSubjectPk,
  });

  @override
  State<AddEditDocumentSheet> createState() => _AddEditDocumentSheetState();
}

class _AddEditDocumentSheetState extends State<AddEditDocumentSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _urlController;
  late TextEditingController _noteController;

  String? _selectedSubjectPk;
  DocumentSourceType _sourceType = DocumentSourceType.file;
  DocumentType _detectedType = DocumentType.pdf;
  DocumentCategory _selectedCategory = DocumentCategory.lecture;
  String? _pickedLocalPath;
  String? _pickedDataUri;
  String? _pickedFileName;
  int _fileSize = 0;
  bool _isPinned = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final doc = widget.document;
    _nameController = TextEditingController(text: doc?.name ?? '');
    _urlController = TextEditingController(text: doc?.url ?? '');
    _noteController = TextEditingController(text: doc?.note ?? '');

    _selectedSubjectPk = doc?.subjectFk ?? widget.initialSubjectPk;
    if (doc != null) {
      _selectedCategory = doc.category;
      if (doc.type == DocumentType.link) {
        _sourceType = DocumentSourceType.link;
        _detectedType = DocumentType.link;
      } else {
        _sourceType = DocumentSourceType.file;
        _detectedType = doc.type;
        _pickedFileName = doc.name;
      }
      _pickedLocalPath = doc.filePath;
      _pickedDataUri = doc.url;
      _fileSize = doc.fileSize;
      _isPinned = doc.isPinned;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  DocumentType _detectTypeFromFileName(String fileName) {
    final ext = p.extension(fileName).toLowerCase();
    if (ext == '.pdf') return DocumentType.pdf;
    if (ext == '.doc' || ext == '.docx') return DocumentType.word;
    if (ext == '.ppt' || ext == '.pptx') return DocumentType.ppt;
    return DocumentType.pdf;
  }

  Future<void> _pickFile() async {
    final picked = await FileStorageService.pickDocumentFile();
    if (picked != null) {
      setState(() {
        _pickedLocalPath = picked.path;
        _pickedDataUri = picked.dataUri;
        _fileSize = picked.size;
        _pickedFileName = picked.name;
        // Auto-detect type from file extension
        _detectedType = _detectTypeFromFileName(picked.name);
        if (_nameController.text.trim().isEmpty) {
          // Strip extension for clean title
          _nameController.text = p.basenameWithoutExtension(picked.name);
        }
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSubjectPk == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn môn học cho tài liệu')),
      );
      return;
    }

    if (_sourceType == DocumentSourceType.file &&
        _pickedLocalPath == null &&
        _pickedDataUri == null &&
        widget.document == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng bấm "Tải tệp lên" để chọn tệp tài liệu')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? savedPath = _pickedLocalPath;
      if (_pickedLocalPath != null &&
          (widget.document == null ||
              widget.document?.filePath != _pickedLocalPath)) {
        savedPath = await FileStorageService.copyFileToLocalStorage(
          _pickedLocalPath!,
          _nameController.text.trim(),
        );
      }

      String? finalUrl;
      final DocumentType finalType;
      if (_sourceType == DocumentSourceType.link) {
        finalUrl = _urlController.text.trim();
        finalType = DocumentType.link;
      } else {
        finalUrl = _pickedDataUri ?? widget.document?.url;
        finalType = _detectedType;
      }

      final docId = widget.document?.documentPk ?? uuid.v4();
      final companion = DocumentsCompanion(
        documentPk: drift.Value(docId),
        name: drift.Value(_nameController.text.trim()),
        subjectFk: drift.Value(_selectedSubjectPk!),
        type: drift.Value(finalType),
        category: drift.Value(_selectedCategory),
        filePath: drift.Value(savedPath),
        url: drift.Value(finalUrl),
        fileSize: drift.Value(_fileSize),
        note: drift.Value(
          _noteController.text.trim().isEmpty
              ? null
              : _noteController.text.trim(),
        ),
        isPinned: drift.Value(_isPinned),
      );

      await database.documentDao.insertOrUpdateDocument(companion);

      // TỰ ĐỘNG SAO LƯU LÊN SUPABASE NẾU NGƯỜI DÙNG ĐÃ ĐĂNG NHẬP
      if (supabaseService.isConfigured &&
          (firebaseService.isLoggedIn || authSyncService.isLoggedIn)) {
        final docName = _nameController.text.trim();
        final selectedSubPk = _selectedSubjectPk!;
        final selectedCat = _selectedCategory;
        final docNote = _noteController.text.trim().isEmpty ? null : _noteController.text.trim();

        final localSavedPath = savedPath;
        final localFinalUrl = finalUrl;

        // Chạy ngầm trong microtask
        Future.microtask(() async {
          try {
            Uint8List? fileBytes;
            if (localSavedPath != null && await File(localSavedPath).exists()) {
              fileBytes = await File(localSavedPath).readAsBytes();
            } else if (localFinalUrl != null && localFinalUrl.startsWith('data:')) {
              final idx = localFinalUrl.indexOf(',');
              if (idx != -1) fileBytes = base64Decode(localFinalUrl.substring(idx + 1));
            }

            if (fileBytes != null && fileBytes.isNotEmpty) {
              final subjects = await database.select(database.subjects).get();
              final subMatch = subjects.where((s) => s.subjectPk == selectedSubPk);
              final subName = subMatch.isNotEmpty ? subMatch.first.name : 'Môn học';

              final uploaded = await supabaseService.uploadAndSaveDocument(
                documentPk: docId,
                name: docName,
                subjectName: subName,
                bytes: fileBytes,
                fileName: docName.endsWith('.pdf') || docName.endsWith('.docx')
                    ? docName
                    : '$docName.pdf',
                mimeType: finalType == DocumentType.pdf
                    ? 'application/pdf'
                    : 'application/octet-stream',
                category: selectedCat.index,
                note: docNote,
              );

              if (uploaded != null && uploaded.downloadUrl != null) {
                await database.documentDao.insertOrUpdateDocument(
                  DocumentsCompanion(
                    documentPk: drift.Value(docId),
                    url: drift.Value(uploaded.downloadUrl),
                  ),
                );
                debugPrint('[AutoSync] Tự động sao lưu tài liệu "$docName" lên Supabase thành công!');
              }
            }
          } catch (autoErr) {
            debugPrint('[AutoSync] Lỗi tự động sao lưu: $autoErr');
          }
        });
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi lưu tài liệu: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xoá tài liệu?'),
        content: Text('Tài liệu "${widget.document!.name}" sẽ bị xoá.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: getColor(context, 'expenseAmount'),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xoá tài liệu'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await database.documentDao
          .deleteDocumentSafely(widget.document!.documentPk);
      if (mounted) Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.document != null;
    final textLightColor = getColor(context, 'textLight');
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 12, 24, bottomInset + 24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const CashewSheetHandle(),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEdit ? 'Sửa tài liệu' : 'Thêm tài liệu mới',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (isEdit)
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline_rounded,
                        color: getColor(context, 'expenseAmount'),
                      ),
                      onPressed: _delete,
                      tooltip: 'Xoá tài liệu',
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Subject Dropdown (isExpanded: true to prevent overflow with long names)
              StreamBuilder<List<Subject>>(
                stream: database.subjectDao.watchAllSubjects(),
                builder: (context, snapshot) {
                  final subjects = snapshot.data ?? [];
                  if (_selectedSubjectPk == null && subjects.isNotEmpty) {
                    _selectedSubjectPk = subjects.first.subjectPk;
                  }

                  return DropdownButtonFormField<String>(
                    value: _selectedSubjectPk,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Môn học',
                      prefixIcon: Icon(Icons.school_rounded),
                    ),
                    items: subjects.map((s) {
                      return DropdownMenuItem<String>(
                        value: s.subjectPk,
                        child: Text(
                          '${s.code} - ${s.name}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (val) =>
                        setState(() => _selectedSubjectPk = val),
                    validator: (val) =>
                        val == null ? 'Vui lòng chọn môn học' : null,
                  );
                },
              ),
              const SizedBox(height: 14),

              // Category Selector (Bài giảng, Tài liệu tham khảo, Bài tập, Đề kiểm tra)
              DropdownButtonFormField<DocumentCategory>(
                value: _selectedCategory,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Phân loại tài liệu',
                  prefixIcon: Icon(Icons.category_rounded),
                ),
                items: DocumentCategory.values.map((cat) {
                  return DropdownMenuItem<DocumentCategory>(
                    value: cat,
                    child: Row(
                      children: [
                        Icon(Formatters.getCategoryIcon(cat), size: 18),
                        const SizedBox(width: 8),
                        Text(Formatters.getCategoryName(cat)),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCategory = val);
                },
              ),
              const SizedBox(height: 14),

              // 2 Options: Tải tệp lên (File) vs Liên kết (Link)
              Container(
                decoration: BoxDecoration(
                  color: getColor(context, 'canvasContainer'),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: getColor(context, 'dividerColor')),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () {
                          setState(() {
                            _sourceType = DocumentSourceType.file;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _sourceType == DocumentSourceType.file
                                ? const Color(0xFF3F51B5)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.upload_file_rounded,
                                size: 18,
                                color: _sourceType == DocumentSourceType.file
                                    ? Colors.white
                                    : textLightColor,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Tệp từ máy',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: _sourceType == DocumentSourceType.file
                                      ? Colors.white
                                      : textLightColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () {
                          setState(() {
                            _sourceType = DocumentSourceType.link;
                            _detectedType = DocumentType.link;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _sourceType == DocumentSourceType.link
                                ? const Color(0xFF3F51B5)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.link_rounded,
                                size: 18,
                                color: _sourceType == DocumentSourceType.link
                                    ? Colors.white
                                    : textLightColor,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Liên kết web',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: _sourceType == DocumentSourceType.link
                                      ? Colors.white
                                      : textLightColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // File Upload or Link Input
              if (_sourceType == DocumentSourceType.file) ...[
                // Highlighted "Tải tệp lên" button
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF3F51B5),
                    foregroundColor: Colors.white,
                    elevation: 2,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _pickFile,
                  icon: const Icon(Icons.cloud_upload_rounded, color: Colors.white),
                  label: const Text(
                    'Tải tệp lên',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                // Auto-detected File Details Card
                if (_pickedFileName != null || _fileSize > 0) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: getColor(context, 'canvasContainer'),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: getColor(
                          context,
                          Formatters.getDocumentTypeColorToken(_detectedType),
                        ).withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Formatters.getDocumentTypeIcon(_detectedType),
                          color: getColor(
                            context,
                            Formatters.getDocumentTypeColorToken(_detectedType),
                          ),
                          size: 24,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _pickedFileName ?? 'Tệp đã chọn',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Loại: ${Formatters.getDocumentTypeShort(_detectedType)}${_fileSize > 0 ? " • ${Formatters.formatFileSize(_fileSize)}" : ""}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: textLightColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.check_circle_rounded,
                          color: Color(0xFF43A047),
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 14),
              ] else ...[
                TextFormField(
                  controller: _urlController,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: 'Đường dẫn liên kết (URL)',
                    hintText: 'https://...',
                    prefixIcon: Icon(Icons.link_rounded),
                  ),
                  validator: (val) {
                    if (_sourceType == DocumentSourceType.link &&
                        (val == null || val.trim().isEmpty)) {
                      return 'Vui lòng nhập đường dẫn URL';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
              ],

              // Document Name Input
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Tên tài liệu',
                  hintText: 'Nhập tiêu đề hoặc tên tài liệu',
                  prefixIcon: Icon(Icons.title_rounded),
                ),
                validator: (val) => (val == null || val.trim().isEmpty)
                    ? 'Vui lòng nhập tên tài liệu'
                    : null,
              ),
              const SizedBox(height: 14),

              // Note Input: Centered vertically when 1 line, expands when typing longer text
              TextFormField(
                controller: _noteController,
                minLines: 1,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Ghi chú',
                  hintText: 'Ghi chú',
                  prefixIcon: Icon(Icons.notes_rounded),
                ),
              ),
              const SizedBox(height: 10),

              // Pinned Switch
              SwitchListTile(
                value: _isPinned,
                onChanged: (val) => setState(() => _isPinned = val),
                title: const Text(
                  'Đánh dấu quan trọng',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                secondary: Icon(
                  _isPinned ? Icons.star_rounded : Icons.star_border_rounded,
                  color: _isPinned
                      ? getColor(context, 'starYellow')
                      : textLightColor,
                ),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 16),

              // Save Button
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF3F51B5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _isLoading ? null : _save,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        isEdit ? 'Lưu thay đổi' : 'Thêm tài liệu',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
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
