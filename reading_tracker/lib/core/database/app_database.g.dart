// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $BooksTableTable extends BooksTable
    with TableInfo<$BooksTableTable, BooksTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BooksTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _authorMeta = const VerificationMeta('author');
  @override
  late final GeneratedColumn<String> author = GeneratedColumn<String>(
    'author',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _publisherMeta = const VerificationMeta(
    'publisher',
  );
  @override
  late final GeneratedColumn<String> publisher = GeneratedColumn<String>(
    'publisher',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _coverUrlMeta = const VerificationMeta(
    'coverUrl',
  );
  @override
  late final GeneratedColumn<String> coverUrl = GeneratedColumn<String>(
    'cover_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isbnMeta = const VerificationMeta('isbn');
  @override
  late final GeneratedColumn<String> isbn = GeneratedColumn<String>(
    'isbn',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _firstPublishYearMeta = const VerificationMeta(
    'firstPublishYear',
  );
  @override
  late final GeneratedColumn<int> firstPublishYear = GeneratedColumn<int>(
    'first_publish_year',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _totalPagesMeta = const VerificationMeta(
    'totalPages',
  );
  @override
  late final GeneratedColumn<int> totalPages = GeneratedColumn<int>(
    'total_pages',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _currentPageMeta = const VerificationMeta(
    'currentPage',
  );
  @override
  late final GeneratedColumn<int> currentPage = GeneratedColumn<int>(
    'current_page',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ratingMeta = const VerificationMeta('rating');
  @override
  late final GeneratedColumn<double> rating = GeneratedColumn<double>(
    'rating',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _startDateMeta = const VerificationMeta(
    'startDate',
  );
  @override
  late final GeneratedColumn<DateTime> startDate = GeneratedColumn<DateTime>(
    'start_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _completedDateMeta = const VerificationMeta(
    'completedDate',
  );
  @override
  late final GeneratedColumn<DateTime> completedDate =
      GeneratedColumn<DateTime>(
        'completed_date',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    author,
    publisher,
    coverUrl,
    isbn,
    firstPublishYear,
    totalPages,
    currentPage,
    rating,
    notes,
    status,
    startDate,
    completedDate,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'books';
  @override
  VerificationContext validateIntegrity(
    Insertable<BooksTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('author')) {
      context.handle(
        _authorMeta,
        author.isAcceptableOrUnknown(data['author']!, _authorMeta),
      );
    }
    if (data.containsKey('publisher')) {
      context.handle(
        _publisherMeta,
        publisher.isAcceptableOrUnknown(data['publisher']!, _publisherMeta),
      );
    }
    if (data.containsKey('cover_url')) {
      context.handle(
        _coverUrlMeta,
        coverUrl.isAcceptableOrUnknown(data['cover_url']!, _coverUrlMeta),
      );
    }
    if (data.containsKey('isbn')) {
      context.handle(
        _isbnMeta,
        isbn.isAcceptableOrUnknown(data['isbn']!, _isbnMeta),
      );
    }
    if (data.containsKey('first_publish_year')) {
      context.handle(
        _firstPublishYearMeta,
        firstPublishYear.isAcceptableOrUnknown(
          data['first_publish_year']!,
          _firstPublishYearMeta,
        ),
      );
    }
    if (data.containsKey('total_pages')) {
      context.handle(
        _totalPagesMeta,
        totalPages.isAcceptableOrUnknown(data['total_pages']!, _totalPagesMeta),
      );
    }
    if (data.containsKey('current_page')) {
      context.handle(
        _currentPageMeta,
        currentPage.isAcceptableOrUnknown(
          data['current_page']!,
          _currentPageMeta,
        ),
      );
    }
    if (data.containsKey('rating')) {
      context.handle(
        _ratingMeta,
        rating.isAcceptableOrUnknown(data['rating']!, _ratingMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('start_date')) {
      context.handle(
        _startDateMeta,
        startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta),
      );
    }
    if (data.containsKey('completed_date')) {
      context.handle(
        _completedDateMeta,
        completedDate.isAcceptableOrUnknown(
          data['completed_date']!,
          _completedDateMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BooksTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BooksTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      author: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}author'],
      ),
      publisher: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}publisher'],
      ),
      coverUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cover_url'],
      ),
      isbn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}isbn'],
      ),
      firstPublishYear: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}first_publish_year'],
      ),
      totalPages: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_pages'],
      ),
      currentPage: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}current_page'],
      ),
      rating: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}rating'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      startDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}start_date'],
      ),
      completedDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_date'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $BooksTableTable createAlias(String alias) {
    return $BooksTableTable(attachedDatabase, alias);
  }
}

