import 'package:flutter/material.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/database_global.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/google_sync_dialog.dart';
import '../../documents/widgets/document_card.dart';

import '../../../core/services/auth_sync_service.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  String _search = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    authSyncService.addListener(_onAuthChange);
  }

  @override
  void dispose() {
    authSyncService.removeListener(_onAuthChange);
    _searchController.dispose();
    super.dispose();
  }

  void _onAuthChange() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final textLightColor = getColor(context, 'textLight');
    final starColor = getColor(context, 'starYellow');

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star_rounded, color: starColor, size: 26),
            const SizedBox(width: 8),
            const Text('Tài Liệu Quan Trọng'),
          ],
        ),
        actions: const [
          GoogleProfileAppBarButton(),
          SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              controller: _searchController,
              onChanged: (val) =>
                  setState(() => _search = val.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Tìm kiếm tài liệu quan trọng...',
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _search.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _search = '');
                        },
                      )
                    : null,
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Document>>(
              stream: database.documentDao.watchFavoriteDocuments(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                var docs = snapshot.data ?? [];
                if (_search.isNotEmpty) {
                  docs = docs.where((d) {
                    return d.name.toLowerCase().contains(_search) ||
                        (d.note != null &&
                            d.note!.toLowerCase().contains(_search));
                  }).toList();
                }

                if (docs.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.star_outline_rounded,
                            size: 64,
                            color: textLightColor.withValues(alpha: 0.4),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _search.isNotEmpty
                                ? 'Không tìm thấy tài liệu phù hợp'
                                : 'Chưa có tài liệu quan trọng nào',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: textLightColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Bấm vào "Đánh dấu quan trọng" trên bất kỳ tài liệu nào để lưu nhanh vào danh sách này.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: textLightColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final currentEmail = authSyncService.user?.email ?? 'guest';
                final isWide = MediaQuery.of(context).size.width >= 600;
                if (!isWide) {
                  return ListView.separated(
                    key: ValueKey('fav_list_$currentEmail'),
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
                    itemCount: docs.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return DocumentCard(document: docs[index]);
                    },
                  );
                }

                return GridView.builder(
                  key: ValueKey('fav_grid_$currentEmail'),
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
