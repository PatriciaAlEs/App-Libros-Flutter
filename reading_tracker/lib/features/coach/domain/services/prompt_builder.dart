import '../entities/coach_message.dart';
import '../models/reader_context.dart';
import 'coach_system_prompt_builder.dart';
import 'context_formatter.dart';

abstract interface class PromptBuilder {
  List<CoachMessage> build({
    required String userMessage,
    required List<CoachMessage> conversation,
    required ReaderContext readerContext,
    bool conversationIncludesCurrentMessage = false,
  });
}

final class CoachPromptBuilder implements PromptBuilder {
  const CoachPromptBuilder({
    required this.systemPromptBuilder,
    required this.contextFormatter,
    this.maxConversationMessages = 20,
  }) : assert(maxConversationMessages >= 0);

  final CoachSystemPromptBuilder systemPromptBuilder;
  final ContextFormatter contextFormatter;
  final int maxConversationMessages;

  @override
  List<CoachMessage> build({
    required String userMessage,
    required List<CoachMessage> conversation,
    required ReaderContext readerContext,
    bool conversationIncludesCurrentMessage = false,
  }) {
    final currentMessage = CoachMessage.user(userMessage);
    final domainConversation = conversation
        .where((message) => message.role != CoachMessageRole.system)
        .toList();
    if (conversationIncludesCurrentMessage) {
      if (domainConversation.isEmpty ||
          domainConversation.last.role != CoachMessageRole.user ||
          domainConversation.last.content != userMessage) {
        throw ArgumentError.value(
          conversation,
          'conversation',
          'The conversation must end with the current user message',
        );
      }
      domainConversation.removeLast();
    }
    final retainedCount = domainConversation.length < maxConversationMessages
        ? domainConversation.length
        : maxConversationMessages;
    final recentConversation = domainConversation.sublist(
      domainConversation.length - retainedCount,
    );

    return List.unmodifiable([
      CoachMessage.system(systemPromptBuilder.build()),
      CoachMessage.system(contextFormatter.format(readerContext)),
      ...recentConversation,
      currentMessage,
    ]);
  }
}
