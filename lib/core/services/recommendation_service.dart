import 'package:flutter/foundation.dart';
import '../database/app_database.dart';
import '../database/database_global.dart';
import 'supabase_service.dart';

class RecommendedItem {
  final Document document;
  final double score;
  final String reason;

  const RecommendedItem({
    required this.document,
    required this.score,
    required this.reason,
  });
}

class RecommendationService extends ChangeNotifier {
  static final RecommendationService _instance = RecommendationService._internal();
  factory RecommendationService() => _instance;
  RecommendationService._internal();

  // Danh sách tags sở thích người dùng tự chọn hoặc tự động học từ tài liệu đã ghim (Favorites)
  final Set<String> _userPreferredTags = {
    '#cntt',
    '#laptrinhdidong',
    '#flutter',
    '#dethi',
  };

  Set<String> get userPreferredTags => Set.unmodifiable(_userPreferredTags);

  void setPreferredTags(Iterable<String> tags) {
    _userPreferredTags.clear();
    for (final t in tags) {
      final clean = t.trim().toLowerCase();
      if (clean.isNotEmpty) {
        _userPreferredTags.add(clean.startsWith('#') ? clean : '#$clean');
      }
    }
    notifyListeners();
  }

  void addPreferredTag(String tag) {
    final clean = tag.trim().toLowerCase();
    if (clean.isNotEmpty) {
      _userPreferredTags.add(clean.startsWith('#') ? clean : '#$clean');
      notifyListeners();
    }
  }

  void removePreferredTag(String tag) {
    final clean = tag.trim().toLowerCase();
    _userPreferredTags.remove(clean.startsWith('#') ? clean : '#$clean');
    notifyListeners();
  }

  /// Tính độ tương đồng Jaccard giữa 2 tập hợp thẻ Tag:
  /// J(A, B) = |A ∩ B| / |A ∪ B|
  double _calculateJaccardSimilarity(Set<String> setA, Set<String> setB) {
    if (setA.isEmpty || setB.isEmpty) return 0.0;
    final intersection = setA.intersection(setB).length;
    final union = setA.union(setB).length;
    if (union == 0) return 0.0;
    return intersection / union;
  }

  /// Trích xuất danh sách tags dạng Set chuẩn hóa từ chuỗi lưu trong CSDL
  Set<String> _parseTags(String rawTags) {
    if (rawTags.trim().isEmpty) return {};
    return rawTags
        .split(RegExp(r'[,;\s]+'))
        .map((t) => t.replaceAll(RegExp(r'^[#\s]+'), '').trim().toLowerCase())
        .where((t) => t.isNotEmpty)
        .map((t) => '#$t')
        .toSet();
  }

  /// Thuật toán Recommendation:
  /// Kết hợp sở thích Tag (Jaccard similarity), môn học thường xem và thời gian tạo
  Future<List<RecommendedItem>> getRecommendations({int limit = 6}) async {
    final deletedPks = await database.documentDao.getDeletedDocumentPks();
    final allDocs = (await database.select(database.documents).get())
        .where((d) => !deletedPks.contains(d.documentPk))
        .toList();
    if (allDocs.isEmpty) return [];

    // 1. Tự động bổ sung sở thích từ các tài liệu người dùng đã gắn sao (isPinned)
    final pinnedDocs = allDocs.where((d) => d.isPinned).toList();
    final dynamicPreferences = Set<String>.from(_userPreferredTags);
    final preferredSubjectFks = <String>{};

    for (final p in pinnedDocs) {
      preferredSubjectFks.add(p.subjectFk);
      dynamicPreferences.addAll(_parseTags(p.tags));
    }

    final subjects = await database.select(database.subjects).get();
    final subjectMap = {for (var s in subjects) s.subjectPk: s.name};

    final recommendations = <RecommendedItem>[];

    for (final doc in allDocs) {
      final docTags = _parseTags(doc.tags);

      // Điểm 1: Độ tương đồng Jaccard về Tag (0.0 - 1.0)
      final tagScore = _calculateJaccardSimilarity(dynamicPreferences, docTags);

      // Điểm 2: Trùng môn học yêu thích (0.0 hoặc 1.0)
      final bool subjectMatched = preferredSubjectFks.contains(doc.subjectFk);
      final subjectScore = subjectMatched ? 1.0 : 0.0;

      // Điểm 3: Tính mới của tài liệu (Recency) trong vòng 30 ngày
      final daysSinceCreated = DateTime.now().difference(doc.dateCreated).inDays;
      final recencyScore = (1.0 - (daysSinceCreated / 60)).clamp(0.1, 1.0);

      // Điểm tổng hợp trọng số:
      // Score = 50% Tag Similarity + 30% Subject Affinity + 20% Recency
      final totalScore = (tagScore * 0.5) + (subjectScore * 0.3) + (recencyScore * 0.2);

      // Tạo lời giải thích minh bạch (Explainable Reason)
      String reason = 'Tài liệu học tập mới cập nhật';
      final commonTags = dynamicPreferences.intersection(docTags);

      if (commonTags.isNotEmpty && subjectMatched) {
        reason = 'Khớp môn ${subjectMap[doc.subjectFk] ?? "học"} & tag ${commonTags.take(2).join(", ")}';
      } else if (commonTags.isNotEmpty) {
        reason = 'Cùng chủ đề bạn quan tâm: ${commonTags.take(2).join(", ")}';
      } else if (subjectMatched) {
        reason = 'Thuộc môn học bạn thường lưu: ${subjectMap[doc.subjectFk] ?? ""}';
      } else if (doc.isPinned) {
        reason = 'Tài liệu quan trọng bạn đã đánh dấu';
      }

      recommendations.add(
        RecommendedItem(
          document: doc,
          score: totalScore,
          reason: reason,
        ),
      );
    }

    // Sắp xếp theo điểm tương quan cao nhất
    recommendations.sort((a, b) => b.score.compareTo(a.score));

    return recommendations.take(limit).toList();
  }

