import '../entities/coach_message.dart';
import '../models/reader_context.dart';
import 'coach_system_\u0070rompt_builder.dart';
import 'context_formatter.dart';
import 'llm_client.dart';

abstract class CoachEngine {
  Future<CoachMessage> sendMessage({
    required String userMessage,
    required ReaderContext readerContext,
  });
}

class DefaultCoachEngine implements CoachEngine {
  const DefaultCoachEngine({
    required this.contextFormatter,
    required this.systemPromptBuilder,
    required this.llmClient,
  });

  final ContextFormatter contextFormatter;
  final CoachSystemPromptBuilder systemPromptBuilder;
  final LlmClient llmClient;

  @override
  Future<CoachMessage> sendMessage({
    required String userMessage,
    required ReaderContext readerContext,
  }) async {
    if (userMessage.trim().isEmpty) {
      throw ArgumentError.value(
        userMessage,
        'userMessage',
        'User message cannot be empty',
      );
    }

    final formattedContext = contextFormatter.format(readerContext);
    final messages = [
      CoachMessage.system(systemPromptBuilder.build()),
      CoachMessage.system(formattedContext),
      CoachMessage.user(userMessage),
    ];
    final response = await llmClient.complete(messages: messages);

    return CoachMessage.assistant(response);
  }
}
