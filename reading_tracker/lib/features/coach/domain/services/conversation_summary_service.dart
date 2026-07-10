import '../entities/coach_message.dart';
import 'conversation_context_policy.dart';
import 'llm_client.dart';

abstract interface class ConversationSummaryService {
  Future<String?> summarizeIfNeeded({
    required List<CoachMessage> messages,
    String? previousSummary,
  });
}

class LlmConversationSummaryService implements ConversationSummaryService {
  const LlmConversationSummaryService({
    required this.client,
    required this.policy,
  });
  final LlmClient client;
  final ConversationContextPolicy policy;

  @override
  Future<String?> summarizeIfNeeded({
    required List<CoachMessage> messages,
    String? previousSummary,
  }) async {
    if (!policy.shouldSummarize(messages)) {
      return previousSummary;
    }
    final oldMessages = policy.messagesToSummarize(messages);
    if (oldMessages.isEmpty) {
      return previousSummary;
    }
    try {
      final transcript = oldMessages
          .map((message) => '${message.role.name}: ${message.content}')
          .join('\n');
      return await client.complete(
        messages: [
          CoachMessage.system(
            'Resume fielmente esta conversación. Conserva temas, preferencias, '
            'recomendaciones, decisiones y preguntas pendientes. No inventes datos.',
          ),
          if (previousSummary?.trim().isNotEmpty == true)
            CoachMessage.system('Resumen anterior:\n$previousSummary'),
          CoachMessage.user(transcript),
        ],
      );
    } catch (_) {
      return previousSummary;
    }
  }
}
