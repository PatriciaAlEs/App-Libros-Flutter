import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/database_provider.dart';
import '../../domain/repositories/book_repository.dart';
import '../../domain/repositories/book_search_repository.dart';
import '../datasources/book_api_datasource.dart';
import '../datasources/google_books_datasource.dart';
import 'book_repository_impl.dart';
import 'book_search_repository_impl.dart';

final bookRepositoryImplProvider = Provider<BookRepositoryImpl>(
  (ref) => BookRepositoryImpl(ref.watch(databaseProvider)),
);

final bookRepositoryProvider = Provider<BookRepository>(
  (ref) => ref.watch(bookRepositoryImplProvider),
);

final bookSearchRepositoryProvider = Provider<BookSearchRepository>(
  (ref) => BookSearchRepositoryImpl(
    openLibraryDatasource: ref.watch(bookApiDatasourceProvider),
    googleBooksDatasource: ref.watch(googleBooksDatasourceProvider),
  ),
);
