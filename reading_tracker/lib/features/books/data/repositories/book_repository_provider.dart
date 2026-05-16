import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/database_provider.dart';
import '../../domain/repositories/book_repository.dart';
import 'book_repository_impl.dart';

final bookRepositoryImplProvider = Provider<BookRepositoryImpl>(
  (ref) => BookRepositoryImpl(ref.watch(databaseProvider)),
);

final bookRepositoryProvider = Provider<BookRepository>(
  (ref) => ref.watch(bookRepositoryImplProvider),
);
