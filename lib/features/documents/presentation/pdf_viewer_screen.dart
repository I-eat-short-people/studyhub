import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../../core/database/app_database.dart';
import '../../../core/services/file_storage_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/supabase_service.dart';

class PdfViewerScreen extends StatefulWidget {
  final Document document;

  const PdfViewerScreen({super.key, required this.document});

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  final PdfViewerController _pdfViewerController = PdfViewerController();
  bool _isLoading = true;
  String? _errorMessage;

  Future<void> _handleDownload() async {
    final doc = widget.document;
    final saved = await FileStorageService.exportFile(
      sourceFilePath: doc.filePath,
      fileUrl: doc.url,
      defaultFileName: doc.name.endsWith('.pdf') ? doc.name : '${doc.name}.pdf',
    );
    if (mounted) {
      if (saved != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã tải tài liệu "$saved" về máy thành công!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể tải xuống tệp này')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textLightColor = getColor(context, 'textLight');
    final doc = widget.document;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              doc.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Builder(
              builder: (_) {
                final cleanNote = SupabaseService.unpackCleanNote(doc.note);
                if (cleanNote.isEmpty) return const SizedBox.shrink();
                return Text(
                  cleanNote,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: textLightColor),
                );
              },
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded),
            tooltip: 'Tải xuống',
            onPressed: _handleDownload,
          ),
          if (doc.url != null &&
              !doc.url!.startsWith('data:') &&
              doc.url!.trim().isNotEmpty)
            IconButton(
              icon: const Icon(Icons.open_in_browser_rounded),
              tooltip: 'Mở bằng trình duyệt',
              onPressed: () => FileStorageService.openUrl(doc.url!),
            ),
          IconButton(
            icon: const Icon(Icons.zoom_in_rounded),
            tooltip: 'Phóng to',
            onPressed: () => _pdfViewerController.zoomLevel =
                (_pdfViewerController.zoomLevel + 0.25).clamp(1.0, 3.0),
          ),
          IconButton(
            icon: const Icon(Icons.zoom_out_rounded),
            tooltip: 'Thu nhỏ',
            onPressed: () => _pdfViewerController.zoomLevel =
                (_pdfViewerController.zoomLevel - 0.25).clamp(1.0, 3.0),
          ),
        ],
      ),
      body: Stack(
        children: [
          _buildPdfBody(),
          if (_isLoading && _errorMessage == null)
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(),
            ),
        ],
      ),
    );
  }

  Widget _buildPdfBody() {
    final doc = widget.document;

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded,
                  size: 48, color: getColor(context, 'expenseAmount')),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _handleDownload,
                icon: const Icon(Icons.download_rounded),
                label: const Text('Tải xuống tệp'),
              ),
            ],
          ),
        ),
      );
    }

    // 1. Data URI (Base64) - Works seamlessly on Web and Native
    if (doc.url != null && doc.url!.startsWith('data:')) {
      try {
        final commaIdx = doc.url!.indexOf(',');
        if (commaIdx != -1) {
          final base64Data = doc.url!.substring(commaIdx + 1);
          final bytes = base64Decode(base64Data);
          return SfPdfViewer.memory(
            bytes,
            controller: _pdfViewerController,
            onDocumentLoaded: (details) {
              setState(() => _isLoading = false);
            },
            onDocumentLoadFailed: (details) {
              setState(() {
                _isLoading = false;
                _errorMessage = 'Không thể nạp tệp PDF: ${details.description}';
              });
            },
          );
        }
      } catch (e) {
        return Center(child: Text('Lỗi nạp tệp: $e'));
      }
    }

    // 2. Local File (Native platforms: Windows, Android, iOS)
    if (!kIsWeb && doc.filePath != null && File(doc.filePath!).existsSync()) {
      return SfPdfViewer.file(
        File(doc.filePath!),
        controller: _pdfViewerController,
        onDocumentLoaded: (details) {
          setState(() => _isLoading = false);
        },
        onDocumentLoadFailed: (details) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Không thể nạp tệp PDF: ${details.description}';
          });
        },
      );
    }

    // 3. Network URL
    if (doc.url != null &&
        (doc.url!.startsWith('http://') || doc.url!.startsWith('https://'))) {
      return SfPdfViewer.network(
        doc.url!,
        controller: _pdfViewerController,
        onDocumentLoaded: (details) {
          setState(() => _isLoading = false);
        },
        onDocumentLoadFailed: (details) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Không thể nạp PDF từ liên kết: ${details.description}';
          });
        },
      );
    }

    // Empty state
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.file_present_rounded,
                size: 56, color: getColor(context, 'textLight')),
            const SizedBox(height: 16),
            const Text(
              'Tài liệu này chưa có tệp đính kèm hoặc URL hợp lệ.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
