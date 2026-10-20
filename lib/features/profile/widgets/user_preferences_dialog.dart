import 'package:flutter/material.dart';
import '../../../core/services/recommendation_service.dart';

/// Hộp thoại tùy chỉnh sở thích (Tags quan tâm) phục vụ thuật toán Recommendation
class UserPreferencesDialog extends StatefulWidget {
  const UserPreferencesDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (ctx) => const UserPreferencesDialog(),
    );
  }

  @override
  State<UserPreferencesDialog> createState() => _UserPreferencesDialogState();
}

class _UserPreferencesDialogState extends State<UserPreferencesDialog> {
  final TextEditingController _tagController = TextEditingController();

  final List<String> _suggestedTags = const [
    '#CNTT',
    '#GiaiTich',
    '#DeThi',
    '#Slide',
    '#GiaoTrinh',
    '#LapTrinhDiDong',
    '#Flutter',
    '#Firebase',
    '#AI',
    '#DataScience',
    '#KienTrucMayTinh',
    '#MangMayTinh',
  ];

  @override
  void dispose() {
    _tagController.dispose();
    super.dispose();
  }

  void _addTag(String tag) {
    final cleanTag = tag.trim().startsWith('#') ? tag.trim() : '#${tag.trim()}';
    if (cleanTag.length > 1) {
      recommendationService.addPreferredTag(cleanTag);
      _tagController.clear();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final tags = recommendationService.userPreferredTags;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Row(
        children: [
          Icon(Icons.tune_rounded, color: Color(0xFF3F51B5)),
          SizedBox(width: 10),
          Text(
            'Sở Thích Tài Liệu',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Hệ thống AI sẽ phân tích độ tương đồng Jaccard dựa trên các tag bạn chọn để đưa ra top 10 tài liệu gợi ý sát nhất với nhu cầu của bạn:',
                style: TextStyle(fontSize: 13, color: Colors.grey, height: 1.3),
              ),
              const SizedBox(height: 14),

              // Danh sách tag hiện tại
              const Text(
                'Tag bạn đang quan tâm:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 8),
              if (tags.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 6.0),
                  child: Text(
                    'Chưa có tag nào được chọn. Hãy chọn từ danh sách gợi ý bên dưới.',
                    style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey),
                  ),
                )
              else
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: tags.map((t) {
                    return Chip(
                      backgroundColor: const Color(0xFF3F51B5).withValues(alpha: 0.1),
                      side: BorderSide.none,
                      label: Text(
                        t,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF3F51B5),
                        ),
                      ),
                      deleteIcon: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF3F51B5)),
                      onDeleted: () {
                        recommendationService.removePreferredTag(t);
                        setState(() {});
                      },
                    );
                  }).toList(),
                ),

              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 14),

              // Ô nhập tag mới
              const Text(
                'Thêm tag tùy chỉnh:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _tagController,
                      decoration: InputDecoration(
                        hintText: 'Nhập tag, ví dụ: #MachineLearning',
                        hintStyle: const TextStyle(fontSize: 13),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onSubmitted: (val) => _addTag(val),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF3F51B5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onPressed: () => _addTag(_tagController.text),
                    child: const Text('Thêm'),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Gợi ý tag phổ biến
              const Text(
                'Tag phổ biến trong trường:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _suggestedTags.map((t) {
                  final isSelected = tags.contains(t);
                  return ActionChip(
                    backgroundColor: isSelected ? const Color(0xFF3F51B5) : Colors.grey.withValues(alpha: 0.08),
                    label: Text(
                      t,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: isSelected ? Colors.white : Colors.black87,
                      ),
                    ),
                    onPressed: () {
                      if (isSelected) {
                        recommendationService.removePreferredTag(t);
                      } else {
                        recommendationService.addPreferredTag(t);
                      }
                      setState(() {});
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF3F51B5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () => Navigator.pop(context),
          child: const Text('Hoàn tất'),
        ),
      ],
    );
  }
}
