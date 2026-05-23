import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../books/data/repositories/book_repository_provider.dart';
import '../../data/repositories/reading_session_repository_provider.dart';
import '../../domain/usecases/register_reading_session.dart';

final registerReadingSessionProvider = Provider<RegisterReadingSession>((ref) {
  return RegisterReadingSession(
    sessionRepository: ref.watch(readingSessionRepositoryProvider),
    bookRepository: ref.watch(bookRepositoryProvider),
  );
});
