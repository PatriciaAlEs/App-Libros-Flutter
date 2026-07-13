import '../entities/coach_message.dart';
import '../models/reader_context.dart';
import 'coach_system_prompt_builder.dart';
import 'bookish_culture_retriever.dart';
import 'context_formatter.dart';

abstract interface class PromptBuilder {
  List<CoachMessage> build({
    required String userMessage,
    required List<CoachMessage> conversation,
    required ReaderContext readerContext,
    bool conversationIncludesCurrentMessage = false,
    String? conversationSummary,
    String? verifiedBibliographicContext,
  });
}

final class CoachPromptBuilder implements PromptBuilder {
  const CoachPromptBuilder({
    required this.systemPromptBuilder,
    required this.contextFormatter,
    this.bookishCultureRetriever = const BookishCultureRetriever(),
    this.maxConversationMessages = 20,
    this.maxConversationCharacters = 12000,
  }) : assert(maxConversationMessages >= 0);

  final CoachSystemPromptBuilder systemPromptBuilder;
  final ContextFormatter contextFormatter;
  final BookishCultureRetriever bookishCultureRetriever;
  final int maxConversationMessages;
  final int maxConversationCharacters;

  @override
  List<CoachMessage> build({
    required String userMessage,
    required List<CoachMessage> conversation,
    required ReaderContext readerContext,
    bool conversationIncludesCurrentMessage = false,
    String? conversationSummary,
    String? verifiedBibliographicContext,
  }) {
    final currentMessage = CoachMessage.user(userMessage);
    final domainConversation = conversation
        .where(
          (message) =>
              message.role != CoachMessageRole.system &&
              message.content.trim().isNotEmpty,
        )
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
    final recentConversationReversed = <CoachMessage>[];
    var retainedCharacters = 0;
    for (final message in domainConversation.reversed) {
      if (recentConversationReversed.length >= maxConversationMessages) {
        break;
      }
      if (recentConversationReversed.isNotEmpty &&
          retainedCharacters + message.content.length >
              maxConversationCharacters) {
        break;
      }
      recentConversationReversed.add(message);
      retainedCharacters += message.content.length;
    }
    final recentConversation = recentConversationReversed.reversed;
    final cultureEntries = bookishCultureRetriever.retrieve(
      userMessage: userMessage,
      recentConversation: recentConversation.toList(growable: false),
      now: readerContext.metadata.generatedAt,
    );
    final cultureNotes = bookishCultureRetriever.formatNotes(cultureEntries);
    final readerContextPrompt = contextFormatter.format(readerContext);
    final enrichedContext = [
      readerContextPrompt,
      if (cultureNotes.isNotEmpty) cultureNotes,
      if (verifiedBibliographicContext?.trim().isNotEmpty == true)
        verifiedBibliographicContext!.trim(),
    ].join('\n\n');

    return List.unmodifiable([
      CoachMessage.system(systemPromptBuilder.build()),
      CoachMessage.system(enrichedContext),
      if (conversationSummary?.trim().isNotEmpty == true)
        CoachMessage.system(
          'Resumen de la conversación:\n$conversationSummary',
        ),
      ...recentConversation,
      currentMessage,
    ]);
  }
}
