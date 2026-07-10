import '../../domain/entities/coach_message.dart';
import '../../domain/models/reader_context.dart';
import '../../domain/repositories/coach_repository.dart';
import '../../domain/services/llm_client.dart';
import '../../domain/services/prompt_builder.dart';

class CoachRepositoryImpl implements CoachRepository {
  const CoachRepositoryImpl({
    required LlmClient llmClient,
    required PromptBuilder promptBuilder,
  }) : _llmClient = llmClient,
       _promptBuilder = promptBuilder;

  final LlmClient _llmClient;
  final PromptBuilder _promptBuilder;

  @override
  Stream<String> streamReply({
    required String userMessage,
    required List<CoachMessage> conversation,
    required ReaderContext readerContext,
    bool conversationIncludesCurrentMessage = false,
    String? conversationSummary,
  }) {
    final messages = _promptBuilder.build(
      userMessage: userMessage,
      conversation: conversation,
      readerContext: readerContext,
      conversationIncludesCurrentMessage: conversationIncludesCurrentMessage,
      conversationSummary: conversationSummary,
    );
    return _llmClient.streamCompletion(messages: messages);
  }
}
