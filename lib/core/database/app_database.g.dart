// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $SubjectsTable extends Subjects with TableInfo<$SubjectsTable, Subject> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SubjectsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _subjectPkMeta = const VerificationMeta(
    'subjectPk',
  );
  @override
  late final GeneratedColumn<String> subjectPk = GeneratedColumn<String>(
    'subject_pk',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => uuid.v4(),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 200,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
    'code',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 50,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<int> color = GeneratedColumn<int>(
    'color',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0xFF4A90E2),
  );
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
    'icon',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('book'),
  );
  static const VerificationMeta _dateCreatedMeta = const VerificationMeta(
    'dateCreated',
  );
  @override
  late final GeneratedColumn<DateTime> dateCreated = GeneratedColumn<DateTime>(
    'date_created',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now(),
  );
  static const VerificationMeta _dateTimeModifiedMeta = const VerificationMeta(
    'dateTimeModified',
  );
  @override
  late final GeneratedColumn<DateTime> dateTimeModified =
      GeneratedColumn<DateTime>(
        'date_time_modified',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
        defaultValue: Constant(DateTime.now()),
      );
  @override
  List<GeneratedColumn> get $columns => [
    subjectPk,
    name,
    code,
    color,
    icon,
    dateCreated,
    dateTimeModified,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'subjects';
  @override
  VerificationContext validateIntegrity(
    Insertable<Subject> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('subject_pk')) {
      context.handle(
        _subjectPkMeta,
        subjectPk.isAcceptableOrUnknown(data['subject_pk']!, _subjectPkMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('code')) {
      context.handle(
        _codeMeta,
        code.isAcceptableOrUnknown(data['code']!, _codeMeta),
      );
    } else if (isInserting) {
      context.missing(_codeMeta);
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    }
    if (data.containsKey('icon')) {
      context.handle(
        _iconMeta,
        icon.isAcceptableOrUnknown(data['icon']!, _iconMeta),
      );
    }
    if (data.containsKey('date_created')) {
      context.handle(
        _dateCreatedMeta,
        dateCreated.isAcceptableOrUnknown(
          data['date_created']!,
          _dateCreatedMeta,
        ),
      );
    }
    if (data.containsKey('date_time_modified')) {
      context.handle(
        _dateTimeModifiedMeta,
        dateTimeModified.isAcceptableOrUnknown(
          data['date_time_modified']!,
          _dateTimeModifiedMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {subjectPk};
  @override
  Subject map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Subject(
      subjectPk: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subject_pk'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      code: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}code'],
      )!,
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color'],
      )!,
      icon: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon'],
      )!,
      dateCreated: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date_created'],
      )!,
      dateTimeModified: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date_time_modified'],
      )!,
    );
  }

  @override
  $SubjectsTable createAlias(String alias) {
    return $SubjectsTable(attachedDatabase, alias);
  }
}

