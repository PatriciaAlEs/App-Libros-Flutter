import '../../domain/entities/coach_message.dart';
import '../../domain/models/reader_context.dart';
import '../../domain/repositories/coach_repository.dart';
import '../../domain/services/llm_client.dart';
import '../../domain/services/prompt_builder.dart';
import '../../domain/services/bibliographic_recommendation_service.dart';

class CoachRepositoryImpl implements CoachRepository {
  const CoachRepositoryImpl({
    required LlmClient llmClient,
    required PromptBuilder promptBuilder,
    BibliographicRecommendationService? bibliographicRecommendationService,
  }) : _llmClient = llmClient,
       _promptBuilder = promptBuilder,
       _bibliographicRecommendationService = bibliographicRecommendationService;

  final LlmClient _llmClient;
  final PromptBuilder _promptBuilder;
  final BibliographicRecommendationService? _bibliographicRecommendationService;

  @override
  Stream<String> streamReply({
    required String userMessage,
    required List<CoachMessage> conversation,
    required ReaderContext readerContext,
    bool conversationIncludesCurrentMessage = false,
    String? conversationSummary,
  }) async* {
    final verifiedBibliographicContext =
        await _bibliographicRecommendationService?.prepareContext(
          userMessage: userMessage,
          conversation: conversation,
          readerContext: readerContext,
        );
    final messages = _promptBuilder.build(
      userMessage: userMessage,
      conversation: conversation,
      readerContext: readerContext,
      conversationIncludesCurrentMessage: conversationIncludesCurrentMessage,
      conversationSummary: conversationSummary,
      verifiedBibliographicContext: verifiedBibliographicContext,
    );
    yield* _llmClient.streamCompletion(messages: messages);
  }
}
