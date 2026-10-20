import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/database_global.dart';
import '../../../core/services/auth_sync_service.dart';
import '../../../core/services/file_storage_service.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/cashew_bottom_sheet.dart';
import '../presentation/pdf_viewer_screen.dart';
import 'add_edit_document_sheet.dart';
import 'share_document_dialog.dart';

class DocumentCard extends StatelessWidget {
  final Document document;

  const DocumentCard({super.key, required this.document});

  static DocumentType resolveEffectiveType(Document doc) {
    if (doc.type == DocumentType.link) return DocumentType.link;

    final url = (doc.url ?? '').toLowerCase();
    final path = (doc.filePath ?? '').toLowerCase();
    final name = doc.name.toLowerCase();

    // Kiểm tra định dạng PDF thực tế từ url, file path, hoặc đuôi tên
    if (url.contains('.pdf') || path.endsWith('.pdf') || name.endsWith('.pdf')) {
      return DocumentType.pdf;
    }

    // Kiểm tra PPT
    if (url.contains('.ppt') ||
        url.contains('.pptx') ||
        path.endsWith('.ppt') ||
        path.endsWith('.pptx') ||
        name.endsWith('.ppt') ||
        name.endsWith('.pptx')) {
      return DocumentType.ppt;
    }

    // Kiểm tra Word
    if (url.contains('.doc') ||
        url.contains('.docx') ||
        path.endsWith('.doc') ||
        path.endsWith('.docx') ||
        name.endsWith('.doc') ||
        name.endsWith('.docx')) {
      return DocumentType.word;
    }

    return doc.type;
  }

