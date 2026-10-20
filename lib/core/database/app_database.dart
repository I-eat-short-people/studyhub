import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'tables/subjects_table.dart';
import 'tables/documents_table.dart';
import 'tables/delete_logs_table.dart';
import 'daos/subject_dao.dart';
import 'daos/document_dao.dart';

export 'tables/subjects_table.dart';
export 'tables/documents_table.dart';
export 'tables/delete_logs_table.dart';

part 'app_database.g.dart';

const uuid = Uuid();

@DriftDatabase(
  tables: [Subjects, Documents, DeleteLogs],
  daos: [SubjectDao, DocumentDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          if (from < 2) {
            await m.addColumn(documents, documents.category);
          }
          if (from < 3) {
            await m.addColumn(documents, documents.tags);
            await m.addColumn(documents, documents.isPhysical);
            await m.addColumn(documents, documents.isAvailableForBorrow);
            await m.addColumn(documents, documents.physicalLocation);
            await m.addColumn(documents, documents.address);
            await m.addColumn(documents, documents.latitude);
            await m.addColumn(documents, documents.longitude);
          }
        },
      );

  Future<void> seedInitialDataIfEmpty() async {
    final existingSubjects = await subjectDao.getAllSubjects();
    if (existingSubjects.isNotEmpty) return;

    // Seed default courses
    final mathId = 'sub-math-001';
    final mobileId = 'sub-mob-002';
    final networkId = 'sub-net-003';

    await subjectDao.insertOrUpdateSubject(
      SubjectsCompanion.insert(
        subjectPk: Value(mathId),
        name: 'Toán Rời Rạc & Giải Thuật',
        code: 'MAT201',
        color: const Value(0xFF5C6BC0), // Indigo
        icon: const Value('calculate'),
      ),
    );

    await subjectDao.insertOrUpdateSubject(
      SubjectsCompanion.insert(
        subjectPk: Value(mobileId),
        name: 'Lập Trình Thiết Bị Di Động',
        code: 'CSE441',
        color: const Value(0xFF42A5F5), // Blue
        icon: const Value('smartphone'),
      ),
    );

    await subjectDao.insertOrUpdateSubject(
      SubjectsCompanion.insert(
        subjectPk: Value(networkId),
        name: 'Mạng Máy Tính & An Ninh Mạng',
        code: 'NET301',
        color: const Value(0xFF26A69A), // Teal
        icon: const Value('cloud'),
      ),
    );

    // Seed sample documents
    await documentDao.insertOrUpdateDocument(
      DocumentsCompanion.insert(
        name: 'Đề cương chi tiết môn Lập trình Di động 2026',
        subjectFk: mobileId,
        type: DocumentType.pdf,
        note: const Value('Bao gồm cấu trúc Flutter, Drift SQLite và Clean Architecture'),
        fileSize: const Value(1542000), // ~1.5 MB
        isPinned: const Value(true),
        url: const Value('https://raw.githubusercontent.com/flutter/flutter/master/README.md'),
      ),
    );

    await documentDao.insertOrUpdateDocument(
      DocumentsCompanion.insert(
        name: 'Slide Bài giảng Chương 1 - Kiến trúc Hệ thống Cashew',
        subjectFk: mobileId,
        type: DocumentType.ppt,
        note: const Value('Phân tích MultiExecutor, Streams và Tombstones'),
        fileSize: const Value(3820000), // ~3.8 MB
        isPinned: const Value(true),
      ),
    );

    await documentDao.insertOrUpdateDocument(
      DocumentsCompanion.insert(
        name: 'Tài liệu hướng dẫn Bài tập lớn - StudyHub',
        subjectFk: mobileId,
        type: DocumentType.word,
        note: const Value('Quy chuẩn nộp bài, rubric chấm điểm và tài liệu yêu cầu'),
        fileSize: const Value(850000), // ~850 KB
        isPinned: const Value(false),
      ),
    );

    await documentDao.insertOrUpdateDocument(
      DocumentsCompanion.insert(
        name: 'Tài liệu tham khảo Drift ORM Docs',
        subjectFk: mobileId,
        type: DocumentType.link,
        url: const Value('https://drift.simonbinder.eu/docs/'),
        note: const Value('Trang tài liệu chính thức về Reactive SQLite cho Flutter'),
        fileSize: const Value(0),
        isPinned: const Value(true),
      ),
    );

    await documentDao.insertOrUpdateDocument(
      DocumentsCompanion.insert(
        name: 'Giáo trình Lý thuyết Đồ thị và Ứng dụng',
        subjectFk: mathId,
        type: DocumentType.pdf,
        note: const Value('Đầy đủ các thuật toán Dijkstra, Floyd-Warshall, Kruskal'),
        fileSize: const Value(4520000),
        isPinned: const Value(false),
      ),
    );

    await documentDao.insertOrUpdateDocument(
      DocumentsCompanion.insert(
        name: 'Chuẩn giao thức TCP/IP và Mô hình OSI',
        subjectFk: networkId,
        type: DocumentType.pdf,
        note: const Value('Tài liệu ôn tập cho kỳ thi cuối kỳ'),
        fileSize: const Value(2150000),
        isPinned: const Value(false),
      ),
    );
  }
}