class Subject extends DataClass implements Insertable<Subject> {
  final String subjectPk;
  final String name;
  final String code;
  final int color;
  final String icon;
  final DateTime dateCreated;
  final DateTime dateTimeModified;
  const Subject({
    required this.subjectPk,
    required this.name,
    required this.code,
    required this.color,
    required this.icon,
    required this.dateCreated,
    required this.dateTimeModified,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['subject_pk'] = Variable<String>(subjectPk);
    map['name'] = Variable<String>(name);
    map['code'] = Variable<String>(code);
    map['color'] = Variable<int>(color);
    map['icon'] = Variable<String>(icon);
    map['date_created'] = Variable<DateTime>(dateCreated);
    map['date_time_modified'] = Variable<DateTime>(dateTimeModified);
    return map;
  }

  SubjectsCompanion toCompanion(bool nullToAbsent) {
    return SubjectsCompanion(
      subjectPk: Value(subjectPk),
      name: Value(name),
      code: Value(code),
      color: Value(color),
      icon: Value(icon),
      dateCreated: Value(dateCreated),
      dateTimeModified: Value(dateTimeModified),
    );
  }

  factory Subject.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Subject(
      subjectPk: serializer.fromJson<String>(json['subjectPk']),
      name: serializer.fromJson<String>(json['name']),
      code: serializer.fromJson<String>(json['code']),
      color: serializer.fromJson<int>(json['color']),
      icon: serializer.fromJson<String>(json['icon']),
      dateCreated: serializer.fromJson<DateTime>(json['dateCreated']),
      dateTimeModified: serializer.fromJson<DateTime>(json['dateTimeModified']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'subjectPk': serializer.toJson<String>(subjectPk),
      'name': serializer.toJson<String>(name),
      'code': serializer.toJson<String>(code),
      'color': serializer.toJson<int>(color),
      'icon': serializer.toJson<String>(icon),
      'dateCreated': serializer.toJson<DateTime>(dateCreated),
      'dateTimeModified': serializer.toJson<DateTime>(dateTimeModified),
    };
  }

  Subject copyWith({
    String? subjectPk,
    String? name,
    String? code,
    int? color,
    String? icon,
    DateTime? dateCreated,
    DateTime? dateTimeModified,
  }) => Subject(
    subjectPk: subjectPk ?? this.subjectPk,
    name: name ?? this.name,
    code: code ?? this.code,
    color: color ?? this.color,
    icon: icon ?? this.icon,
    dateCreated: dateCreated ?? this.dateCreated,
    dateTimeModified: dateTimeModified ?? this.dateTimeModified,
  );
  Subject copyWithCompanion(SubjectsCompanion data) {
    return Subject(
      subjectPk: data.subjectPk.present ? data.subjectPk.value : this.subjectPk,
      name: data.name.present ? data.name.value : this.name,
      code: data.code.present ? data.code.value : this.code,
      color: data.color.present ? data.color.value : this.color,
      icon: data.icon.present ? data.icon.value : this.icon,
      dateCreated: data.dateCreated.present
          ? data.dateCreated.value
          : this.dateCreated,
      dateTimeModified: data.dateTimeModified.present
          ? data.dateTimeModified.value
          : this.dateTimeModified,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Subject(')
          ..write('subjectPk: $subjectPk, ')
          ..write('name: $name, ')
          ..write('code: $code, ')
          ..write('color: $color, ')
          ..write('icon: $icon, ')
          ..write('dateCreated: $dateCreated, ')
          ..write('dateTimeModified: $dateTimeModified')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    subjectPk,
    name,
    code,
    color,
    icon,
    dateCreated,
    dateTimeModified,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Subject &&
          other.subjectPk == this.subjectPk &&
          other.name == this.name &&
          other.code == this.code &&
          other.color == this.color &&
          other.icon == this.icon &&
          other.dateCreated == this.dateCreated &&
          other.dateTimeModified == this.dateTimeModified);
}

class SubjectsCompanion extends UpdateCompanion<Subject> {
  final Value<String> subjectPk;
  final Value<String> name;
  final Value<String> code;
  final Value<int> color;
  final Value<String> icon;
  final Value<DateTime> dateCreated;
  final Value<DateTime> dateTimeModified;
  final Value<int> rowid;
  const SubjectsCompanion({
    this.subjectPk = const Value.absent(),
    this.name = const Value.absent(),
    this.code = const Value.absent(),
    this.color = const Value.absent(),
    this.icon = const Value.absent(),
    this.dateCreated = const Value.absent(),
    this.dateTimeModified = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SubjectsCompanion.insert({
    this.subjectPk = const Value.absent(),
    required String name,
    required String code,
    this.color = const Value.absent(),
    this.icon = const Value.absent(),
    this.dateCreated = const Value.absent(),
    this.dateTimeModified = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : name = Value(name),
       code = Value(code);
  static Insertable<Subject> custom({
    Expression<String>? subjectPk,
    Expression<String>? name,
    Expression<String>? code,
    Expression<int>? color,
    Expression<String>? icon,
    Expression<DateTime>? dateCreated,
    Expression<DateTime>? dateTimeModified,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (subjectPk != null) 'subject_pk': subjectPk,
      if (name != null) 'name': name,
      if (code != null) 'code': code,
      if (color != null) 'color': color,
      if (icon != null) 'icon': icon,
      if (dateCreated != null) 'date_created': dateCreated,
      if (dateTimeModified != null) 'date_time_modified': dateTimeModified,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SubjectsCompanion copyWith({
    Value<String>? subjectPk,
    Value<String>? name,
    Value<String>? code,
    Value<int>? color,
    Value<String>? icon,
    Value<DateTime>? dateCreated,
    Value<DateTime>? dateTimeModified,
    Value<int>? rowid,
  }) {
    return SubjectsCompanion(
      subjectPk: subjectPk ?? this.subjectPk,
      name: name ?? this.name,
      code: code ?? this.code,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      dateCreated: dateCreated ?? this.dateCreated,
      dateTimeModified: dateTimeModified ?? this.dateTimeModified,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (subjectPk.present) {
      map['subject_pk'] = Variable<String>(subjectPk.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (color.present) {
      map['color'] = Variable<int>(color.value);
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (dateCreated.present) {
      map['date_created'] = Variable<DateTime>(dateCreated.value);
    }
    if (dateTimeModified.present) {
      map['date_time_modified'] = Variable<DateTime>(dateTimeModified.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SubjectsCompanion(')
          ..write('subjectPk: $subjectPk, ')
          ..write('name: $name, ')
          ..write('code: $code, ')
          ..write('color: $color, ')
          ..write('icon: $icon, ')
          ..write('dateCreated: $dateCreated, ')
          ..write('dateTimeModified: $dateTimeModified, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DocumentsTable extends Documents
    with TableInfo<$DocumentsTable, Document> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DocumentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _documentPkMeta = const VerificationMeta(
    'documentPk',
  );
  @override
  late final GeneratedColumn<String> documentPk = GeneratedColumn<String>(
    'document_pk',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => uuid.v4(),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 250,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _subjectFkMeta = const VerificationMeta(
    'subjectFk',
  );
  @override
  late final GeneratedColumn<String> subjectFk = GeneratedColumn<String>(
    'subject_fk',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DocumentType, int> type =
      GeneratedColumn<int>(
        'type',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DocumentType>($DocumentsTable.$convertertype);
  @override
  late final GeneratedColumnWithTypeConverter<DocumentCategory, int> category =
      GeneratedColumn<int>(
        'category',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: const Constant(0),
      ).withConverter<DocumentCategory>($DocumentsTable.$convertercategory);
  static const VerificationMeta _filePathMeta = const VerificationMeta(
    'filePath',
  );
  @override
  late final GeneratedColumn<String> filePath = GeneratedColumn<String>(
    'file_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _urlMeta = const VerificationMeta('url');
  @override
  late final GeneratedColumn<String> url = GeneratedColumn<String>(
    'url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fileSizeMeta = const VerificationMeta(
    'fileSize',
  );
  @override
  late final GeneratedColumn<int> fileSize = GeneratedColumn<int>(
    'file_size',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 1000),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isPinnedMeta = const VerificationMeta(
    'isPinned',
  );
  @override
  late final GeneratedColumn<bool> isPinned = GeneratedColumn<bool>(
    'is_pinned',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_pinned" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _tagsMeta = const VerificationMeta('tags');
  @override
  late final GeneratedColumn<String> tags = GeneratedColumn<String>(
    'tags',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _isPhysicalMeta = const VerificationMeta(
    'isPhysical',
  );
  @override
  late final GeneratedColumn<bool> isPhysical = GeneratedColumn<bool>(
    'is_physical',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_physical" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isAvailableForBorrowMeta =
      const VerificationMeta('isAvailableForBorrow');
  @override
  late final GeneratedColumn<bool> isAvailableForBorrow = GeneratedColumn<bool>(
    'is_available_for_borrow',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_available_for_borrow" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _physicalLocationMeta = const VerificationMeta(
    'physicalLocation',
  );
  @override
  late final GeneratedColumn<String> physicalLocation = GeneratedColumn<String>(
    'physical_location',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _addressMeta = const VerificationMeta(
    'address',
  );
  @override
  late final GeneratedColumn<String> address = GeneratedColumn<String>(
    'address',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _latitudeMeta = const VerificationMeta(
    'latitude',
  );
  @override
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
    'latitude',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _longitudeMeta = const VerificationMeta(
    'longitude',
  );
  @override
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
    'longitude',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dateCreatedMeta = const VerificationMeta(
    'dateCreated',
  );
  @override
  late final GeneratedColumn<DateTime> dateCreated = GeneratedColumn<DateTime>(
    'date_created',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now(),
  );
  static const VerificationMeta _dateTimeModifiedMeta = const VerificationMeta(
    'dateTimeModified',
  );
  @override
  late final GeneratedColumn<DateTime> dateTimeModified =
      GeneratedColumn<DateTime>(
        'date_time_modified',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
        defaultValue: Constant(DateTime.now()),
      );
  @override
  List<GeneratedColumn> get $columns => [
    documentPk,
    name,
    subjectFk,
    type,
    category,
    filePath,
    url,
    fileSize,
    note,
    isPinned,
    tags,
    isPhysical,
    isAvailableForBorrow,
    physicalLocation,
    address,
    latitude,
    longitude,
    dateCreated,
    dateTimeModified,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'documents';
  @override
  VerificationContext validateIntegrity(
    Insertable<Document> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('document_pk')) {
      context.handle(
        _documentPkMeta,
        documentPk.isAcceptableOrUnknown(data['document_pk']!, _documentPkMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('subject_fk')) {
      context.handle(
        _subjectFkMeta,
        subjectFk.isAcceptableOrUnknown(data['subject_fk']!, _subjectFkMeta),
      );
    } else if (isInserting) {
      context.missing(_subjectFkMeta);
    }
    if (data.containsKey('file_path')) {
      context.handle(
        _filePathMeta,
        filePath.isAcceptableOrUnknown(data['file_path']!, _filePathMeta),
      );
    }
    if (data.containsKey('url')) {
      context.handle(
        _urlMeta,
        url.isAcceptableOrUnknown(data['url']!, _urlMeta),
      );
    }
    if (data.containsKey('file_size')) {
      context.handle(
        _fileSizeMeta,
        fileSize.isAcceptableOrUnknown(data['file_size']!, _fileSizeMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('is_pinned')) {
      context.handle(
        _isPinnedMeta,
        isPinned.isAcceptableOrUnknown(data['is_pinned']!, _isPinnedMeta),
      );
    }
    if (data.containsKey('tags')) {
      context.handle(
        _tagsMeta,
        tags.isAcceptableOrUnknown(data['tags']!, _tagsMeta),
      );
    }
    if (data.containsKey('is_physical')) {
      context.handle(
        _isPhysicalMeta,
        isPhysical.isAcceptableOrUnknown(data['is_physical']!, _isPhysicalMeta),
      );
    }
    if (data.containsKey('is_available_for_borrow')) {
      context.handle(
        _isAvailableForBorrowMeta,
        isAvailableForBorrow.isAcceptableOrUnknown(
          data['is_available_for_borrow']!,
          _isAvailableForBorrowMeta,
        ),
      );
    }
    if (data.containsKey('physical_location')) {
      context.handle(
        _physicalLocationMeta,
        physicalLocation.isAcceptableOrUnknown(
          data['physical_location']!,
          _physicalLocationMeta,
        ),
      );
    }
    if (data.containsKey('address')) {
      context.handle(
        _addressMeta,
        address.isAcceptableOrUnknown(data['address']!, _addressMeta),
      );
    }
    if (data.containsKey('latitude')) {
      context.handle(
        _latitudeMeta,
        latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta),
      );
    }
    if (data.containsKey('longitude')) {
      context.handle(
        _longitudeMeta,
        longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta),
      );
    }
    if (data.containsKey('date_created')) {
      context.handle(
        _dateCreatedMeta,
        dateCreated.isAcceptableOrUnknown(
          data['date_created']!,
          _dateCreatedMeta,
        ),
      );
    }
    if (data.containsKey('date_time_modified')) {
      context.handle(
        _dateTimeModifiedMeta,
        dateTimeModified.isAcceptableOrUnknown(
          data['date_time_modified']!,
          _dateTimeModifiedMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {documentPk};
  @override
  Document map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Document(
      documentPk: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}document_pk'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      subjectFk: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subject_fk'],
      )!,
      type: $DocumentsTable.$convertertype.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}type'],
        )!,
      ),
      category: $DocumentsTable.$convertercategory.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}category'],
        )!,
      ),
      filePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_path'],
      ),
      url: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}url'],
      ),
      fileSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}file_size'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      isPinned: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_pinned'],
      )!,
      tags: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tags'],
      )!,
      isPhysical: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_physical'],
      )!,
      isAvailableForBorrow: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_available_for_borrow'],
      )!,
      physicalLocation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}physical_location'],
      ),
      address: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}address'],
      ),
      latitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}latitude'],
      ),
      longitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}longitude'],
      ),
      dateCreated: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date_created'],
      )!,
      dateTimeModified: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date_time_modified'],
      )!,
    );
  }

  @override
  $DocumentsTable createAlias(String alias) {
    return $DocumentsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<DocumentType, int, int> $convertertype =
      const EnumIndexConverter<DocumentType>(DocumentType.values);
  static JsonTypeConverter2<DocumentCategory, int, int> $convertercategory =
      const EnumIndexConverter<DocumentCategory>(DocumentCategory.values);
}

class Document extends DataClass implements Insertable<Document> {
  final String documentPk;
  final String name;
  final String subjectFk;
  final DocumentType type;
  final DocumentCategory category;
  final String? filePath;
  final String? url;
  final int fileSize;
  final String? note;
  final bool isPinned;
  final String tags;
  final bool isPhysical;
  final bool isAvailableForBorrow;
  final String? physicalLocation;
  final String? address;
  final double? latitude;
  final double? longitude;
  final DateTime dateCreated;
  final DateTime dateTimeModified;
  const Document({
    required this.documentPk,
    required this.name,
    required this.subjectFk,
    required this.type,
    required this.category,
    this.filePath,
    this.url,
    required this.fileSize,
    this.note,
    required this.isPinned,
    required this.tags,
    required this.isPhysical,
    required this.isAvailableForBorrow,
    this.physicalLocation,
    this.address,
    this.latitude,
    this.longitude,
    required this.dateCreated,
    required this.dateTimeModified,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['document_pk'] = Variable<String>(documentPk);
    map['name'] = Variable<String>(name);
    map['subject_fk'] = Variable<String>(subjectFk);
    {
      map['type'] = Variable<int>($DocumentsTable.$convertertype.toSql(type));
    }
    {
      map['category'] = Variable<int>(
        $DocumentsTable.$convertercategory.toSql(category),
      );
    }
    if (!nullToAbsent || filePath != null) {
      map['file_path'] = Variable<String>(filePath);
    }
    if (!nullToAbsent || url != null) {
      map['url'] = Variable<String>(url);
    }
    map['file_size'] = Variable<int>(fileSize);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['is_pinned'] = Variable<bool>(isPinned);
    map['tags'] = Variable<String>(tags);
    map['is_physical'] = Variable<bool>(isPhysical);
    map['is_available_for_borrow'] = Variable<bool>(isAvailableForBorrow);
    if (!nullToAbsent || physicalLocation != null) {
      map['physical_location'] = Variable<String>(physicalLocation);
    }
    if (!nullToAbsent || address != null) {
      map['address'] = Variable<String>(address);
    }
    if (!nullToAbsent || latitude != null) {
      map['latitude'] = Variable<double>(latitude);
    }
    if (!nullToAbsent || longitude != null) {
      map['longitude'] = Variable<double>(longitude);
    }
    map['date_created'] = Variable<DateTime>(dateCreated);
    map['date_time_modified'] = Variable<DateTime>(dateTimeModified);
    return map;
  }

  DocumentsCompanion toCompanion(bool nullToAbsent) {
    return DocumentsCompanion(
      documentPk: Value(documentPk),
      name: Value(name),
      subjectFk: Value(subjectFk),
      type: Value(type),
      category: Value(category),
      filePath: filePath == null && nullToAbsent
          ? const Value.absent()
          : Value(filePath),
      url: url == null && nullToAbsent ? const Value.absent() : Value(url),
      fileSize: Value(fileSize),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      isPinned: Value(isPinned),
      tags: Value(tags),
      isPhysical: Value(isPhysical),
      isAvailableForBorrow: Value(isAvailableForBorrow),
      physicalLocation: physicalLocation == null && nullToAbsent
          ? const Value.absent()
          : Value(physicalLocation),
      address: address == null && nullToAbsent
          ? const Value.absent()
          : Value(address),
      latitude: latitude == null && nullToAbsent
          ? const Value.absent()
          : Value(latitude),
      longitude: longitude == null && nullToAbsent
          ? const Value.absent()
          : Value(longitude),
      dateCreated: Value(dateCreated),
      dateTimeModified: Value(dateTimeModified),
    );
  }

  factory Document.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Document(
      documentPk: serializer.fromJson<String>(json['documentPk']),
      name: serializer.fromJson<String>(json['name']),
      subjectFk: serializer.fromJson<String>(json['subjectFk']),
      type: $DocumentsTable.$convertertype.fromJson(
        serializer.fromJson<int>(json['type']),
      ),
      category: $DocumentsTable.$convertercategory.fromJson(
        serializer.fromJson<int>(json['category']),
      ),
      filePath: serializer.fromJson<String?>(json['filePath']),
      url: serializer.fromJson<String?>(json['url']),
      fileSize: serializer.fromJson<int>(json['fileSize']),
      note: serializer.fromJson<String?>(json['note']),
      isPinned: serializer.fromJson<bool>(json['isPinned']),
      tags: serializer.fromJson<String>(json['tags']),
      isPhysical: serializer.fromJson<bool>(json['isPhysical']),
      isAvailableForBorrow: serializer.fromJson<bool>(
        json['isAvailableForBorrow'],
      ),
      physicalLocation: serializer.fromJson<String?>(json['physicalLocation']),
      address: serializer.fromJson<String?>(json['address']),
      latitude: serializer.fromJson<double?>(json['latitude']),
      longitude: serializer.fromJson<double?>(json['longitude']),
      dateCreated: serializer.fromJson<DateTime>(json['dateCreated']),
      dateTimeModified: serializer.fromJson<DateTime>(json['dateTimeModified']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'documentPk': serializer.toJson<String>(documentPk),
      'name': serializer.toJson<String>(name),
      'subjectFk': serializer.toJson<String>(subjectFk),
      'type': serializer.toJson<int>(
        $DocumentsTable.$convertertype.toJson(type),
      ),
      'category': serializer.toJson<int>(
        $DocumentsTable.$convertercategory.toJson(category),
      ),
      'filePath': serializer.toJson<String?>(filePath),
      'url': serializer.toJson<String?>(url),
      'fileSize': serializer.toJson<int>(fileSize),
      'note': serializer.toJson<String?>(note),
      'isPinned': serializer.toJson<bool>(isPinned),
      'tags': serializer.toJson<String>(tags),
      'isPhysical': serializer.toJson<bool>(isPhysical),
      'isAvailableForBorrow': serializer.toJson<bool>(isAvailableForBorrow),
      'physicalLocation': serializer.toJson<String?>(physicalLocation),
      'address': serializer.toJson<String?>(address),
      'latitude': serializer.toJson<double?>(latitude),
      'longitude': serializer.toJson<double?>(longitude),
      'dateCreated': serializer.toJson<DateTime>(dateCreated),
      'dateTimeModified': serializer.toJson<DateTime>(dateTimeModified),
    };
  }

  Document copyWith({
    String? documentPk,
    String? name,
    String? subjectFk,
    DocumentType? type,
    DocumentCategory? category,
    Value<String?> filePath = const Value.absent(),
    Value<String?> url = const Value.absent(),
    int? fileSize,
    Value<String?> note = const Value.absent(),
    bool? isPinned,
    String? tags,
    bool? isPhysical,
    bool? isAvailableForBorrow,
    Value<String?> physicalLocation = const Value.absent(),
    Value<String?> address = const Value.absent(),
    Value<double?> latitude = const Value.absent(),
    Value<double?> longitude = const Value.absent(),
    DateTime? dateCreated,
    DateTime? dateTimeModified,
  }) => Document(
    documentPk: documentPk ?? this.documentPk,
    name: name ?? this.name,
    subjectFk: subjectFk ?? this.subjectFk,
    type: type ?? this.type,
    category: category ?? this.category,
    filePath: filePath.present ? filePath.value : this.filePath,
    url: url.present ? url.value : this.url,
    fileSize: fileSize ?? this.fileSize,
    note: note.present ? note.value : this.note,
    isPinned: isPinned ?? this.isPinned,
    tags: tags ?? this.tags,
    isPhysical: isPhysical ?? this.isPhysical,
    isAvailableForBorrow: isAvailableForBorrow ?? this.isAvailableForBorrow,
    physicalLocation: physicalLocation.present
        ? physicalLocation.value
        : this.physicalLocation,
    address: address.present ? address.value : this.address,
    latitude: latitude.present ? latitude.value : this.latitude,
    longitude: longitude.present ? longitude.value : this.longitude,
    dateCreated: dateCreated ?? this.dateCreated,
    dateTimeModified: dateTimeModified ?? this.dateTimeModified,
  );
  Document copyWithCompanion(DocumentsCompanion data) {
    return Document(
      documentPk: data.documentPk.present
          ? data.documentPk.value
          : this.documentPk,
      name: data.name.present ? data.name.value : this.name,
      subjectFk: data.subjectFk.present ? data.subjectFk.value : this.subjectFk,
      type: data.type.present ? data.type.value : this.type,
      category: data.category.present ? data.category.value : this.category,
      filePath: data.filePath.present ? data.filePath.value : this.filePath,
      url: data.url.present ? data.url.value : this.url,
      fileSize: data.fileSize.present ? data.fileSize.value : this.fileSize,
      note: data.note.present ? data.note.value : this.note,
      isPinned: data.isPinned.present ? data.isPinned.value : this.isPinned,
      tags: data.tags.present ? data.tags.value : this.tags,
      isPhysical: data.isPhysical.present
          ? data.isPhysical.value
          : this.isPhysical,
      isAvailableForBorrow: data.isAvailableForBorrow.present
          ? data.isAvailableForBorrow.value
          : this.isAvailableForBorrow,
      physicalLocation: data.physicalLocation.present
          ? data.physicalLocation.value
          : this.physicalLocation,
      address: data.address.present ? data.address.value : this.address,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      dateCreated: data.dateCreated.present
          ? data.dateCreated.value
          : this.dateCreated,
      dateTimeModified: data.dateTimeModified.present
          ? data.dateTimeModified.value
          : this.dateTimeModified,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Document(')
          ..write('documentPk: $documentPk, ')
          ..write('name: $name, ')
          ..write('subjectFk: $subjectFk, ')
          ..write('type: $type, ')
          ..write('category: $category, ')
          ..write('filePath: $filePath, ')
          ..write('url: $url, ')
          ..write('fileSize: $fileSize, ')
          ..write('note: $note, ')
          ..write('isPinned: $isPinned, ')
          ..write('tags: $tags, ')
          ..write('isPhysical: $isPhysical, ')
          ..write('isAvailableForBorrow: $isAvailableForBorrow, ')
          ..write('physicalLocation: $physicalLocation, ')
          ..write('address: $address, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('dateCreated: $dateCreated, ')
          ..write('dateTimeModified: $dateTimeModified')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    documentPk,
    name,
    subjectFk,
    type,
    category,
    filePath,
    url,
    fileSize,
    note,
    isPinned,
    tags,
    isPhysical,
    isAvailableForBorrow,
    physicalLocation,
    address,
    latitude,
    longitude,
    dateCreated,
    dateTimeModified,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Document &&
          other.documentPk == this.documentPk &&
          other.name == this.name &&
          other.subjectFk == this.subjectFk &&
          other.type == this.type &&
          other.category == this.category &&
          other.filePath == this.filePath &&
          other.url == this.url &&
          other.fileSize == this.fileSize &&
          other.note == this.note &&
          other.isPinned == this.isPinned &&
          other.tags == this.tags &&
          other.isPhysical == this.isPhysical &&
          other.isAvailableForBorrow == this.isAvailableForBorrow &&
          other.physicalLocation == this.physicalLocation &&
          other.address == this.address &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.dateCreated == this.dateCreated &&
          other.dateTimeModified == this.dateTimeModified);
}

class DocumentsCompanion extends UpdateCompanion<Document> {
  final Value<String> documentPk;
  final Value<String> name;
  final Value<String> subjectFk;
  final Value<DocumentType> type;
  final Value<DocumentCategory> category;
  final Value<String?> filePath;
  final Value<String?> url;
  final Value<int> fileSize;
  final Value<String?> note;
  final Value<bool> isPinned;
  final Value<String> tags;
  final Value<bool> isPhysical;
  final Value<bool> isAvailableForBorrow;
  final Value<String?> physicalLocation;
  final Value<String?> address;
  final Value<double?> latitude;
  final Value<double?> longitude;
  final Value<DateTime> dateCreated;
  final Value<DateTime> dateTimeModified;
  final Value<int> rowid;
  const DocumentsCompanion({
    this.documentPk = const Value.absent(),
    this.name = const Value.absent(),
    this.subjectFk = const Value.absent(),
    this.type = const Value.absent(),
    this.category = const Value.absent(),
    this.filePath = const Value.absent(),
    this.url = const Value.absent(),
    this.fileSize = const Value.absent(),
    this.note = const Value.absent(),
    this.isPinned = const Value.absent(),
    this.tags = const Value.absent(),
    this.isPhysical = const Value.absent(),
    this.isAvailableForBorrow = const Value.absent(),
    this.physicalLocation = const Value.absent(),
    this.address = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.dateCreated = const Value.absent(),
    this.dateTimeModified = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DocumentsCompanion.insert({
    this.documentPk = const Value.absent(),
    required String name,
    required String subjectFk,
    required DocumentType type,
    this.category = const Value.absent(),
    this.filePath = const Value.absent(),
    this.url = const Value.absent(),
    this.fileSize = const Value.absent(),
    this.note = const Value.absent(),
    this.isPinned = const Value.absent(),
    this.tags = const Value.absent(),
    this.isPhysical = const Value.absent(),
    this.isAvailableForBorrow = const Value.absent(),
    this.physicalLocation = const Value.absent(),
    this.address = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.dateCreated = const Value.absent(),
    this.dateTimeModified = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : name = Value(name),
       subjectFk = Value(subjectFk),
       type = Value(type);
  static Insertable<Document> custom({
    Expression<String>? documentPk,
    Expression<String>? name,
    Expression<String>? subjectFk,
    Expression<int>? type,
    Expression<int>? category,
    Expression<String>? filePath,
    Expression<String>? url,
    Expression<int>? fileSize,
    Expression<String>? note,
    Expression<bool>? isPinned,
    Expression<String>? tags,
    Expression<bool>? isPhysical,
    Expression<bool>? isAvailableForBorrow,
    Expression<String>? physicalLocation,
    Expression<String>? address,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<DateTime>? dateCreated,
    Expression<DateTime>? dateTimeModified,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (documentPk != null) 'document_pk': documentPk,
      if (name != null) 'name': name,
      if (subjectFk != null) 'subject_fk': subjectFk,
      if (type != null) 'type': type,
      if (category != null) 'category': category,
      if (filePath != null) 'file_path': filePath,
      if (url != null) 'url': url,
      if (fileSize != null) 'file_size': fileSize,
      if (note != null) 'note': note,
      if (isPinned != null) 'is_pinned': isPinned,
      if (tags != null) 'tags': tags,
      if (isPhysical != null) 'is_physical': isPhysical,
      if (isAvailableForBorrow != null)
        'is_available_for_borrow': isAvailableForBorrow,
      if (physicalLocation != null) 'physical_location': physicalLocation,
      if (address != null) 'address': address,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (dateCreated != null) 'date_created': dateCreated,
      if (dateTimeModified != null) 'date_time_modified': dateTimeModified,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DocumentsCompanion copyWith({
    Value<String>? documentPk,
    Value<String>? name,
    Value<String>? subjectFk,
    Value<DocumentType>? type,
    Value<DocumentCategory>? category,
    Value<String?>? filePath,
    Value<String?>? url,
    Value<int>? fileSize,
    Value<String?>? note,
    Value<bool>? isPinned,
    Value<String>? tags,
    Value<bool>? isPhysical,
    Value<bool>? isAvailableForBorrow,
    Value<String?>? physicalLocation,
    Value<String?>? address,
    Value<double?>? latitude,
    Value<double?>? longitude,
    Value<DateTime>? dateCreated,
    Value<DateTime>? dateTimeModified,
    Value<int>? rowid,
  }) {
    return DocumentsCompanion(
      documentPk: documentPk ?? this.documentPk,
      name: name ?? this.name,
      subjectFk: subjectFk ?? this.subjectFk,
      type: type ?? this.type,
      category: category ?? this.category,
      filePath: filePath ?? this.filePath,
      url: url ?? this.url,
      fileSize: fileSize ?? this.fileSize,
      note: note ?? this.note,
      isPinned: isPinned ?? this.isPinned,
      tags: tags ?? this.tags,
      isPhysical: isPhysical ?? this.isPhysical,
      isAvailableForBorrow: isAvailableForBorrow ?? this.isAvailableForBorrow,
      physicalLocation: physicalLocation ?? this.physicalLocation,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      dateCreated: dateCreated ?? this.dateCreated,
      dateTimeModified: dateTimeModified ?? this.dateTimeModified,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (documentPk.present) {
      map['document_pk'] = Variable<String>(documentPk.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (subjectFk.present) {
      map['subject_fk'] = Variable<String>(subjectFk.value);
    }
    if (type.present) {
      map['type'] = Variable<int>(
        $DocumentsTable.$convertertype.toSql(type.value),
      );
    }
    if (category.present) {
      map['category'] = Variable<int>(
        $DocumentsTable.$convertercategory.toSql(category.value),
      );
    }
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    if (url.present) {
      map['url'] = Variable<String>(url.value);
    }
    if (fileSize.present) {
      map['file_size'] = Variable<int>(fileSize.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (isPinned.present) {
      map['is_pinned'] = Variable<bool>(isPinned.value);
    }
    if (tags.present) {
      map['tags'] = Variable<String>(tags.value);
    }
    if (isPhysical.present) {
      map['is_physical'] = Variable<bool>(isPhysical.value);
    }
    if (isAvailableForBorrow.present) {
      map['is_available_for_borrow'] = Variable<bool>(
        isAvailableForBorrow.value,
      );
    }
    if (physicalLocation.present) {
      map['physical_location'] = Variable<String>(physicalLocation.value);
    }
    if (address.present) {
      map['address'] = Variable<String>(address.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    if (dateCreated.present) {
      map['date_created'] = Variable<DateTime>(dateCreated.value);
    }
    if (dateTimeModified.present) {
      map['date_time_modified'] = Variable<DateTime>(dateTimeModified.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DocumentsCompanion(')
          ..write('documentPk: $documentPk, ')
          ..write('name: $name, ')
          ..write('subjectFk: $subjectFk, ')
          ..write('type: $type, ')
          ..write('category: $category, ')
          ..write('filePath: $filePath, ')
          ..write('url: $url, ')
          ..write('fileSize: $fileSize, ')
          ..write('note: $note, ')
          ..write('isPinned: $isPinned, ')
          ..write('tags: $tags, ')
          ..write('isPhysical: $isPhysical, ')
          ..write('isAvailableForBorrow: $isAvailableForBorrow, ')
          ..write('physicalLocation: $physicalLocation, ')
          ..write('address: $address, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('dateCreated: $dateCreated, ')
          ..write('dateTimeModified: $dateTimeModified, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DeleteLogsTable extends DeleteLogs
    with TableInfo<$DeleteLogsTable, DeleteLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DeleteLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _deleteLogPkMeta = const VerificationMeta(
    'deleteLogPk',
  );
  @override
  late final GeneratedColumn<String> deleteLogPk = GeneratedColumn<String>(
    'delete_log_pk',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => uuid.v4(),
  );
  static const VerificationMeta _entryPkMeta = const VerificationMeta(
    'entryPk',
  );
  @override
  late final GeneratedColumn<String> entryPk = GeneratedColumn<String>(
    'entry_pk',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DeleteLogType, int> type =
      GeneratedColumn<int>(
        'type',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DeleteLogType>($DeleteLogsTable.$convertertype);
  static const VerificationMeta _dateTimeModifiedMeta = const VerificationMeta(
    'dateTimeModified',
  );
  @override
  late final GeneratedColumn<DateTime> dateTimeModified =
      GeneratedColumn<DateTime>(
        'date_time_modified',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
        defaultValue: Constant(DateTime.now()),
      );
  @override
  List<GeneratedColumn> get $columns => [
    deleteLogPk,
    entryPk,
    type,
    dateTimeModified,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'delete_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<DeleteLog> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('delete_log_pk')) {
      context.handle(
        _deleteLogPkMeta,
        deleteLogPk.isAcceptableOrUnknown(
          data['delete_log_pk']!,
          _deleteLogPkMeta,
        ),
      );
    }
    if (data.containsKey('entry_pk')) {
      context.handle(
        _entryPkMeta,
        entryPk.isAcceptableOrUnknown(data['entry_pk']!, _entryPkMeta),
      );
    } else if (isInserting) {
      context.missing(_entryPkMeta);
    }
    if (data.containsKey('date_time_modified')) {
      context.handle(
        _dateTimeModifiedMeta,
        dateTimeModified.isAcceptableOrUnknown(
          data['date_time_modified']!,
          _dateTimeModifiedMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {deleteLogPk};
  @override
  DeleteLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DeleteLog(
      deleteLogPk: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}delete_log_pk'],
      )!,
      entryPk: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entry_pk'],
      )!,
      type: $DeleteLogsTable.$convertertype.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}type'],
        )!,
      ),
      dateTimeModified: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date_time_modified'],
      )!,
    );
  }

  @override
  $DeleteLogsTable createAlias(String alias) {
    return $DeleteLogsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<DeleteLogType, int, int> $convertertype =
      const EnumIndexConverter<DeleteLogType>(DeleteLogType.values);
}

class DeleteLog extends DataClass implements Insertable<DeleteLog> {
  final String deleteLogPk;
  final String entryPk;
  final DeleteLogType type;
  final DateTime dateTimeModified;
  const DeleteLog({
    required this.deleteLogPk,
    required this.entryPk,
    required this.type,
    required this.dateTimeModified,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['delete_log_pk'] = Variable<String>(deleteLogPk);
    map['entry_pk'] = Variable<String>(entryPk);
    {
      map['type'] = Variable<int>($DeleteLogsTable.$convertertype.toSql(type));
    }
    map['date_time_modified'] = Variable<DateTime>(dateTimeModified);
    return map;
  }

  DeleteLogsCompanion toCompanion(bool nullToAbsent) {
    return DeleteLogsCompanion(
      deleteLogPk: Value(deleteLogPk),
      entryPk: Value(entryPk),
      type: Value(type),
      dateTimeModified: Value(dateTimeModified),
    );
  }

  factory DeleteLog.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DeleteLog(
      deleteLogPk: serializer.fromJson<String>(json['deleteLogPk']),
      entryPk: serializer.fromJson<String>(json['entryPk']),
      type: $DeleteLogsTable.$convertertype.fromJson(
        serializer.fromJson<int>(json['type']),
      ),
      dateTimeModified: serializer.fromJson<DateTime>(json['dateTimeModified']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'deleteLogPk': serializer.toJson<String>(deleteLogPk),
      'entryPk': serializer.toJson<String>(entryPk),
      'type': serializer.toJson<int>(
        $DeleteLogsTable.$convertertype.toJson(type),
      ),
      'dateTimeModified': serializer.toJson<DateTime>(dateTimeModified),
    };
  }

  DeleteLog copyWith({
    String? deleteLogPk,
    String? entryPk,
    DeleteLogType? type,
    DateTime? dateTimeModified,
  }) => DeleteLog(
    deleteLogPk: deleteLogPk ?? this.deleteLogPk,
    entryPk: entryPk ?? this.entryPk,
    type: type ?? this.type,
    dateTimeModified: dateTimeModified ?? this.dateTimeModified,
  );
  DeleteLog copyWithCompanion(DeleteLogsCompanion data) {
    return DeleteLog(
      deleteLogPk: data.deleteLogPk.present
          ? data.deleteLogPk.value
          : this.deleteLogPk,
      entryPk: data.entryPk.present ? data.entryPk.value : this.entryPk,
      type: data.type.present ? data.type.value : this.type,
      dateTimeModified: data.dateTimeModified.present
          ? data.dateTimeModified.value
          : this.dateTimeModified,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DeleteLog(')
          ..write('deleteLogPk: $deleteLogPk, ')
          ..write('entryPk: $entryPk, ')
          ..write('type: $type, ')
          ..write('dateTimeModified: $dateTimeModified')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(deleteLogPk, entryPk, type, dateTimeModified);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DeleteLog &&
          other.deleteLogPk == this.deleteLogPk &&
          other.entryPk == this.entryPk &&
          other.type == this.type &&
          other.dateTimeModified == this.dateTimeModified);
}

class DeleteLogsCompanion extends UpdateCompanion<DeleteLog> {
  final Value<String> deleteLogPk;
  final Value<String> entryPk;
  final Value<DeleteLogType> type;
  final Value<DateTime> dateTimeModified;
  final Value<int> rowid;
  const DeleteLogsCompanion({
    this.deleteLogPk = const Value.absent(),
    this.entryPk = const Value.absent(),
    this.type = const Value.absent(),
    this.dateTimeModified = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DeleteLogsCompanion.insert({
    this.deleteLogPk = const Value.absent(),
    required String entryPk,
    required DeleteLogType type,
    this.dateTimeModified = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : entryPk = Value(entryPk),
       type = Value(type);
  static Insertable<DeleteLog> custom({
    Expression<String>? deleteLogPk,
    Expression<String>? entryPk,
    Expression<int>? type,
    Expression<DateTime>? dateTimeModified,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (deleteLogPk != null) 'delete_log_pk': deleteLogPk,
      if (entryPk != null) 'entry_pk': entryPk,
      if (type != null) 'type': type,
      if (dateTimeModified != null) 'date_time_modified': dateTimeModified,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DeleteLogsCompanion copyWith({
    Value<String>? deleteLogPk,
    Value<String>? entryPk,
    Value<DeleteLogType>? type,
    Value<DateTime>? dateTimeModified,
    Value<int>? rowid,
  }) {
    return DeleteLogsCompanion(
      deleteLogPk: deleteLogPk ?? this.deleteLogPk,
      entryPk: entryPk ?? this.entryPk,
      type: type ?? this.type,
      dateTimeModified: dateTimeModified ?? this.dateTimeModified,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (deleteLogPk.present) {
      map['delete_log_pk'] = Variable<String>(deleteLogPk.value);
    }
    if (entryPk.present) {
      map['entry_pk'] = Variable<String>(entryPk.value);
    }
    if (type.present) {
      map['type'] = Variable<int>(
        $DeleteLogsTable.$convertertype.toSql(type.value),
      );
    }
    if (dateTimeModified.present) {
      map['date_time_modified'] = Variable<DateTime>(dateTimeModified.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DeleteLogsCompanion(')
          ..write('deleteLogPk: $deleteLogPk, ')
          ..write('entryPk: $entryPk, ')
          ..write('type: $type, ')
          ..write('dateTimeModified: $dateTimeModified, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SubjectsTable subjects = $SubjectsTable(this);
  late final $DocumentsTable documents = $DocumentsTable(this);
  late final $DeleteLogsTable deleteLogs = $DeleteLogsTable(this);
  late final SubjectDao subjectDao = SubjectDao(this as AppDatabase);
  late final DocumentDao documentDao = DocumentDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    subjects,
    documents,
    deleteLogs,
  ];
}

typedef $$SubjectsTableCreateCompanionBuilder = SubjectsCompanion Function({
  Value<String> subjectPk,
  required String name,
  required String code,
  Value<int> color,
  Value<String> icon,
  Value<DateTime> dateCreated,
  Value<DateTime> dateTimeModified,
  Value<int> rowid,
});
typedef $$SubjectsTableUpdateCompanionBuilder = SubjectsCompanion Function({
  Value<String> subjectPk,
  Value<String> name,
  Value<String> code,
  Value<int> color,
  Value<String> icon,
  Value<DateTime> dateCreated,
  Value<DateTime> dateTimeModified,
  Value<int> rowid,
});

class $$SubjectsTableFilterComposer
    extends Composer<_$AppDatabase, $SubjectsTable> {
  $$SubjectsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get subjectPk => $composableBuilder(
    column: $table.subjectPk,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dateCreated => $composableBuilder(
    column: $table.dateCreated,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dateTimeModified => $composableBuilder(
    column: $table.dateTimeModified,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SubjectsTableOrderingComposer
    extends Composer<_$AppDatabase, $SubjectsTable> {
  $$SubjectsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get subjectPk => $composableBuilder(
    column: $table.subjectPk,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dateCreated => $composableBuilder(
    column: $table.dateCreated,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dateTimeModified => $composableBuilder(
    column: $table.dateTimeModified,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SubjectsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SubjectsTable> {
  $$SubjectsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get subjectPk =>
      $composableBuilder(column: $table.subjectPk, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumn<int> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<String> get icon =>
      $composableBuilder(column: $table.icon, builder: (column) => column);

  GeneratedColumn<DateTime> get dateCreated => $composableBuilder(
    column: $table.dateCreated,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get dateTimeModified => $composableBuilder(
    column: $table.dateTimeModified,
    builder: (column) => column,
  );
}

class $$SubjectsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SubjectsTable,
          Subject,
          $$SubjectsTableFilterComposer,
          $$SubjectsTableOrderingComposer,
          $$SubjectsTableAnnotationComposer,
          $$SubjectsTableCreateCompanionBuilder,
          $$SubjectsTableUpdateCompanionBuilder,
          (Subject, BaseReferences<_$AppDatabase, $SubjectsTable, Subject>),
          Subject,
          PrefetchHooks Function()
        > {
  $$SubjectsTableTableManager(_$AppDatabase db, $SubjectsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SubjectsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SubjectsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SubjectsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> subjectPk = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> code = const Value.absent(),
                Value<int> color = const Value.absent(),
                Value<String> icon = const Value.absent(),
                Value<DateTime> dateCreated = const Value.absent(),
                Value<DateTime> dateTimeModified = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SubjectsCompanion(
                subjectPk: subjectPk,
                name: name,
                code: code,
                color: color,
                icon: icon,
                dateCreated: dateCreated,
                dateTimeModified: dateTimeModified,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> subjectPk = const Value.absent(),
                required String name,
                required String code,
                Value<int> color = const Value.absent(),
                Value<String> icon = const Value.absent(),
                Value<DateTime> dateCreated = const Value.absent(),
                Value<DateTime> dateTimeModified = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SubjectsCompanion.insert(
                subjectPk: subjectPk,
                name: name,
                code: code,
                color: color,
                icon: icon,
                dateCreated: dateCreated,
                dateTimeModified: dateTimeModified,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SubjectsTable, Subject>(table),
                  BaseReferences<_$AppDatabase, $SubjectsTable, Subject>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SubjectsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SubjectsTable,
      Subject,
      $$SubjectsTableFilterComposer,
      $$SubjectsTableOrderingComposer,
      $$SubjectsTableAnnotationComposer,
      $$SubjectsTableCreateCompanionBuilder,
      $$SubjectsTableUpdateCompanionBuilder,
      (Subject, BaseReferences<_$AppDatabase, $SubjectsTable, Subject>),
      Subject,
      PrefetchHooks Function()
    >;
typedef $$DocumentsTableCreateCompanionBuilder = DocumentsCompanion Function({
  Value<String> documentPk,
  required String name,
  required String subjectFk,
  required DocumentType type,
  Value<DocumentCategory> category,
  Value<String?> filePath,
  Value<String?> url,
  Value<int> fileSize,
  Value<String?> note,
  Value<bool> isPinned,
  Value<String> tags,
  Value<bool> isPhysical,
  Value<bool> isAvailableForBorrow,
  Value<String?> physicalLocation,
  Value<String?> address,
  Value<double?> latitude,
  Value<double?> longitude,
  Value<DateTime> dateCreated,
  Value<DateTime> dateTimeModified,
  Value<int> rowid,
});
typedef $$DocumentsTableUpdateCompanionBuilder = DocumentsCompanion Function({
  Value<String> documentPk,
  Value<String> name,
  Value<String> subjectFk,
  Value<DocumentType> type,
  Value<DocumentCategory> category,
  Value<String?> filePath,
  Value<String?> url,
  Value<int> fileSize,
  Value<String?> note,
  Value<bool> isPinned,
  Value<String> tags,
  Value<bool> isPhysical,
  Value<bool> isAvailableForBorrow,
  Value<String?> physicalLocation,
  Value<String?> address,
  Value<double?> latitude,
  Value<double?> longitude,
  Value<DateTime> dateCreated,
  Value<DateTime> dateTimeModified,
  Value<int> rowid,
});

class $$DocumentsTableFilterComposer
    extends Composer<_$AppDatabase, $DocumentsTable> {
  $$DocumentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get documentPk => $composableBuilder(
    column: $table.documentPk,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subjectFk => $composableBuilder(
    column: $table.subjectFk,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DocumentType, DocumentType, int> get type =>
      $composableBuilder(
        column: $table.type,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<DocumentCategory, DocumentCategory, int>
  get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fileSize => $composableBuilder(
    column: $table.fileSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPinned => $composableBuilder(
    column: $table.isPinned,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPhysical => $composableBuilder(
    column: $table.isPhysical,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isAvailableForBorrow => $composableBuilder(
    column: $table.isAvailableForBorrow,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get physicalLocation => $composableBuilder(
    column: $table.physicalLocation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dateCreated => $composableBuilder(
    column: $table.dateCreated,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dateTimeModified => $composableBuilder(
    column: $table.dateTimeModified,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DocumentsTableOrderingComposer
    extends Composer<_$AppDatabase, $DocumentsTable> {
  $$DocumentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get documentPk => $composableBuilder(
    column: $table.documentPk,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subjectFk => $composableBuilder(
    column: $table.subjectFk,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fileSize => $composableBuilder(
    column: $table.fileSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPinned => $composableBuilder(
    column: $table.isPinned,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPhysical => $composableBuilder(
    column: $table.isPhysical,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isAvailableForBorrow => $composableBuilder(
    column: $table.isAvailableForBorrow,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get physicalLocation => $composableBuilder(
    column: $table.physicalLocation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dateCreated => $composableBuilder(
    column: $table.dateCreated,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dateTimeModified => $composableBuilder(
    column: $table.dateTimeModified,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DocumentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DocumentsTable> {
  $$DocumentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get documentPk => $composableBuilder(
    column: $table.documentPk,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get subjectFk =>
      $composableBuilder(column: $table.subjectFk, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DocumentType, int> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DocumentCategory, int> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get filePath =>
      $composableBuilder(column: $table.filePath, builder: (column) => column);

  GeneratedColumn<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => column);

  GeneratedColumn<int> get fileSize =>
      $composableBuilder(column: $table.fileSize, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<bool> get isPinned =>
      $composableBuilder(column: $table.isPinned, builder: (column) => column);

  GeneratedColumn<String> get tags =>
      $composableBuilder(column: $table.tags, builder: (column) => column);

  GeneratedColumn<bool> get isPhysical => $composableBuilder(
    column: $table.isPhysical,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isAvailableForBorrow => $composableBuilder(
    column: $table.isAvailableForBorrow,
    builder: (column) => column,
  );

  GeneratedColumn<String> get physicalLocation => $composableBuilder(
    column: $table.physicalLocation,
    builder: (column) => column,
  );

  GeneratedColumn<String> get address =>
      $composableBuilder(column: $table.address, builder: (column) => column);

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);

  GeneratedColumn<DateTime> get dateCreated => $composableBuilder(
    column: $table.dateCreated,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get dateTimeModified => $composableBuilder(
    column: $table.dateTimeModified,
    builder: (column) => column,
  );
}

class $$DocumentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DocumentsTable,
          Document,
          $$DocumentsTableFilterComposer,
          $$DocumentsTableOrderingComposer,
          $$DocumentsTableAnnotationComposer,
          $$DocumentsTableCreateCompanionBuilder,
          $$DocumentsTableUpdateCompanionBuilder,
          (Document, BaseReferences<_$AppDatabase, $DocumentsTable, Document>),
          Document,
          PrefetchHooks Function()
        > {
  $$DocumentsTableTableManager(_$AppDatabase db, $DocumentsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DocumentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DocumentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DocumentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> documentPk = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> subjectFk = const Value.absent(),
                Value<DocumentType> type = const Value.absent(),
                Value<DocumentCategory> category = const Value.absent(),
                Value<String?> filePath = const Value.absent(),
                Value<String?> url = const Value.absent(),
                Value<int> fileSize = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<bool> isPinned = const Value.absent(),
                Value<String> tags = const Value.absent(),
                Value<bool> isPhysical = const Value.absent(),
                Value<bool> isAvailableForBorrow = const Value.absent(),
                Value<String?> physicalLocation = const Value.absent(),
                Value<String?> address = const Value.absent(),
                Value<double?> latitude = const Value.absent(),
                Value<double?> longitude = const Value.absent(),
                Value<DateTime> dateCreated = const Value.absent(),
                Value<DateTime> dateTimeModified = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DocumentsCompanion(
                documentPk: documentPk,
                name: name,
                subjectFk: subjectFk,
                type: type,
                category: category,
                filePath: filePath,
                url: url,
                fileSize: fileSize,
                note: note,
                isPinned: isPinned,
                tags: tags,
                isPhysical: isPhysical,
                isAvailableForBorrow: isAvailableForBorrow,
                physicalLocation: physicalLocation,
                address: address,
                latitude: latitude,
                longitude: longitude,
                dateCreated: dateCreated,
                dateTimeModified: dateTimeModified,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> documentPk = const Value.absent(),
                required String name,
                required String subjectFk,
                required DocumentType type,
                Value<DocumentCategory> category = const Value.absent(),
                Value<String?> filePath = const Value.absent(),
                Value<String?> url = const Value.absent(),
                Value<int> fileSize = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<bool> isPinned = const Value.absent(),
                Value<String> tags = const Value.absent(),
                Value<bool> isPhysical = const Value.absent(),
                Value<bool> isAvailableForBorrow = const Value.absent(),
                Value<String?> physicalLocation = const Value.absent(),
                Value<String?> address = const Value.absent(),
                Value<double?> latitude = const Value.absent(),
                Value<double?> longitude = const Value.absent(),
                Value<DateTime> dateCreated = const Value.absent(),
                Value<DateTime> dateTimeModified = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DocumentsCompanion.insert(
                documentPk: documentPk,
                name: name,
                subjectFk: subjectFk,
                type: type,
                category: category,
                filePath: filePath,
                url: url,
                fileSize: fileSize,
                note: note,
                isPinned: isPinned,
                tags: tags,
                isPhysical: isPhysical,
                isAvailableForBorrow: isAvailableForBorrow,
                physicalLocation: physicalLocation,
                address: address,
                latitude: latitude,
                longitude: longitude,
                dateCreated: dateCreated,
                dateTimeModified: dateTimeModified,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DocumentsTable, Document>(table),
                  BaseReferences<_$AppDatabase, $DocumentsTable, Document>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DocumentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DocumentsTable,
      Document,
      $$DocumentsTableFilterComposer,
      $$DocumentsTableOrderingComposer,
      $$DocumentsTableAnnotationComposer,
      $$DocumentsTableCreateCompanionBuilder,
      $$DocumentsTableUpdateCompanionBuilder,
      (Document, BaseReferences<_$AppDatabase, $DocumentsTable, Document>),
      Document,
      PrefetchHooks Function()
    >;
typedef $$DeleteLogsTableCreateCompanionBuilder = DeleteLogsCompanion Function({
  Value<String> deleteLogPk,
  required String entryPk,
  required DeleteLogType type,
  Value<DateTime> dateTimeModified,
  Value<int> rowid,
});
typedef $$DeleteLogsTableUpdateCompanionBuilder = DeleteLogsCompanion Function({
  Value<String> deleteLogPk,
  Value<String> entryPk,
  Value<DeleteLogType> type,
  Value<DateTime> dateTimeModified,
  Value<int> rowid,
});

class $$DeleteLogsTableFilterComposer
    extends Composer<_$AppDatabase, $DeleteLogsTable> {
  $$DeleteLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get deleteLogPk => $composableBuilder(
    column: $table.deleteLogPk,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entryPk => $composableBuilder(
    column: $table.entryPk,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DeleteLogType, DeleteLogType, int> get type =>
      $composableBuilder(
        column: $table.type,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<DateTime> get dateTimeModified => $composableBuilder(
    column: $table.dateTimeModified,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DeleteLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $DeleteLogsTable> {
  $$DeleteLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get deleteLogPk => $composableBuilder(
    column: $table.deleteLogPk,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entryPk => $composableBuilder(
    column: $table.entryPk,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dateTimeModified => $composableBuilder(
    column: $table.dateTimeModified,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DeleteLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DeleteLogsTable> {
  $$DeleteLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get deleteLogPk => $composableBuilder(
    column: $table.deleteLogPk,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entryPk =>
      $composableBuilder(column: $table.entryPk, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DeleteLogType, int> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<DateTime> get dateTimeModified => $composableBuilder(
    column: $table.dateTimeModified,
    builder: (column) => column,
  );
}

class $$DeleteLogsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DeleteLogsTable,
          DeleteLog,
          $$DeleteLogsTableFilterComposer,
          $$DeleteLogsTableOrderingComposer,
          $$DeleteLogsTableAnnotationComposer,
          $$DeleteLogsTableCreateCompanionBuilder,
          $$DeleteLogsTableUpdateCompanionBuilder,
          (
            DeleteLog,
            BaseReferences<_$AppDatabase, $DeleteLogsTable, DeleteLog>,
          ),
          DeleteLog,
          PrefetchHooks Function()
        > {
  $$DeleteLogsTableTableManager(_$AppDatabase db, $DeleteLogsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DeleteLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DeleteLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DeleteLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> deleteLogPk = const Value.absent(),
                Value<String> entryPk = const Value.absent(),
                Value<DeleteLogType> type = const Value.absent(),
                Value<DateTime> dateTimeModified = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DeleteLogsCompanion(
                deleteLogPk: deleteLogPk,
                entryPk: entryPk,
                type: type,
                dateTimeModified: dateTimeModified,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> deleteLogPk = const Value.absent(),
                required String entryPk,
                required DeleteLogType type,
                Value<DateTime> dateTimeModified = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DeleteLogsCompanion.insert(
                deleteLogPk: deleteLogPk,
                entryPk: entryPk,
                type: type,
                dateTimeModified: dateTimeModified,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DeleteLogsTable, DeleteLog>(table),
                  BaseReferences<_$AppDatabase, $DeleteLogsTable, DeleteLog>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DeleteLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DeleteLogsTable,
      DeleteLog,
      $$DeleteLogsTableFilterComposer,
      $$DeleteLogsTableOrderingComposer,
      $$DeleteLogsTableAnnotationComposer,
      $$DeleteLogsTableCreateCompanionBuilder,
      $$DeleteLogsTableUpdateCompanionBuilder,
      (DeleteLog, BaseReferences<_$AppDatabase, $DeleteLogsTable, DeleteLog>),
      DeleteLog,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SubjectsTableTableManager get subjects =>
      $$SubjectsTableTableManager(_db, _db.subjects);
  $$DocumentsTableTableManager get documents =>
      $$DocumentsTableTableManager(_db, _db.documents);
  $$DeleteLogsTableTableManager get deleteLogs =>
      $$DeleteLogsTableTableManager(_db, _db.deleteLogs);
}