  Future<void> _handlePrimaryAction(BuildContext context) async {
    final effectiveType = resolveEffectiveType(document);
    if (effectiveType == DocumentType.pdf) {
      if (document.filePath != null || document.url != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PdfViewerScreen(
              document: document.type == effectiveType
                  ? document
                  : document.copyWith(type: effectiveType),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không tìm thấy tệp PDF')),
        );
      }
    } else if (effectiveType == DocumentType.link) {
      if (document.url != null && document.url!.isNotEmpty) {
        final uri = Uri.tryParse(document.url!);
        if (uri != null && await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Không thể mở liên kết này')),
            );
          }
        }
      }
    }
  }

  Future<void> _handleDownload(BuildContext context) async {
    final savedPath = await FileStorageService.exportFile(
      sourceFilePath: document.filePath,
      fileUrl: document.url,
      defaultFileName: document.name,
    );
    if (!context.mounted) return;
    if (savedPath != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã tải xuống "${document.name}" thành công')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể tải xuống tài liệu này')),
      );
    }
  }

  void _showLocationInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.location_on_rounded, color: Colors.redAccent, size: 20),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Vị trí tài liệu vật lý',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tên sách: ${document.name}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 12),
              if (document.physicalLocation != null &&
                  document.physicalLocation!.isNotEmpty) ...[
                const Text('Ngăn / Kệ / Tủ:',
                    style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey, fontSize: 13)),
                Text(document.physicalLocation!,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
              ],
              if (document.address != null && document.address!.isNotEmpty) ...[
                const Text('Địa điểm / Khuôn viên:',
                    style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey, fontSize: 13)),
                Text(document.address!, style: const TextStyle(fontSize: 13.5)),
                const SizedBox(height: 8),
              ],
              if (document.latitude != null && document.longitude != null)
                Text(
                  'Tọa độ GPS: ${document.latitude!.toStringAsFixed(4)}, ${document.longitude!.toStringAsFixed(4)}',
                  style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveType = resolveEffectiveType(document);

    // Tự động đồng bộ lại loại tài liệu trong SQLite nếu phát hiện tài liệu trước đây bị lưu nhầm là Word
    if (effectiveType != document.type) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        database.documentDao.updateDocumentType(document.documentPk, effectiveType);
      });
    }

    final textLightColor = getColor(context, 'textLight');
    final cardColor = getColor(context, 'lightDarkAccent');
    final typeColorToken =
        Formatters.getDocumentTypeColorToken(effectiveType);
    final typeColor = getColor(context, typeColorToken);

    final canPreview = effectiveType == DocumentType.pdf ||
        effectiveType == DocumentType.link;

    return FutureBuilder<DocumentAccessInfo>(
      initialData: supabaseService.getCachedAccessInfo(document.documentPk),
      future: supabaseService.getDocumentAccessInfo(document.documentPk),
      builder: (context, accessSnapshot) {
        final accessInfo = accessSnapshot.data ??
            const DocumentAccessInfo(isOwner: true, canEdit: true);
        final myEmail = (authSyncService.user?.email ?? firebaseService.userEmail ?? '').trim().toLowerCase();
        final creator = supabaseService.getDocumentCreator(document);
        final effectiveIsOwner = (creator == myEmail && myEmail.isNotEmpty) ? true : accessInfo.isOwner;
        final isOwner = effectiveIsOwner;
        final canEdit = effectiveIsOwner ? true : accessInfo.canEdit;
        final ownerEmail = (creator ?? accessInfo.ownerEmail ?? myEmail).trim().toLowerCase();

        // Nếu là tài liệu trên Cloud của tài khoản khác và KHÔNG được chia sẻ cho tôi -> Ẩn hoàn toàn khỏi thư viện
        if (!isOwner && accessInfo.permission == 'none' && ownerEmail != myEmail && myEmail.isNotEmpty) {
          return const SizedBox.shrink();
        }

        return InkWell(
          onTap: canPreview ? () => _handlePrimaryAction(context) : null,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: getColor(context, 'dividerColor'),
                width: 1.2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Row: Type Icon + Title & Subject + Star Button
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Type Icon Badge
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: typeColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Formatters.getDocumentTypeIcon(effectiveType),
                        color: typeColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Title and Subject Tag
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Subject badge
                          FutureBuilder<Subject?>(
                            future: database.subjectDao
                                .getSubject(document.subjectFk),
                            builder: (context, snapshot) {
                              final subject = snapshot.data;
                              if (subject == null) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 2),
                                child: Text(
                                  '${subject.code} - ${subject.name}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(subject.color),
                                  ),
                                ),
                              );
                            },
                          ),
                          Text(
                            document.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Star Button
                    IconButton(
                      icon: Icon(
                        document.isPinned
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: document.isPinned
                            ? getColor(context, 'starYellow')
                            : textLightColor,
                        size: 24,
                      ),
                      onPressed: () {
                        database.documentDao
                            .togglePinned(document.documentPk, !document.isPinned);
                      },
                      tooltip: 'Đánh dấu quan trọng',
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                // Metadata row: Type badge, Size, and Category badge (Không hiển thị mô tả)
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: typeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        Formatters.getDocumentTypeShort(effectiveType),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: typeColor,
                        ),
                      ),
                    ),
                    // Category Badge
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blueGrey.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Formatters.getCategoryIcon(document.category),
                            size: 12,
                            color: textLightColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            Formatters.getCategoryName(document.category),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: textLightColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (document.isPhysical) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.location_on_rounded, size: 12, color: Colors.redAccent),
                            const SizedBox(width: 4),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 130),
                              child: Text(
                                document.physicalLocation ?? (document.address ?? 'Sách giấy'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.redAccent,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (document.fileSize > 0) ...[
                      Text(
                        Formatters.formatFileSize(document.fileSize),
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: textLightColor,
                        ),
                      ),
                    ],
                  ],
                ),

                // Tags chips
                if (document.tags.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: document.tags
                        .split(',')
                        .map((t) => t.trim())
                        .where((t) => t.isNotEmpty)
                        .take(4)
                        .map((tag) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF3F51B5).withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                tag.startsWith('#') ? tag : '#$tag',
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF3F51B5),
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ],

                const SizedBox(height: 4),
                const Divider(height: 6, thickness: 0.5),

                // Bottom Action Bar: Avatar bên trái & Icon thao tác bên phải
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Avatar của chủ sở hữu: CĂN TRÁI CARD, CHỈ HIỆN KHI LÀ TÀI LIỆU CỦA NGƯỜI KHÁC
                    if (!isOwner) ...[
                      Tooltip(
                        message: 'Tài liệu của: $ownerEmail (Chạm để xem)',
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Tài liệu được chia sẻ bởi: $ownerEmail'),
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 3),
                              ),
                            );
                          },
                          child: CircleAvatar(
                            radius: 12,
                            backgroundColor: const Color(0xFF1976D2),
                            child: Text(
                              ownerEmail.isNotEmpty ? ownerEmail[0].toUpperCase() : '?',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                    if (!isOwner) const SizedBox(width: 8),

                    // Action buttons wrapped in Expanded to use full remaining width without cutting off leftmost icons
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                            // Slot 0: Location Icon (Vị trí sách giấy vật lý)
                            if (document.isPhysical)
                              SizedBox(
                                width: 36,
                                height: 32,
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  icon: const Icon(Icons.place_outlined,
                                      size: 20, color: Colors.redAccent),
                                  tooltip: 'Xem vị trí sách & kệ',
                                  onPressed: () => _showLocationInfoDialog(context),
                                ),
                              ),

                            // Slot 1: Preview Icon
                            SizedBox(
                              width: 36,
                              height: 32,
                              child: effectiveType == DocumentType.pdf
                                  ? IconButton(
                                      padding: EdgeInsets.zero,
                                      icon: Icon(Icons.visibility_rounded,
                                          size: 19, color: typeColor),
                                      tooltip: 'Xem trước',
                                      onPressed: () => _handlePrimaryAction(context),
                                    )
                                  : effectiveType == DocumentType.link
                                      ? IconButton(
                                          padding: EdgeInsets.zero,
                                          icon: Icon(Icons.open_in_new_rounded,
                                              size: 19, color: typeColor),
                                          tooltip: 'Mở liên kết',
                                          onPressed: () => _handlePrimaryAction(context),
                                        )
                                      : const SizedBox.shrink(),
                            ),

                            // Slot 2: Download Icon
                            SizedBox(
                              width: 36,
                              height: 32,
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                icon: Icon(Icons.download_rounded,
                                    size: 19, color: textLightColor),
                                tooltip: 'Tải xuống',
                                onPressed: () => _handleDownload(context),
                              ),
                            ),

                            // Slot 2.5: Share Icon (Chủ sở hữu hoặc người được cấp quyền sửa đều có thể chia sẻ)
                            if (isOwner || canEdit)
                              SizedBox(
                                width: 36,
                                height: 32,
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  icon: const Icon(
                                    Icons.share_outlined,
                                    size: 19,
                                    color: Color(0xFF2E7D32),
                                  ),
                                  tooltip: 'Chia sẻ tài liệu',
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (_) =>
                                          ShareDocumentDialog(document: document),
                                    );
                                  },
                                ),
                              ),

                            // Slot 3: Edit Icon
                            SizedBox(
                              width: 36,
                              height: 32,
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                icon: Icon(
                                  canEdit ? Icons.edit_outlined : Icons.lock_outline_rounded,
                                  size: 19,
                                  color: canEdit ? textLightColor : Colors.amber.shade800,
                                ),
                                tooltip: canEdit ? 'Chỉnh sửa' : 'Chỉ xem (Không thể chỉnh sửa)',
                                onPressed: () {
                                  showCashewModalBottomSheet(
                                    context: context,
                                    builder: (_) => AddEditDocumentSheet(
                                      document: document.type == effectiveType
                                          ? document
                                          : document.copyWith(type: effectiveType),
                                      isReadOnly: !canEdit,
                                    ),
                                  );
                                },
                              ),
                            ),

                            // Slot 4: Delete Icon (CHỈ CHỦ SỞ HỮU MỚI CÓ QUYỀN XOÁ)
                            if (isOwner)
                              SizedBox(
                                width: 36,
                                height: 32,
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  icon: Icon(Icons.delete_outline_rounded,
                                      size: 19, color: getColor(context, 'expenseAmount')),
                                  tooltip: 'Xoá tài liệu',
                                  onPressed: () async {
                                    final confirmed = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('Xác nhận xoá tài liệu?'),
                                        content: Text(
                                          'Tài liệu "${document.name}" sẽ bị xoá vĩnh viễn trên máy và trên Cloud Storage.',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(ctx, false),
                                            child: const Text('Huỷ'),
                                          ),
                                          FilledButton(
                                            style: FilledButton.styleFrom(
                                              backgroundColor:
                                                  getColor(context, 'expenseAmount'),
                                            ),
                                            onPressed: () => Navigator.pop(ctx, true),
                                            child: const Text('Xoá'),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirmed == true) {
                                      // 1. Xoá trên Supabase Storage & Database
                                      if (supabaseService.isConfigured) {
                                        await supabaseService.deleteCloudDocument(document.documentPk);
                                      }
                                      // 2. Xoá file đĩa cục bộ
                                      if (document.filePath != null) {
                                        try {
                                          final f = File(document.filePath!);
                                          if (await f.exists()) await f.delete();
                                        } catch (_) {}
                                      }
                                      // 3. Xoá trong SQLite
                                      await database.documentDao.deleteDocumentSafely(document.documentPk);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Đã xoá "${document.name}" thành công'),
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                      }
                                    }
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              ],
            ),
          ),
        );
      },
    );
  }
}
