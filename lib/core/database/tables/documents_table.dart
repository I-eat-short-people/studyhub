import 'package:drift/drift.dart';
import '../app_database.dart';

enum DocumentType {
  pdf,
  word,
  ppt,
  link,
}

enum DocumentCategory {
  lecture, // Bài giảng
  reference, // Tài liệu tham khảo
  exercise, // Bài tập
  exam, // Đề kiểm tra
}

@DataClassName('Document')
class Documents extends Table {
  TextColumn get documentPk => text().clientDefault(() => uuid.v4())();
  TextColumn get name => text().withLength(min: 1, max: 250)();
  TextColumn get subjectFk => text()();
  IntColumn get type => intEnum<DocumentType>()();
  IntColumn get category =>
      intEnum<DocumentCategory>().withDefault(const Constant(0))();
  TextColumn get filePath => text().nullable()();
  TextColumn get url => text().nullable()();
  IntColumn get fileSize => integer().withDefault(const Constant(0))();
  TextColumn get note => text().withLength(max: 1000).nullable()();
  BoolColumn get isPinned => boolean().withDefault(const Constant(false))();
  TextColumn get tags => text().withDefault(const Constant(''))();
  BoolColumn get isPhysical => boolean().withDefault(const Constant(false))();
  BoolColumn get isAvailableForBorrow =>
      boolean().withDefault(const Constant(false))();
  TextColumn get physicalLocation => text().nullable()();
  TextColumn get address => text().nullable()();
  RealColumn get latitude => real().nullable()();
  RealColumn get longitude => real().nullable()();
  DateTimeColumn get dateCreated =>
      dateTime().clientDefault(() => DateTime.now())();
  DateTimeColumn get dateTimeModified =>
      dateTime().withDefault(Constant(DateTime.now()))();

  @override
  Set<Column> get primaryKey => {documentPk};
}
