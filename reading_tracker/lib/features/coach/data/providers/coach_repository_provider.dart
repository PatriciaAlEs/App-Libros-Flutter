import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/database_provider.dart';
import '../../domain/repositories/coach_conversation_repository.dart';
import '../../domain/repositories/coach_repository.dart';
import '../../domain/services/conversation_context_policy.dart';
import '../../domain/services/conversation_summary_service.dart';
import '../../domain/services/bookish_culture_retriever.dart';
import '../culture/bookish_culture_es_v1.dart';
import '../../domain/services/coach_system_prompt_builder.dart';
import '../../domain/services/context_formatter.dart';
import '../../domain/services/prompt_builder.dart';
import '../repositories/coach_repository_impl.dart';
import '../daos/coach_conversation_dao.dart';
import '../repositories/drift_coach_conversation_repository.dart';
import 'coach_llm_providers.dart';

final promptBuilderProvider = Provider<PromptBuilder>((ref) {
  return const CoachPromptBuilder(
    systemPromptBuilder: DefaultCoachSystemPromptBuilder(),
    contextFormatter: MarkdownContextFormatter(),
    bookishCultureRetriever: BookishCultureRetriever(
      entries: bookishCultureEsV1,
    ),
  );
});

final coachRepositoryProvider = Provider<CoachRepository>((ref) {
  return CoachRepositoryImpl(
    llmClient: ref.watch(llmClientProvider),
    promptBuilder: ref.watch(promptBuilderProvider),
  );
});

final conversationContextPolicyProvider = Provider<ConversationContextPolicy>(
  (ref) => const ConversationContextPolicy(),
);

final coachConversationDaoProvider = Provider<CoachConversationDao>((ref) {
  return CoachConversationDao(ref.watch(databaseProvider));
});

final coachConversationRepositoryProvider =
    Provider<CoachConversationRepository>((ref) {
      return DriftCoachConversationRepository(
        ref.watch(coachConversationDaoProvider),
      );
    });

final conversationSummaryServiceProvider = Provider<ConversationSummaryService>(
  (ref) => LlmConversationSummaryService(
    client: ref.watch(llmClientProvider),
    policy: ref.watch(conversationContextPolicyProvider),
  ),
);
