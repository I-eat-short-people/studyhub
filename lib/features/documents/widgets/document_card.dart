import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/database_global.dart';
import '../../../core/database/tables/documents_table.dart';
import '../../../core/services/file_storage_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/cashew_bottom_sheet.dart';
import '../presentation/pdf_viewer_screen.dart';
import 'add_edit_document_sheet.dart';
import 'share_document_dialog.dart';

class DocumentCard extends StatelessWidget {
  final Document document;

  const DocumentCard({super.key, required this.document});

  Future<void> _handlePrimaryAction(BuildContext context) async {
    if (document.type == DocumentType.pdf) {
      if (document.filePath != null || document.url != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PdfViewerScreen(
              document: document,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không tìm thấy tệp PDF')),
        );
      }
    } else if (document.type == DocumentType.link) {
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

  @override
  Widget build(BuildContext context) {
    final textLightColor = getColor(context, 'textLight');
    final cardColor = getColor(context, 'lightDarkAccent');
    final typeColorToken =
        Formatters.getDocumentTypeColorToken(document.type);
    final typeColor = getColor(context, typeColorToken);

    final canPreview = document.type == DocumentType.pdf ||
        document.type == DocumentType.link;

    return InkWell(
      onTap: canPreview ? () => _handlePrimaryAction(context) : null,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
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
            // Top Row: Type Icon + Title & Subject + Star
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
                    Formatters.getDocumentTypeIcon(document.type),
                    color: typeColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                // Title and Subject Tag (Fixed overflow for long subject name)
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
                // Star Button with simple UX writing
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

            // Note Field: Plain light grey text, no grey background, no line border
            if (document.note != null && document.note!.trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                document.note!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: textLightColor.withValues(alpha: 0.85),
                  height: 1.25,
                ),
              ),
            ],

            const SizedBox(height: 6),

            // Metadata row: Type badge, Size, and Category badge
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    Formatters.getDocumentTypeShort(document.type),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: typeColor,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                // Category Badge (Bài giảng, Tài liệu tham khảo, Bài tập, Đề kiểm tra)
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
                if (document.fileSize > 0) ...[
                  const SizedBox(width: 6),
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

            const SizedBox(height: 6),
            const Divider(height: 1),

            // Bottom Action Bar: Exactly 4 strictly aligned slots
            // If cannot preview, keep Slot 1 as an empty 40px SizedBox so other 3 icons NEVER shift or stretch!
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Slot 1: Preview Icon (or fixed empty space)
                SizedBox(
                  width: 40,
                  height: 38,
                  child: document.type == DocumentType.pdf
                      ? IconButton(
                          padding: EdgeInsets.zero,
                          icon: Icon(Icons.visibility_rounded,
                              size: 20, color: typeColor),
                          tooltip: 'Xem trước',
                          onPressed: () => _handlePrimaryAction(context),
                        )
                      : document.type == DocumentType.link
                          ? IconButton(
                              padding: EdgeInsets.zero,
                              icon: Icon(Icons.open_in_new_rounded,
                                  size: 20, color: typeColor),
                              tooltip: 'Mở liên kết',
                              onPressed: () => _handlePrimaryAction(context),
                            )
                          : const SizedBox.shrink(),
                ),

                // Slot 2: Download Icon
                SizedBox(
                  width: 40,
                  height: 38,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: Icon(Icons.download_rounded,
                        size: 20, color: textLightColor),
                    tooltip: 'Tải xuống',
                    onPressed: () => _handleDownload(context),
                  ),
                ),

                // Slot 2.5: Share Icon
                SizedBox(
                  width: 40,
                  height: 38,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.share_outlined,
                        size: 20, color: Color(0xFF2E7D32)),
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
                  width: 40,
                  height: 38,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: Icon(Icons.edit_outlined,
                        size: 20, color: textLightColor),
                    tooltip: 'Chỉnh sửa',
                    onPressed: () {
                      showCashewModalBottomSheet(
                        context: context,
                        builder: (_) =>
                            AddEditDocumentSheet(document: document),
                      );
                    },
                  ),
                ),

                // Slot 4: Delete Icon
                SizedBox(
                  width: 40,
                  height: 38,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: Icon(Icons.delete_outline_rounded,
                        size: 20, color: getColor(context, 'expenseAmount')),
                    tooltip: 'Xoá',
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Xác nhận xoá tài liệu?'),
                          content:
                              Text('Tài liệu "${document.name}" sẽ bị xoá.'),
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
                        await database.documentDao
                            .deleteDocumentSafely(document.documentPk);
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
