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
import '../../map/widgets/location_picker_dialog.dart';

enum DocumentSourceType { file, link }

class AddEditDocumentSheet extends StatefulWidget {
  final Document? document;
  final String? initialSubjectPk;
  final bool? isReadOnly;

  const AddEditDocumentSheet({
    super.key,
    this.document,
    this.initialSubjectPk,
    this.isReadOnly,
  });

  @override
  State<AddEditDocumentSheet> createState() => _AddEditDocumentSheetState();
}

class _AddEditDocumentSheetState extends State<AddEditDocumentSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _urlController;
  late TextEditingController _noteController;
  late TextEditingController _tagsController;

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
  bool _isReadOnly = false;
  DocumentAccessInfo? _accessInfo;

  // Thuộc tính Tag & Vị trí vật lý
  bool _isPhysical = false;
  bool _isAvailableForBorrow = false;
  String? _address;
  String? _physicalLocation;
  double? _latitude;
  double? _longitude;

  final List<String> _suggestedTags = [
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
    final doc = widget.document;
    final docMeta = SupabaseService.extractMetadataFromNote(doc?.note);
    final cleanNote = SupabaseService.unpackCleanNote(doc?.note);

    _nameController = TextEditingController(text: doc?.name ?? '');
    _urlController = TextEditingController(text: doc?.url ?? '');
    _noteController = TextEditingController(text: cleanNote);
    final initialTags = (doc?.tags != null && doc!.tags.isNotEmpty)
        ? doc.tags
        : (docMeta['tags'] as String? ?? '');
    _tagsController = TextEditingController(text: initialTags);

    if (widget.isReadOnly == true) {
      _isReadOnly = true;
    }

    _selectedSubjectPk = doc?.subjectFk ?? widget.initialSubjectPk;
    if (doc != null) {
      _selectedCategory = doc.category;
      if (doc.type == DocumentType.link) {
        _sourceType = DocumentSourceType.link;
        _detectedType = DocumentType.link;
      } else {
        _sourceType = DocumentSourceType.file;
        final urlLower = (doc.url ?? '').toLowerCase();
        final pathLower = (doc.filePath ?? '').toLowerCase();
        final nameLower = doc.name.toLowerCase();
        if (doc.type == DocumentType.word &&
            (urlLower.contains('.pdf') ||
                pathLower.endsWith('.pdf') ||
                nameLower.endsWith('.pdf'))) {
          _detectedType = DocumentType.pdf;
        } else {
          _detectedType = doc.type;
        }
        _pickedFileName = doc.name;
      }
      _pickedLocalPath = doc.filePath;
      _pickedDataUri = doc.url;
      _fileSize = doc.fileSize;
      _isPinned = doc.isPinned;
      _isPhysical = doc.isPhysical || (docMeta['is_physical'] as bool? ?? false);
      _isAvailableForBorrow = doc.isAvailableForBorrow || (docMeta['is_available_for_borrow'] as bool? ?? false);
      _address = doc.address ?? (docMeta['address'] as String?);
      _physicalLocation = doc.physicalLocation ?? (docMeta['physical_location'] as String?);
      _latitude = doc.latitude ?? (docMeta['latitude'] as num?)?.toDouble();
      _longitude = doc.longitude ?? (docMeta['longitude'] as num?)?.toDouble();

      // Kiểm tra quyền từ cache
      final cached = supabaseService.getCachedAccessInfo(doc.documentPk);
      if (cached != null) {
        _accessInfo = cached;
        if (widget.isReadOnly != true) {
          _isReadOnly = !cached.canEdit;
        }
      }
      _checkAccessPermission(doc.documentPk);
    }
  }

  Future<void> _checkAccessPermission(String docId) async {
    final info = await supabaseService.getDocumentAccessInfo(docId);
    if (mounted) {
      setState(() {
        _accessInfo = info;
        if (widget.isReadOnly != true) {
          _isReadOnly = !info.canEdit;
        }
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    _noteController.dispose();
    _tagsController.dispose();
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
    if (_isReadOnly) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bạn chỉ có quyền xem tài liệu này, không thể chỉnh sửa.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

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
      final currentOwnerEmail = (authSyncService.user?.email ?? firebaseService.userEmail ?? '').trim().toLowerCase();
      final userNote = _noteController.text.trim().isEmpty ? null : _noteController.text.trim();
      final packedLocalNote = SupabaseService.packMetadataIntoNote(
        note: userNote,
        tags: _tagsController.text.trim(),
        isPhysical: _isPhysical,
        isAvailableForBorrow: _isAvailableForBorrow,
        physicalLocation: _physicalLocation,
        address: _address,
        latitude: _latitude,
        longitude: _longitude,
        ownerEmail: currentOwnerEmail.isNotEmpty ? currentOwnerEmail : null,
      );

      final companion = DocumentsCompanion(
        documentPk: drift.Value(docId),
        name: drift.Value(_nameController.text.trim()),
        subjectFk: drift.Value(_selectedSubjectPk!),
        type: drift.Value(finalType),
        category: drift.Value(_selectedCategory),
        filePath: drift.Value(savedPath),
        url: drift.Value(finalUrl),
        fileSize: drift.Value(_fileSize),
        note: drift.Value(packedLocalNote),
        isPinned: drift.Value(_isPinned),
        tags: drift.Value(_tagsController.text.trim()),
        isPhysical: drift.Value(_isPhysical),
        isAvailableForBorrow: drift.Value(_isAvailableForBorrow),
        physicalLocation: drift.Value(_physicalLocation),
        address: drift.Value(_address),
        latitude: drift.Value(_latitude),
        longitude: drift.Value(_longitude),
      );

      await database.documentDao.insertOrUpdateDocument(companion);

      if (currentOwnerEmail.isNotEmpty) {
        await supabaseService.registerLocalDocOwner(docId, currentOwnerEmail);
      }

      // Đóng sheet ngay lập tức để người dùng không phải chờ đợi
      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.document != null ? 'Đã lưu thay đổi tài liệu!' : 'Đã thêm tài liệu thành công!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      // TỰ ĐỘNG ĐỒNG BỘ NỀN LÊN SUPABASE (BACKGROUND) NẾU ĐÃ ĐĂNG NHẬP
      if (supabaseService.isConfigured &&
          (firebaseService.isLoggedIn || authSyncService.isLoggedIn)) {
        final docName = _nameController.text.trim();
        final selectedSubPk = _selectedSubjectPk!;
        final selectedCat = _selectedCategory;
        final docNote = _noteController.text.trim().isEmpty ? null : _noteController.text.trim();
        final docTags = _tagsController.text.trim();
        final docIsPhysical = _isPhysical;
        final docIsBorrow = _isAvailableForBorrow;
        final docPhysicalLoc = _physicalLocation;
        final docAddress = _address;
        final docLat = _latitude;
        final docLng = _longitude;

        final localSavedPath = savedPath;
        final localFinalUrl = finalUrl;

        // Đồng bộ bất đồng bộ ở nền không làm đơ giao diện
        Future(() async {
          try {
            Uint8List? fileBytes;
            if (localSavedPath != null && await File(localSavedPath).exists()) {
              fileBytes = await File(localSavedPath).readAsBytes();
            } else if (localFinalUrl != null && localFinalUrl.startsWith('data:')) {
              final idx = localFinalUrl.indexOf(',');
              if (idx != -1) fileBytes = base64Decode(localFinalUrl.substring(idx + 1));
            }

            final subjects = await database.select(database.subjects).get();
            final subMatch = subjects.where((s) => s.subjectPk == selectedSubPk);
            final subName = subMatch.isNotEmpty ? subMatch.first.name : 'Môn học';

            final uploaded = await supabaseService.uploadAndSaveDocument(
              documentPk: docId,
              name: docName,
              subjectName: subName,
              bytes: fileBytes,
              downloadUrl: localFinalUrl,
              fileName: docName.endsWith('.pdf') ||
                      docName.endsWith('.docx') ||
                      docName.endsWith('.doc') ||
                      docName.endsWith('.pptx') ||
                      docName.endsWith('.ppt')
                  ? docName
                  : (finalType == DocumentType.pdf
                      ? '$docName.pdf'
                      : (finalType == DocumentType.word
                          ? '$docName.docx'
                          : (finalType == DocumentType.ppt
                              ? '$docName.pptx'
                              : docName))),
              mimeType: finalType == DocumentType.pdf
                  ? 'application/pdf'
                  : (finalType == DocumentType.word
                      ? 'application/msword'
                      : (finalType == DocumentType.ppt
                          ? 'application/vnd.ms-powerpoint'
                          : 'application/octet-stream')),
              category: selectedCat.index,
              note: docNote,
              tags: docTags,
              isPhysical: docIsPhysical,
              isAvailableForBorrow: docIsBorrow,
              physicalLocation: docPhysicalLoc,
              address: docAddress,
              latitude: docLat,
              longitude: docLng,
              customOwnerEmail: currentOwnerEmail,
              notify: false,
            );

            if (uploaded != null && uploaded.downloadUrl != null && uploaded.downloadUrl != localFinalUrl) {
              await database.documentDao.updateDocumentUrl(
                docId,
                uploaded.downloadUrl!,
              );
            }
            if (uploaded != null) {
              debugPrint('[AutoSync] Tự động sao lưu tài liệu "$docName" lên Supabase thành công!');
            }
          } catch (autoErr) {
            debugPrint('[AutoSync] Lỗi tự động sao lưu nền: $autoErr');
          }
        });
      }
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
    if (_accessInfo?.isOwner == false) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bạn không có quyền xoá tài liệu được chia sẻ'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

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
      final docPk = widget.document!.documentPk;
      // 1. Xoá trên Supabase Cloud
      if (supabaseService.isConfigured) {
        await supabaseService.deleteCloudDocument(docPk);
      }
      // 2. Xoá file đĩa cục bộ
      if (widget.document!.filePath != null) {
        try {
          final f = File(widget.document!.filePath!);
          if (await f.exists()) await f.delete();
        } catch (_) {}
      }
      // 3. Xoá trong SQLite
      await database.documentDao.deleteDocumentSafely(docPk);
      if (mounted) Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                  Expanded(
                    child: Text(
                      _isReadOnly
                          ? 'Chi tiết tài liệu (Chỉ xem)'
                          : (isEdit ? 'Sửa tài liệu' : 'Thêm tài liệu mới'),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isEdit && !_isReadOnly && (_accessInfo?.isOwner ?? true))
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
              const SizedBox(height: 12),

              if (_isReadOnly) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.lock_outline_rounded, color: Colors.blue.shade800, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Tài liệu này được chia sẻ bởi ${_accessInfo?.ownerEmail ?? 'chủ tài liệu'} với quyền "Chỉ xem". Bạn không thể chỉnh sửa mô tả hoặc nội dung.',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

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
                    onChanged: _isReadOnly
                        ? null
                        : (val) => setState(() => _selectedSubjectPk = val),
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
                onChanged: _isReadOnly
                    ? null
                    : (val) {
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
                        onTap: _isReadOnly
                            ? null
                            : () {
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
                        onTap: _isReadOnly
                            ? null
                            : () {
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
                  onPressed: _isReadOnly ? null : _pickFile,
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
                readOnly: _isReadOnly,
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
                readOnly: _isReadOnly,
                minLines: 1,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Ghi chú / Mô tả',
                  hintText: 'Ghi chú hoặc mô tả tài liệu',
                  prefixIcon: Icon(Icons.notes_rounded),
                ),
              ),
              const SizedBox(height: 14),

              // Tag Input
              TextFormField(
                controller: _tagsController,
                readOnly: _isReadOnly,
                decoration: const InputDecoration(
                  labelText: 'Tags phân loại (phân cách bằng dấu phẩy)',
                  hintText: 'Vd: #CNTT, #GiaiTich, #DeThi2024',
                  prefixIcon: Icon(Icons.tag_rounded),
                ),
              ),
              const SizedBox(height: 8),

              // Tag Suggestion Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _suggestedTags.map((tag) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ActionChip(
                        label: Text(tag, style: const TextStyle(fontSize: 12)),
                        onPressed: _isReadOnly
                            ? null
                            : () {
                                final current = _tagsController.text.trim();
                                if (current.isEmpty) {
                                  _tagsController.text = tag;
                                } else if (!current.contains(tag)) {
                                  _tagsController.text = '$current, $tag';
                                }
                              },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 14),

              // Physical Document Switch
              SwitchListTile(
                value: _isPhysical,
                onChanged: _isReadOnly
                    ? null
                    : (val) => setState(() => _isPhysical = val),
                title: const Text(
                  'Sách / Tài liệu giấy bản cứng',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                subtitle: const Text(
                  'Quản lý vị trí lưu trữ thực tế và cho mượn',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                secondary: Icon(
                  _isPhysical ? Icons.menu_book_rounded : Icons.menu_book_outlined,
                  color: _isPhysical ? const Color(0xFF3F51B5) : textLightColor,
                ),
                contentPadding: EdgeInsets.zero,
              ),

              // Location & Borrowing Settings when _isPhysical is true
              if (_isPhysical) ...[
                Container(
                  margin: const EdgeInsets.only(top: 8, bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3F51B5).withOpacity(0.06),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF3F51B5).withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.location_on_rounded, color: Colors.redAccent, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _address != null && _address!.isNotEmpty
                                  ? _address!
                                  : 'Chưa chọn vị trí lưu trữ',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                      if (_physicalLocation != null && _physicalLocation!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Padding(
                          padding: const EdgeInsets.only(left: 28),
                          child: Text(
                            'Chi tiết kệ/tủ: $_physicalLocation',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF3F51B5)),
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.map_rounded, size: 18),
                        label: Text(
                          _address == null ? 'Ghim vị trí trên Bản đồ' : 'Thay đổi vị trí',
                        ),
                        onPressed: _isReadOnly
                            ? null
                            : () async {
                                final res = await showDialog<LocationPickResult>(
                                  context: context,
                                  builder: (_) => LocationPickerDialog(
                                    initialAddress: _address,
                                    initialPhysicalLocation: _physicalLocation,
                                    initialLatitude: _latitude,
                                    initialLongitude: _longitude,
                                  ),
                                );
                                if (res != null) {
                                  setState(() {
                                    _address = res.address;
                                    _physicalLocation = res.physicalLocation;
                                    _latitude = res.latitude;
                                    _longitude = res.longitude;
                                  });
                                }
                              },
                      ),
                      const Divider(height: 20),
                      SwitchListTile(
                        value: _isAvailableForBorrow,
                        onChanged: _isReadOnly
                            ? null
                            : (val) => setState(() => _isAvailableForBorrow = val),
                        title: const Text(
                          'Sẵn sàng cho mượn',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        subtitle: const Text(
                          'Hiển thị trên Bản đồ cộng đồng để các bạn khác gửi yêu cầu mượn',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
              ],
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

              // Save / Close Button
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: _isReadOnly
                      ? theme.colorScheme.surfaceContainerHighest
                      : const Color(0xFF3F51B5),
                  foregroundColor: _isReadOnly
                      ? theme.colorScheme.onSurface
                      : Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _isReadOnly
                    ? () => Navigator.pop(context)
                    : (_isLoading ? null : _save),
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
                        _isReadOnly
                            ? 'Đóng'
                            : (isEdit ? 'Lưu thay đổi' : 'Thêm tài liệu'),
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