class BooksTableData extends DataClass implements Insertable<BooksTableData> {
  final String id;
  final String title;
  final String? author;
  final String? publisher;
  final String? coverUrl;
  final String? isbn;
  final int? firstPublishYear;
  final int? totalPages;
  final int? currentPage;
  final double? rating;
  final String? notes;
  final String status;
  final DateTime? startDate;
  final DateTime? completedDate;
  final DateTime createdAt;
  const BooksTableData({
    required this.id,
    required this.title,
    this.author,
    this.publisher,
    this.coverUrl,
    this.isbn,
    this.firstPublishYear,
    this.totalPages,
    this.currentPage,
    this.rating,
    this.notes,
    required this.status,
    this.startDate,
    this.completedDate,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || author != null) {
      map['author'] = Variable<String>(author);
    }
    if (!nullToAbsent || publisher != null) {
      map['publisher'] = Variable<String>(publisher);
    }
    if (!nullToAbsent || coverUrl != null) {
      map['cover_url'] = Variable<String>(coverUrl);
    }
    if (!nullToAbsent || isbn != null) {
      map['isbn'] = Variable<String>(isbn);
    }
    if (!nullToAbsent || firstPublishYear != null) {
      map['first_publish_year'] = Variable<int>(firstPublishYear);
    }
    if (!nullToAbsent || totalPages != null) {
      map['total_pages'] = Variable<int>(totalPages);
    }
    if (!nullToAbsent || currentPage != null) {
      map['current_page'] = Variable<int>(currentPage);
    }
    if (!nullToAbsent || rating != null) {
      map['rating'] = Variable<double>(rating);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || startDate != null) {
      map['start_date'] = Variable<DateTime>(startDate);
    }
    if (!nullToAbsent || completedDate != null) {
      map['completed_date'] = Variable<DateTime>(completedDate);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  BooksTableCompanion toCompanion(bool nullToAbsent) {
    return BooksTableCompanion(
      id: Value(id),
      title: Value(title),
      author: author == null && nullToAbsent
          ? const Value.absent()
          : Value(author),
      publisher: publisher == null && nullToAbsent
          ? const Value.absent()
          : Value(publisher),
      coverUrl: coverUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(coverUrl),
      isbn: isbn == null && nullToAbsent ? const Value.absent() : Value(isbn),
      firstPublishYear: firstPublishYear == null && nullToAbsent
          ? const Value.absent()
          : Value(firstPublishYear),
      totalPages: totalPages == null && nullToAbsent
          ? const Value.absent()
          : Value(totalPages),
      currentPage: currentPage == null && nullToAbsent
          ? const Value.absent()
          : Value(currentPage),
      rating: rating == null && nullToAbsent
          ? const Value.absent()
          : Value(rating),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      status: Value(status),
      startDate: startDate == null && nullToAbsent
          ? const Value.absent()
          : Value(startDate),
      completedDate: completedDate == null && nullToAbsent
          ? const Value.absent()
          : Value(completedDate),
      createdAt: Value(createdAt),
    );
  }

  factory BooksTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BooksTableData(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      author: serializer.fromJson<String?>(json['author']),
      publisher: serializer.fromJson<String?>(json['publisher']),
      coverUrl: serializer.fromJson<String?>(json['coverUrl']),
      isbn: serializer.fromJson<String?>(json['isbn']),
      firstPublishYear: serializer.fromJson<int?>(json['firstPublishYear']),
      totalPages: serializer.fromJson<int?>(json['totalPages']),
      currentPage: serializer.fromJson<int?>(json['currentPage']),
      rating: serializer.fromJson<double?>(json['rating']),
      notes: serializer.fromJson<String?>(json['notes']),
      status: serializer.fromJson<String>(json['status']),
      startDate: serializer.fromJson<DateTime?>(json['startDate']),
      completedDate: serializer.fromJson<DateTime?>(json['completedDate']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'author': serializer.toJson<String?>(author),
      'publisher': serializer.toJson<String?>(publisher),
      'coverUrl': serializer.toJson<String?>(coverUrl),
      'isbn': serializer.toJson<String?>(isbn),
      'firstPublishYear': serializer.toJson<int?>(firstPublishYear),
      'totalPages': serializer.toJson<int?>(totalPages),
      'currentPage': serializer.toJson<int?>(currentPage),
      'rating': serializer.toJson<double?>(rating),
      'notes': serializer.toJson<String?>(notes),
      'status': serializer.toJson<String>(status),
      'startDate': serializer.toJson<DateTime?>(startDate),
      'completedDate': serializer.toJson<DateTime?>(completedDate),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  BooksTableData copyWith({
    String? id,
    String? title,
    Value<String?> author = const Value.absent(),
    Value<String?> publisher = const Value.absent(),
    Value<String?> coverUrl = const Value.absent(),
    Value<String?> isbn = const Value.absent(),
    Value<int?> firstPublishYear = const Value.absent(),
    Value<int?> totalPages = const Value.absent(),
    Value<int?> currentPage = const Value.absent(),
    Value<double?> rating = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    String? status,
    Value<DateTime?> startDate = const Value.absent(),
    Value<DateTime?> completedDate = const Value.absent(),
    DateTime? createdAt,
  }) => BooksTableData(
    id: id ?? this.id,
    title: title ?? this.title,
    author: author.present ? author.value : this.author,
    publisher: publisher.present ? publisher.value : this.publisher,
    coverUrl: coverUrl.present ? coverUrl.value : this.coverUrl,
    isbn: isbn.present ? isbn.value : this.isbn,
    firstPublishYear: firstPublishYear.present
        ? firstPublishYear.value
        : this.firstPublishYear,
    totalPages: totalPages.present ? totalPages.value : this.totalPages,
    currentPage: currentPage.present ? currentPage.value : this.currentPage,
    rating: rating.present ? rating.value : this.rating,
    notes: notes.present ? notes.value : this.notes,
    status: status ?? this.status,
    startDate: startDate.present ? startDate.value : this.startDate,
    completedDate: completedDate.present
        ? completedDate.value
        : this.completedDate,
    createdAt: createdAt ?? this.createdAt,
  );
  BooksTableData copyWithCompanion(BooksTableCompanion data) {
    return BooksTableData(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      author: data.author.present ? data.author.value : this.author,
      publisher: data.publisher.present ? data.publisher.value : this.publisher,
      coverUrl: data.coverUrl.present ? data.coverUrl.value : this.coverUrl,
      isbn: data.isbn.present ? data.isbn.value : this.isbn,
      firstPublishYear: data.firstPublishYear.present
          ? data.firstPublishYear.value
          : this.firstPublishYear,
      totalPages: data.totalPages.present
          ? data.totalPages.value
          : this.totalPages,
      currentPage: data.currentPage.present
          ? data.currentPage.value
          : this.currentPage,
      rating: data.rating.present ? data.rating.value : this.rating,
      notes: data.notes.present ? data.notes.value : this.notes,
      status: data.status.present ? data.status.value : this.status,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      completedDate: data.completedDate.present
          ? data.completedDate.value
          : this.completedDate,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BooksTableData(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('author: $author, ')
          ..write('publisher: $publisher, ')
          ..write('coverUrl: $coverUrl, ')
          ..write('isbn: $isbn, ')
          ..write('firstPublishYear: $firstPublishYear, ')
          ..write('totalPages: $totalPages, ')
          ..write('currentPage: $currentPage, ')
          ..write('rating: $rating, ')
          ..write('notes: $notes, ')
          ..write('status: $status, ')
          ..write('startDate: $startDate, ')
          ..write('completedDate: $completedDate, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    author,
    publisher,
    coverUrl,
    isbn,
    firstPublishYear,
    totalPages,
    currentPage,
    rating,
    notes,
    status,
    startDate,
    completedDate,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BooksTableData &&
          other.id == this.id &&
          other.title == this.title &&
          other.author == this.author &&
          other.publisher == this.publisher &&
          other.coverUrl == this.coverUrl &&
          other.isbn == this.isbn &&
          other.firstPublishYear == this.firstPublishYear &&
          other.totalPages == this.totalPages &&
          other.currentPage == this.currentPage &&
          other.rating == this.rating &&
          other.notes == this.notes &&
          other.status == this.status &&
          other.startDate == this.startDate &&
          other.completedDate == this.completedDate &&
          other.createdAt == this.createdAt);
}

class BooksTableCompanion extends UpdateCompanion<BooksTableData> {
  final Value<String> id;
  final Value<String> title;
  final Value<String?> author;
  final Value<String?> publisher;
  final Value<String?> coverUrl;
  final Value<String?> isbn;
  final Value<int?> firstPublishYear;
  final Value<int?> totalPages;
  final Value<int?> currentPage;
  final Value<double?> rating;
  final Value<String?> notes;
  final Value<String> status;
  final Value<DateTime?> startDate;
  final Value<DateTime?> completedDate;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const BooksTableCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.author = const Value.absent(),
    this.publisher = const Value.absent(),
    this.coverUrl = const Value.absent(),
    this.isbn = const Value.absent(),
    this.firstPublishYear = const Value.absent(),
    this.totalPages = const Value.absent(),
    this.currentPage = const Value.absent(),
    this.rating = const Value.absent(),
    this.notes = const Value.absent(),
    this.status = const Value.absent(),
    this.startDate = const Value.absent(),
    this.completedDate = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BooksTableCompanion.insert({
    required String id,
    required String title,
    this.author = const Value.absent(),
    this.publisher = const Value.absent(),
    this.coverUrl = const Value.absent(),
    this.isbn = const Value.absent(),
    this.firstPublishYear = const Value.absent(),
    this.totalPages = const Value.absent(),
    this.currentPage = const Value.absent(),
    this.rating = const Value.absent(),
    this.notes = const Value.absent(),
    this.status = const Value.absent(),
    this.startDate = const Value.absent(),
    this.completedDate = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title);
  static Insertable<BooksTableData> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? author,
    Expression<String>? publisher,
    Expression<String>? coverUrl,
    Expression<String>? isbn,
    Expression<int>? firstPublishYear,
    Expression<int>? totalPages,
    Expression<int>? currentPage,
    Expression<double>? rating,
    Expression<String>? notes,
    Expression<String>? status,
    Expression<DateTime>? startDate,
    Expression<DateTime>? completedDate,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (author != null) 'author': author,
      if (publisher != null) 'publisher': publisher,
      if (coverUrl != null) 'cover_url': coverUrl,
      if (isbn != null) 'isbn': isbn,
      if (firstPublishYear != null) 'first_publish_year': firstPublishYear,
      if (totalPages != null) 'total_pages': totalPages,
      if (currentPage != null) 'current_page': currentPage,
      if (rating != null) 'rating': rating,
      if (notes != null) 'notes': notes,
      if (status != null) 'status': status,
      if (startDate != null) 'start_date': startDate,
      if (completedDate != null) 'completed_date': completedDate,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BooksTableCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<String?>? author,
    Value<String?>? publisher,
    Value<String?>? coverUrl,
    Value<String?>? isbn,
    Value<int?>? firstPublishYear,
    Value<int?>? totalPages,
    Value<int?>? currentPage,
    Value<double?>? rating,
    Value<String?>? notes,
    Value<String>? status,
    Value<DateTime?>? startDate,
    Value<DateTime?>? completedDate,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return BooksTableCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      publisher: publisher ?? this.publisher,
      coverUrl: coverUrl ?? this.coverUrl,
      isbn: isbn ?? this.isbn,
      firstPublishYear: firstPublishYear ?? this.firstPublishYear,
      totalPages: totalPages ?? this.totalPages,
      currentPage: currentPage ?? this.currentPage,
      rating: rating ?? this.rating,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      completedDate: completedDate ?? this.completedDate,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (author.present) {
      map['author'] = Variable<String>(author.value);
    }
    if (publisher.present) {
      map['publisher'] = Variable<String>(publisher.value);
    }
    if (coverUrl.present) {
      map['cover_url'] = Variable<String>(coverUrl.value);
    }
    if (isbn.present) {
      map['isbn'] = Variable<String>(isbn.value);
    }
    if (firstPublishYear.present) {
      map['first_publish_year'] = Variable<int>(firstPublishYear.value);
    }
    if (totalPages.present) {
      map['total_pages'] = Variable<int>(totalPages.value);
    }
    if (currentPage.present) {
      map['current_page'] = Variable<int>(currentPage.value);
    }
    if (rating.present) {
      map['rating'] = Variable<double>(rating.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<DateTime>(startDate.value);
    }
    if (completedDate.present) {
      map['completed_date'] = Variable<DateTime>(completedDate.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BooksTableCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('author: $author, ')
          ..write('publisher: $publisher, ')
          ..write('coverUrl: $coverUrl, ')
          ..write('isbn: $isbn, ')
          ..write('firstPublishYear: $firstPublishYear, ')
          ..write('totalPages: $totalPages, ')
          ..write('currentPage: $currentPage, ')
          ..write('rating: $rating, ')
          ..write('notes: $notes, ')
          ..write('status: $status, ')
          ..write('startDate: $startDate, ')
          ..write('completedDate: $completedDate, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $BooksTableTable booksTable = $BooksTableTable(this);
  late final BookDao bookDao = BookDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [booksTable];
}

typedef $$BooksTableTableCreateCompanionBuilder =
    BooksTableCompanion Function({
      required String id,
      required String title,
      Value<String?> author,
      Value<String?> publisher,
      Value<String?> coverUrl,
      Value<String?> isbn,
      Value<int?> firstPublishYear,
      Value<int?> totalPages,
      Value<int?> currentPage,
      Value<double?> rating,
      Value<String?> notes,
      Value<String> status,
      Value<DateTime?> startDate,
      Value<DateTime?> completedDate,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });
typedef $$BooksTableTableUpdateCompanionBuilder =
    BooksTableCompanion Function({
      Value<String> id,
      Value<String> title,
      Value<String?> author,
      Value<String?> publisher,
      Value<String?> coverUrl,
      Value<String?> isbn,
      Value<int?> firstPublishYear,
      Value<int?> totalPages,
      Value<int?> currentPage,
      Value<double?> rating,
      Value<String?> notes,
      Value<String> status,
      Value<DateTime?> startDate,
      Value<DateTime?> completedDate,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$BooksTableTableFilterComposer
    extends Composer<_$AppDatabase, $BooksTableTable> {
  $$BooksTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get author => $composableBuilder(
    column: $table.author,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get publisher => $composableBuilder(
    column: $table.publisher,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get coverUrl => $composableBuilder(
    column: $table.coverUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get isbn => $composableBuilder(
    column: $table.isbn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get firstPublishYear => $composableBuilder(
    column: $table.firstPublishYear,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalPages => $composableBuilder(
    column: $table.totalPages,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get currentPage => $composableBuilder(
    column: $table.currentPage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedDate => $composableBuilder(
    column: $table.completedDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BooksTableTableOrderingComposer
    extends Composer<_$AppDatabase, $BooksTableTable> {
  $$BooksTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get author => $composableBuilder(
    column: $table.author,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get publisher => $composableBuilder(
    column: $table.publisher,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get coverUrl => $composableBuilder(
    column: $table.coverUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get isbn => $composableBuilder(
    column: $table.isbn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get firstPublishYear => $composableBuilder(
    column: $table.firstPublishYear,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalPages => $composableBuilder(
    column: $table.totalPages,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get currentPage => $composableBuilder(
    column: $table.currentPage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedDate => $composableBuilder(
    column: $table.completedDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BooksTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $BooksTableTable> {
  $$BooksTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get author =>
      $composableBuilder(column: $table.author, builder: (column) => column);

  GeneratedColumn<String> get publisher =>
      $composableBuilder(column: $table.publisher, builder: (column) => column);

  GeneratedColumn<String> get coverUrl =>
      $composableBuilder(column: $table.coverUrl, builder: (column) => column);

  GeneratedColumn<String> get isbn =>
      $composableBuilder(column: $table.isbn, builder: (column) => column);

  GeneratedColumn<int> get firstPublishYear => $composableBuilder(
    column: $table.firstPublishYear,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalPages => $composableBuilder(
    column: $table.totalPages,
    builder: (column) => column,
  );

  GeneratedColumn<int> get currentPage => $composableBuilder(
    column: $table.currentPage,
    builder: (column) => column,
  );

  GeneratedColumn<double> get rating =>
      $composableBuilder(column: $table.rating, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<DateTime> get completedDate => $composableBuilder(
    column: $table.completedDate,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$BooksTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BooksTableTable,
          BooksTableData,
          $$BooksTableTableFilterComposer,
          $$BooksTableTableOrderingComposer,
          $$BooksTableTableAnnotationComposer,
          $$BooksTableTableCreateCompanionBuilder,
          $$BooksTableTableUpdateCompanionBuilder,
          (
            BooksTableData,
            BaseReferences<_$AppDatabase, $BooksTableTable, BooksTableData>,
          ),
          BooksTableData,
          PrefetchHooks Function()
        > {
  $$BooksTableTableTableManager(_$AppDatabase db, $BooksTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BooksTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BooksTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BooksTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> author = const Value.absent(),
                Value<String?> publisher = const Value.absent(),
                Value<String?> coverUrl = const Value.absent(),
                Value<String?> isbn = const Value.absent(),
                Value<int?> firstPublishYear = const Value.absent(),
                Value<int?> totalPages = const Value.absent(),
                Value<int?> currentPage = const Value.absent(),
                Value<double?> rating = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime?> startDate = const Value.absent(),
                Value<DateTime?> completedDate = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BooksTableCompanion(
                id: id,
                title: title,
                author: author,
                publisher: publisher,
                coverUrl: coverUrl,
                isbn: isbn,
                firstPublishYear: firstPublishYear,
                totalPages: totalPages,
                currentPage: currentPage,
                rating: rating,
                notes: notes,
                status: status,
                startDate: startDate,
                completedDate: completedDate,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                Value<String?> author = const Value.absent(),
                Value<String?> publisher = const Value.absent(),
                Value<String?> coverUrl = const Value.absent(),
                Value<String?> isbn = const Value.absent(),
                Value<int?> firstPublishYear = const Value.absent(),
                Value<int?> totalPages = const Value.absent(),
                Value<int?> currentPage = const Value.absent(),
                Value<double?> rating = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime?> startDate = const Value.absent(),
                Value<DateTime?> completedDate = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BooksTableCompanion.insert(
                id: id,
                title: title,
                author: author,
                publisher: publisher,
                coverUrl: coverUrl,
                isbn: isbn,
                firstPublishYear: firstPublishYear,
                totalPages: totalPages,
                currentPage: currentPage,
                rating: rating,
                notes: notes,
                status: status,
                startDate: startDate,
                completedDate: completedDate,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BooksTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BooksTableTable,
      BooksTableData,
      $$BooksTableTableFilterComposer,
      $$BooksTableTableOrderingComposer,
      $$BooksTableTableAnnotationComposer,
      $$BooksTableTableCreateCompanionBuilder,
      $$BooksTableTableUpdateCompanionBuilder,
      (
        BooksTableData,
        BaseReferences<_$AppDatabase, $BooksTableTable, BooksTableData>,
      ),
      BooksTableData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$BooksTableTableTableManager get booksTable =>
      $$BooksTableTableTableManager(_db, _db.booksTable);
}
