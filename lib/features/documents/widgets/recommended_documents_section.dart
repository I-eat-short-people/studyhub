import 'package:flutter/material.dart';
import '../../../core/database/app_database.dart';
import '../../../core/services/recommendation_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../presentation/pdf_viewer_screen.dart';
import '../../profile/widgets/user_preferences_dialog.dart';

class RecommendedDocumentsSection extends StatefulWidget {
  const RecommendedDocumentsSection({super.key});

  @override
  State<RecommendedDocumentsSection> createState() =>
      _RecommendedDocumentsSectionState();
}

class _RecommendedDocumentsSectionState
    extends State<RecommendedDocumentsSection> {
  List<RecommendedItem> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    recommendationService.addListener(_refresh);
    _loadRecommendations();
  }

  @override
  void dispose() {
    recommendationService.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
    final list = await recommendationService.getRecommendations(limit: 5);
    if (mounted) {
      setState(() {
        _items = list;
        _isLoading = false;
      });
    }
  }

  void _showCustomizePreferencesDialog() {
    UserPreferencesDialog.show(context);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _items.isEmpty) return const SizedBox.shrink();

    final textLightColor = getColor(context, 'textLight');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3F51B5).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      size: 18,
                      color: Color(0xFF3F51B5),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Gợi ý học tập cho bạn',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  visualDensity: VisualDensity.compact,
                ),
                icon: const Icon(Icons.tune_rounded, size: 16),
                label: const Text('Sở thích', style: TextStyle(fontSize: 12)),
                onPressed: _showCustomizePreferencesDialog,
              ),
            ],
          ),
        ),

        // Danh sách thẻ gợi ý dạng vuốt ngang
        SizedBox(
          height: 130,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _items.length,
            itemBuilder: (ctx, i) {
              final item = _items[i];
              final doc = item.document;
              final percent = (item.score * 100).toInt().clamp(10, 99);

              return Container(
                width: 250,
                margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: const Color(0xFF3F51B5).withOpacity(0.15),
                    ),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      if (doc.type == DocumentType.pdf && doc.url != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PdfViewerScreen(document: doc),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Đã chọn: ${doc.name}')),
                        );
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF43A047).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '$percent% phù hợp',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2E7D32),
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Icon(
                                Formatters.getCategoryIcon(doc.category),
                                size: 14,
                                color: textLightColor,
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            doc.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13.5,
                            ),
                          ),
                          const Spacer(),
                          Row(
                            children: [
                              const Icon(
                                Icons.lightbulb_outline_rounded,
                                size: 13,
                                color: Color(0xFFFFA000),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  item.reason,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
