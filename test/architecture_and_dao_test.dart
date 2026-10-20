import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyhub/core/database/app_database.dart';
import 'package:studyhub/core/database/tables/delete_logs_table.dart';
import 'package:studyhub/core/database/tables/documents_table.dart';
import 'package:studyhub/core/theme/app_colors.dart';
import 'package:studyhub/core/utils/formatters.dart';
import 'package:studyhub/core/services/supabase_service.dart';
import 'package:flutter/material.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    // Isolated In-Memory SQLite database ensuring pure persistence layer testing
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('Kiểm thử tầng CSDL (Persistence Layer) & DAOs', () {
    test('SubjectDao: Thêm môn học và truy vấn danh sách', () async {
      await db.subjectDao.insertOrUpdateSubject(
        const SubjectsCompanion(
          subjectPk: Value('sub-01'),
          name: Value('Lập trình di động'),
          code: Value('CSE441'),
          color: Value(0xFF3F51B5),
          icon: Value('smartphone'),
        ),
      );

      final subjects = await db.subjectDao.getAllSubjects();
      expect(subjects.length, 1);
      expect(subjects.first.name, 'Lập trình di động');
      expect(subjects.first.code, 'CSE441');
    });

    test('DocumentDao: Thêm tài liệu và phát sinh Reactive Stream', () async {
      // 1. Tạo môn học trước
      await db.subjectDao.insertOrUpdateSubject(
        const SubjectsCompanion(
          subjectPk: Value('sub-01'),
          name: Value('Lập trình di động'),
          code: Value('CSE441'),
        ),
      );

      // 2. Thêm tài liệu PDF
      await db.documentDao.insertOrUpdateDocument(
        const DocumentsCompanion(
          documentPk: Value('doc-01'),
          name: Value('Slide Kiến trúc Cashew'),
          subjectFk: Value('sub-01'),
          type: Value(DocumentType.pdf),
          fileSize: Value(2048500),
          isPinned: Value(true),
        ),
      );

      final doc = await db.documentDao.getDocument('doc-01');
      expect(doc, isNotNull);
      expect(doc!.name, 'Slide Kiến trúc Cashew');
      expect(doc.type, DocumentType.pdf);
      expect(doc.isPinned, isTrue);

      // Kiểm thử đếm số lượng tài liệu theo môn học
      final count = await db.documentDao.countDocumentsBySubject('sub-01');
      expect(count, 1);
    });

    test('DocumentDao: Đánh dấu quan trọng (Ghim/Gắn sao) và lọc danh sách',
        () async {
      await db.subjectDao.insertOrUpdateSubject(
        const SubjectsCompanion(
          subjectPk: Value('sub-01'),
          name: Value('Toán rời rạc'),
          code: Value('MAT101'),
        ),
      );

      await db.documentDao.insertOrUpdateDocument(
        const DocumentsCompanion(
          documentPk: Value('doc-fav'),
          name: Value('Đề cương ôn tập cuối kỳ'),
          subjectFk: Value('sub-01'),
          type: Value(DocumentType.word),
          isPinned: Value(false),
        ),
      );

      // Bật ghim
      await db.documentDao.togglePinned('doc-fav', true);
      var doc = await db.documentDao.getDocument('doc-fav');
      expect(doc!.isPinned, isTrue);

      // Bỏ ghim
      await db.documentDao.togglePinned('doc-fav', false);
      doc = await db.documentDao.getDocument('doc-fav');
      expect(doc!.isPinned, isFalse);
    });

    test('Cashew Tombstone Integrity: Xoá an toàn ghi nhận vào DeleteLogs',
        () async {
      await db.subjectDao.insertOrUpdateSubject(
        const SubjectsCompanion(
          subjectPk: Value('sub-tombstone'),
          name: Value('An toàn mạng'),
          code: Value('NET202'),
        ),
      );

      await db.documentDao.insertOrUpdateDocument(
        const DocumentsCompanion(
          documentPk: Value('doc-tombstone'),
          name: Value('Lab 1 Cryptography'),
          subjectFk: Value('sub-tombstone'),
          type: Value(DocumentType.pdf),
        ),
      );

      // Xoá tài liệu
      await db.documentDao.deleteDocumentSafely('doc-tombstone');

      final deletedDoc = await db.documentDao.getDocument('doc-tombstone');
      expect(deletedDoc, isNull);

      // Kiểm tra bản ghi Tombstone trong DeleteLogs
      final logs = await db.select(db.deleteLogs).get();
      expect(
        logs.any((l) =>
            l.entryPk == 'doc-tombstone' &&
            l.type == DeleteLogType.document),
        isTrue,
      );
    });

    test('SubjectDao: Xoá môn học cascade tài liệu và tạo đủ Tombstone',
        () async {
      await db.subjectDao.insertOrUpdateSubject(
        const SubjectsCompanion(
          subjectPk: Value('sub-del'),
          name: Value('Hệ điều hành'),
          code: Value('OS101'),
        ),
      );

      await db.documentDao.insertOrUpdateDocument(
        const DocumentsCompanion(
          documentPk: Value('doc-del-1'),
          name: Value('Slide Process & Thread'),
          subjectFk: Value('sub-del'),
          type: Value(DocumentType.ppt),
        ),
      );

      await db.subjectDao.deleteSubjectSafely('sub-del');

      // Môn học và tài liệu liên kết đều phải bị xoá
      expect(await db.subjectDao.getSubject('sub-del'), isNull);
      expect(await db.documentDao.getDocument('doc-del-1'), isNull);

      // DeleteLogs phải có cả bản ghi xóa môn học lẫn tài liệu
      final logs = await db.select(db.deleteLogs).get();
      expect(
        logs.any(
            (l) => l.entryPk == 'sub-del' && l.type == DeleteLogType.subject),
        isTrue,
      );
      expect(
        logs.any(
            (l) => l.entryPk == 'doc-del-1' && l.type == DeleteLogType.document),
        isTrue,
      );
    });
  });

  group('Kiểm thử tầng Tiện ích & Định dạng (Domain Utilities)', () {
    test('Formatters: Định dạng dung lượng tệp tin (File Size)', () {
      expect(Formatters.formatFileSize(0), '0 B');
      expect(Formatters.formatFileSize(512), '512 B');
      expect(Formatters.formatFileSize(1024), '1.0 KB');
      expect(Formatters.formatFileSize(1536), '1.5 KB');
      expect(Formatters.formatFileSize(1048576), '1.0 MB');
      expect(Formatters.formatFileSize(5242880), '5.0 MB');
      expect(Formatters.formatFileSize(1073741824), '1.0 GB');
    });

    test('Formatters: Phân loại nhãn và icon theo DocumentType', () {
      expect(Formatters.getDocumentTypeName(DocumentType.pdf), 'Tài liệu PDF');
      expect(Formatters.getDocumentTypeShort(DocumentType.pdf), 'PDF');
      expect(Formatters.getDocumentTypeShort(DocumentType.word), 'Word');
      expect(Formatters.getDocumentTypeShort(DocumentType.ppt), 'PPT');
      expect(Formatters.getDocumentTypeShort(DocumentType.link), 'Link');

      expect(Formatters.getDocumentTypeIcon(DocumentType.pdf),
          Icons.picture_as_pdf_rounded);
    });

    test('Cashew Pastel Color Algorithm: lightenPastel và darkenPastel', () {
      const baseColor = Color(0xFF3F51B5);
      final lightened = lightenPastel(baseColor, amount: 0.8);
      final darkened = darkenPastel(baseColor, amount: 0.8);

      // Lighten phải tiến dần về trắng (RGB cao hơn)
      expect(lightened.red > baseColor.red, isTrue);
      expect(lightened.green > baseColor.green, isTrue);

      // Darken phải tiến dần về đen (RGB thấp hơn)
      expect(darkened.red < baseColor.red, isTrue);
      expect(darkened.blue < baseColor.blue, isTrue);
    });

    test('Tự động nhận diện định dạng file (Docx, PDF, PPT) theo đuôi mở rộng', () {
      DocumentType detect(String name) {
        final ext = name.toLowerCase().split('.').last;
        if (ext == 'pdf') return DocumentType.pdf;
        if (ext == 'doc' || ext == 'docx') return DocumentType.word;
        if (ext == 'ppt' || ext == 'pptx') return DocumentType.ppt;
        return DocumentType.pdf;
      }

      expect(detect('Bao_Cao.docx'), DocumentType.word);
      expect(detect('Giao_Trinh.DOC'), DocumentType.word);
      expect(detect('Slide_Kien_Truc.pptx'), DocumentType.ppt);
      expect(detect('Bai_Tap_Lon.pdf'), DocumentType.pdf);
    });

    test('Recommendation Engine: Phân tích chuẩn hóa tag đa định dạng (dấu phẩy, khoảng trắng)', () {
      Set<String> parseTags(String raw) {
        if (raw.trim().isEmpty) return {};
        return raw
            .split(RegExp(r'[,;\s]+'))
            .map((t) => t.replaceAll(RegExp(r'^[#\s]+'), '').trim().toLowerCase())
            .where((t) => t.isNotEmpty)
            .map((t) => '#$t')
            .toSet();
      }

      final tags1 = parseTags('toan, tin, cntt');
      expect(tags1, containsAll(['#toan', '#tin', '#cntt']));

      final tags2 = parseTags('#mobile #flutter   #studyhub');
      expect(tags2, containsAll(['#mobile', '#flutter', '#studyhub']));

      final tags3 = parseTags('GiaiTich; DaiSo,   #KienTruc');
      expect(tags3, containsAll(['#giaitich', '#daiso', '#kientruc']));
    });

    test('Recommendation Engine: Lọc bỏ tài liệu của chính mình và nhận diện tài liệu cộng đồng', () {
      final docA = const SupabaseDocument(
        id: 'doc-a',
        name: 'Sách Giải Tích 1',
        ownerUid: 'uid-a',
        ownerEmail: 'user_a@gmail.com',
        fileName: 'doc-a.pdf',
        fileSize: 1000,
        mimeType: 'application/pdf',
        storagePath: 'docs/doc-a.pdf',
        tags: '#toan, #giaitich',
        isAvailableForBorrow: true,
      );

      final docB = const SupabaseDocument(
        id: 'doc-b',
        name: 'Vở Ghi CNTT',
        ownerUid: 'uid-b',
        ownerEmail: 'user_b@gmail.com',
        fileName: 'doc-b.pdf',
        fileSize: 1000,
        mimeType: 'application/pdf',
        storagePath: 'docs/doc-b.pdf',
        tags: '#cntt, #flutter',
        isAvailableForBorrow: true,
      );

      final allDocs = [docA, docB];

      // Khi User A truy vấn danh sách gợi ý: docA phải bị loại bỏ, chỉ còn docB
      final candidateForA = allDocs.where((d) => d.ownerEmail.toLowerCase() != 'user_a@gmail.com').toList();
      expect(candidateForA.length, 1);
      expect(candidateForA.first.id, 'doc-b');

      // Khi User B truy vấn danh sách gợi ý: docB phải bị loại bỏ, chỉ còn docA
      final candidateForB = allDocs.where((d) => d.ownerEmail.toLowerCase() != 'user_b@gmail.com').toList();
      expect(candidateForB.length, 1);
      expect(candidateForB.first.id, 'doc-a');
    });

    test('SupabaseService Metadata Resiliency: packMetadataIntoNote, unpackCleanNote, extractMetadataFromNote', () {
      final packed = SupabaseService.packMetadataIntoNote(
        note: 'Sách hay cần mượn gấp',
        tags: '#cntt #mobile',
        isPhysical: true,
        isAvailableForBorrow: true,
        physicalLocation: 'Kệ B2 - Ngăn 3',
        address: 'Hà Nội',
        latitude: 21.0285,
        longitude: 105.8542,
        ownerEmail: 'user_a@gmail.com',
      );

      expect(packed, contains('<!--STUDYHUB_META:'));
      expect(packed, contains('Sách hay cần mượn gấp'));

      final clean = SupabaseService.unpackCleanNote(packed);
      expect(clean, 'Sách hay cần mượn gấp');

      final meta = SupabaseService.extractMetadataFromNote(packed);
      expect(meta['tags'], '#cntt #mobile');
      expect(meta['is_physical'], isTrue);
      expect(meta['is_available_for_borrow'], isTrue);
      expect(meta['physical_location'], 'Kệ B2 - Ngăn 3');
      expect(meta['address'], 'Hà Nội');
      expect(meta['latitude'], 21.0285);
      expect(meta['longitude'], 105.8542);
      expect(meta['owner_email'], 'user_a@gmail.com');
    });

    test('SupabaseDocument.fromJson phục hồi toàn vẹn thông tin vật lý từ packed note khi thiếu cột', () {
      final rawSupabaseRow = {
        'id': 'cloud-doc-123',
        'name': 'Dotline A4',
        'subject_name': 'Di động',
        'owner_uid': 'uid_a',
        'owner_email': 'user_a@gmail.com',
        'file_name': 'Dotline A4.pdf',
        'file_size': 1024,
        'mime_type': 'application/pdf',
        'storage_path': 'docs/a.pdf',
        'download_url': 'https://example.com/a.pdf',
        'category': 1,
        // Bảng trên Supabase Postgres không có cột is_physical, is_available_for_borrow, tags, address, lat, lng!
        // Tất cả được đóng gói an toàn trong note:
        'note': SupabaseService.packMetadataIntoNote(
          note: 'Sách mới mua',
          tags: '#a4 #dotline',
          isPhysical: true,
          isAvailableForBorrow: true,
          physicalLocation: 'Ngăn 1',
          address: 'Thư viện Tạ Quang Bửu',
          latitude: 21.0048,
          longitude: 105.8433,
        ),
      };

      final doc = SupabaseDocument.fromJson(rawSupabaseRow);
      expect(doc.name, 'Dotline A4');
      expect(doc.note, 'Sách mới mua');
      expect(doc.tags, '#a4 #dotline');
      expect(doc.isPhysical, isTrue);
      expect(doc.isAvailableForBorrow, isTrue);
      expect(doc.physicalLocation, 'Ngăn 1');
      expect(doc.address, 'Thư viện Tạ Quang Bửu');
      expect(doc.latitude, 21.0048);
      expect(doc.longitude, 105.8433);
    });
  });
}