  /// Gợi ý tài liệu cộng đồng từ Cloud cho người dùng mượn:
  /// - Loại trừ tài liệu của chính người dùng (theo email, uid, hoặc id tài liệu local)
  /// - Tính điểm tương đồng theo Tag, môn học và tính mới
  Future<List<CommunityRecommendedItem>> getCommunityRecommendations({
    required List<SupabaseDocument> communityDocs,
    required String myEmail,
    required String myUid,
    Set<String>? myLocalDocIds,
    int limit = 10,
  }) async {
    final cleanMyEmail = myEmail.trim().toLowerCase();
    final deletedPks = await database.documentDao.getDeletedDocumentPks();

    // 1. Lọc bỏ tài liệu thuộc về chính người dùng và tài liệu đã xoá
    final candidateDocs = communityDocs.where((doc) {
      if (deletedPks.contains(doc.id)) {
        return false;
      }
      final docOwnerEmail = doc.ownerEmail.trim().toLowerCase();
      if (cleanMyEmail.isNotEmpty && docOwnerEmail == cleanMyEmail) {
        return false;
      }
      if (myUid.isNotEmpty && doc.ownerUid == myUid) {
        return false;
      }
      if (myLocalDocIds != null && myLocalDocIds.contains(doc.id)) {
        return false;
      }
      return true;
    }).toList();

    if (candidateDocs.isEmpty) return [];

    // 2. Tự động lấy sở thích từ:
    // a. Các tag người dùng tự chọn (_userPreferredTags)
    // b. Tất cả tài liệu cục bộ thuộc về myEmail (cả pinned lẫn không pinned, để tự học sở thích)
    final allLocalDocs = await database.select(database.documents).get();
    final myLocalDocs = allLocalDocs.where((d) {
      final owner = supabaseService.getLocalDocumentOwner(d.documentPk);
      return owner == null || owner.isEmpty || owner == cleanMyEmail;
    }).toList();

    final dynamicPreferences = Set<String>.from(_userPreferredTags);
    final preferredSubjectNames = <String>{};

    final subjects = await database.select(database.subjects).get();
    final subjectMap = {for (var s in subjects) s.subjectPk: s.name.toLowerCase()};

    for (final doc in myLocalDocs) {
      final subName = subjectMap[doc.subjectFk];
      if (subName != null) preferredSubjectNames.add(subName);
      dynamicPreferences.addAll(_parseTags(doc.tags));
    }

    final recommendations = <CommunityRecommendedItem>[];

    for (final doc in candidateDocs) {
      final docTags = _parseTags(doc.tags);

      // Điểm 1: Độ tương đồng Tag (kết hợp Jaccard và Overlap Ratio)
      final commonTags = dynamicPreferences.intersection(docTags);
      final jaccard = _calculateJaccardSimilarity(dynamicPreferences, docTags);
      final overlap = docTags.isNotEmpty ? (commonTags.length / docTags.length) : 0.0;
      final tagScore = commonTags.isNotEmpty
          ? (0.35 * jaccard + 0.65 * overlap).clamp(0.2, 1.0)
          : 0.0;

      // Điểm 2: Trùng môn học
      final docSubName = doc.subjectName?.trim().toLowerCase();
      final bool subjectMatched = docSubName != null && preferredSubjectNames.contains(docSubName);
      final subjectScore = subjectMatched ? 1.0 : 0.0;

      // Điểm 3: Tính mới
      final recencyScore = doc.createdAt != null
          ? (1.0 - (DateTime.now().difference(doc.createdAt!).inDays / 60)).clamp(0.2, 1.0)
          : 0.5;

      final totalScore = (tagScore * 0.55) + (subjectScore * 0.25) + (recencyScore * 0.20);

      String reason = 'Tài liệu cộng đồng sẵn sàng mượn';
      if (commonTags.isNotEmpty && subjectMatched) {
        reason = 'Khớp môn ${doc.subjectName} & tag ${commonTags.take(2).join(", ")}';
      } else if (commonTags.isNotEmpty) {
        reason = 'Cùng chủ đề: ${commonTags.take(2).join(", ")}';
      } else if (subjectMatched) {
        reason = 'Môn học bạn quan tâm: ${doc.subjectName}';
      }

      recommendations.add(
        CommunityRecommendedItem(
          document: doc,
          score: totalScore,
          reason: reason,
        ),
      );
    }

    recommendations.sort((a, b) => b.score.compareTo(a.score));
    return recommendations.take(limit).toList();
  }
}

class CommunityRecommendedItem {
  final SupabaseDocument document;
  final double score;
  final String reason;

  const CommunityRecommendedItem({
    required this.document,
    required this.score,
    required this.reason,
  });
}

final recommendationService = RecommendationService();
