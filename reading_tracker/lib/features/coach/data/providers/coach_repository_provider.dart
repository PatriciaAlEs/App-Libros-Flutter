import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repositories/coach_repository.dart';
import '../../domain/services/coach_system_prompt_builder.dart';
import '../../domain/services/context_formatter.dart';
import '../../domain/services/prompt_builder.dart';
import '../repositories/coach_repository_impl.dart';
import 'coach_llm_providers.dart';

final promptBuilderProvider = Provider<PromptBuilder>((ref) {
  return const CoachPromptBuilder(
    systemPromptBuilder: DefaultCoachSystemPromptBuilder(),
    contextFormatter: MarkdownContextFormatter(),
  );
});

final coachRepositoryProvider = Provider<CoachRepository>((ref) {
  return CoachRepositoryImpl(
    llmClient: ref.watch(llmClientProvider),
    promptBuilder: ref.watch(promptBuilderProvider),
  );
});
