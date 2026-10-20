import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyhub/core/database/app_database.dart';
import 'package:studyhub/core/database/database_global.dart';
import 'package:studyhub/core/services/recommendation_service.dart';
import 'package:studyhub/core/services/supabase_service.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    database = db;

    // Seed test subject
    await db.subjectDao.insertOrUpdateSubject(
      const SubjectsCompanion(
        subjectPk: Value('sub-mob-01'),
        name: Value('Lập trình di động'),
        code: Value('CSE441'),
      ),
    );

    await db.subjectDao.insertOrUpdateSubject(
      const SubjectsCompanion(
        subjectPk: Value('sub-ai-02'),
        name: Value('Trí tuệ nhân tạo'),
        code: Value('AI301'),
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('1. Kiểm thử Quản lý Tag và Vị trí vật lý (Persistence & DAO)', () {
    test('Thêm tài liệu vật lý kèm tọa độ GPS và Kệ tủ', () async {
      await db.documentDao.insertOrUpdateDocument(
        const DocumentsCompanion(
          documentPk: Value('doc-book-01'),
          name: Value('Giáo trình Flutter & Clean Architecture'),
          subjectFk: Value('sub-mob-01'),
          type: Value(DocumentType.pdf),
          tags: Value('#flutter, #mobile, #architecture'),
          isPhysical: Value(true),
          isAvailableForBorrow: Value(true),
          address: Value('Thư viện Tạ Quang Bửu - ĐHBK Hà Nội'),
          physicalLocation: Value('Tủ A2, Kệ 3, Ngăn 1'),
          latitude: Value(21.0049),
          longitude: Value(105.8458),
        ),
      );

      final doc = await db.documentDao.getDocument('doc-book-01');
      expect(doc, isNotNull);
      expect(doc!.isPhysical, true);
      expect(doc.isAvailableForBorrow, true);
      expect(doc.address, 'Thư viện Tạ Quang Bửu - ĐHBK Hà Nội');
      expect(doc.physicalLocation, 'Tủ A2, Kệ 3, Ngăn 1');
      expect(doc.latitude, closeTo(21.0049, 0.0001));
      expect(doc.longitude, closeTo(105.8458, 0.0001));
    });

    test('Lọc tài liệu theo Tag cụ thể', () async {
      await db.documentDao.insertOrUpdateDocument(
        const DocumentsCompanion(
          documentPk: Value('doc-01'),
          name: Value('Tài liệu Toán Rời Rạc'),
          subjectFk: Value('sub-mob-01'),
          type: Value(DocumentType.pdf),
          tags: Value('#toan, #giaithuat'),
        ),
      );

      await db.documentDao.insertOrUpdateDocument(
        const DocumentsCompanion(
          documentPk: Value('doc-02'),
          name: Value('Machine Learning cơ bản'),
          subjectFk: Value('sub-ai-02'),
          type: Value(DocumentType.pdf),
          tags: Value('#ai, #python'),
        ),
      );

      // Lọc tag #toan
      final mathResults = await db.documentDao
          .watchFilteredDocuments(tag: '#toan')
          .first;
      expect(mathResults.length, 1);
      expect(mathResults.first.documentPk, 'doc-01');

      // Lọc tag #ai
      final aiResults = await db.documentDao
          .watchFilteredDocuments(tag: '#ai')
          .first;
      expect(aiResults.length, 1);
      expect(aiResults.first.documentPk, 'doc-02');
    });

    test('Truy vấn danh sách sách vật lý cho Bản đồ (watchPhysicalDocuments)', () async {
      await db.documentDao.insertOrUpdateDocument(
        const DocumentsCompanion(
          documentPk: Value('doc-soft-01'),
          name: Value('Slide PDF trực tuyến'),
          subjectFk: Value('sub-mob-01'),
          type: Value(DocumentType.pdf),
          isPhysical: Value(false),
        ),
      );

      await db.documentDao.insertOrUpdateDocument(
        const DocumentsCompanion(
          documentPk: Value('doc-hard-01'),
          name: Value('Sách giáo trình bản cứng'),
          subjectFk: Value('sub-mob-01'),
          type: Value(DocumentType.pdf),
          isPhysical: Value(true),
          latitude: Value(21.0049),
          longitude: Value(105.8458),
        ),
      );

      final physicalDocs = await db.documentDao.watchPhysicalDocuments().first;
      expect(physicalDocs.length, 1);
      expect(physicalDocs.first.documentPk, 'doc-hard-01');
    });
  });

  group('2. Kiểm thử Thuật toán Recommendation (Gợi ý tài liệu)', () {
    test('Xếp hạng tài liệu theo độ tương đồng sở thích Tag và Môn học', () async {
      // 1. Thêm các tài liệu có tags khác nhau
      await db.documentDao.insertOrUpdateDocument(
        const DocumentsCompanion(
          documentPk: Value('rec-flutter'),
          name: Value('Học Flutter từ cơ bản đến nâng cao'),
          subjectFk: Value('sub-mob-01'),
          type: Value(DocumentType.pdf),
          tags: Value('#flutter, #mobile, #dart'),
        ),
      );

      await db.documentDao.insertOrUpdateDocument(
        const DocumentsCompanion(
          documentPk: Value('rec-cooking'),
          name: Value('Cẩm nang nấu ăn sinh viên'),
          subjectFk: Value('sub-ai-02'),
          type: Value(DocumentType.pdf),
          tags: Value('#monan, #bep'),
        ),
      );

      // 2. Thiết lập sở thích người dùng quan tâm đến #flutter và #mobile
      recommendationService.setPreferredTags(['#flutter', '#mobile']);

      // 3. Chạy thuật toán gợi ý
      final recommendations = await recommendationService.getRecommendations();

      expect(recommendations.isNotEmpty, true);
      expect(recommendations.first.document.documentPk, 'rec-flutter');
      expect(recommendations.first.score, greaterThan(0.3));
      expect(recommendations.first.reason, contains('#flutter'));
    });
  });

  group('3. Kiểm thử Vòng đời Mượn tài liệu P2P (Borrow Requests Model)', () {
    test('Parse và chuyển đổi trạng thái mượn sách', () {
      final json = {
        'id': 'req-123',
        'document_id': 'doc-book-01',
        'document_name': 'Giáo trình Flutter',
        'borrower_uid': 'user-b',
        'borrower_email': 'svb@gmail.com',
        'borrower_name': 'Sinh viên B',
        'owner_uid': 'user-a',
        'owner_email': 'sva@gmail.com',
        'status': 'approved',
        'borrow_date': '2026-10-17T10:00:00Z',
        'due_date': '2026-10-24T10:00:00Z',
        'note': 'Em mượn sách chuẩn bị thi ạ',
        'physical_location': 'Tủ A2, Kệ 3, Ngăn 1',
        'address': 'ĐH Bách Khoa',
      };

      final req = SupabaseBorrowRequest.fromJson(json);
      expect(req.id, 'req-123');
      expect(req.documentName, 'Giáo trình Flutter');
      expect(req.borrowerEmail, 'svb@gmail.com');
      expect(req.status, 'approved');
      expect(req.dueDate, isNotNull);
      expect(req.physicalLocation, 'Tủ A2, Kệ 3, Ngăn 1');
      expect(req.address, 'ĐH Bách Khoa');
    });
  });
}
