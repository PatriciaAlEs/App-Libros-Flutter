import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repositories/coach_repository.dart';
import '../repositories/coach_repository_impl.dart';
import 'coach_llm_providers.dart';

final coachRepositoryProvider = Provider<CoachRepository>((ref) {
  return CoachRepositoryImpl(ref.watch(llmClientProvider));
});
