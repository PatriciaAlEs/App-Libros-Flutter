import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/preferences/reader_profile_controller.dart';
import '../../../books/data/repositories/book_repository_provider.dart';
import '../../../reading_sessions/data/repositories/reading_session_repository_provider.dart';
import '../../../stats/data/repositories/annual_reading_goal_repository_provider.dart';
import '../../domain/entities/account_migration_preparation.dart';
import '../../domain/usecases/prepare_account_migration.dart';
import 'auth_controller.dart';

final prepareAccountMigrationProvider = Provider<PrepareAccountMigration>((
  ref,
) {
  return PrepareAccountMigration(
    bookRepository: ref.watch(bookRepositoryProvider),
    readingSessionRepository: ref.watch(readingSessionRepositoryProvider),
    annualReadingGoalRepository: ref.watch(annualReadingGoalRepositoryProvider),
  );
});

final accountMigrationControllerProvider =
    AsyncNotifierProvider.autoDispose<
      AccountMigrationController,
      AccountMigrationPreparation
    >(AccountMigrationController.new);

class AccountMigrationController
    extends AutoDisposeAsyncNotifier<AccountMigrationPreparation> {
  @override
  Future<AccountMigrationPreparation> build() {
    final authState = ref.watch(authControllerProvider);
    final readerProfile = ref.watch(readerProfileControllerProvider);
    final prepareAccountMigration = ref.watch(prepareAccountMigrationProvider);

    return prepareAccountMigration(
      user: authState.user,
      hasReaderProfileData: _hasReaderProfileData(readerProfile),
    );
  }

  bool _hasReaderProfileData(ReaderProfile profile) {
    return profile.displayName.isNotEmpty ||
        profile.customGreeting.trim().isNotEmpty ||
        profile.currentReadingBookId != null ||
        profile.greetingPreference != ReaderGreetingPreference.female;
  }
}
