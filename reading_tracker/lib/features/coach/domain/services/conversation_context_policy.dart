import '../entities/coach_message.dart';

class ConversationContextPolicy {
  const ConversationContextPolicy({
    this.maxRecentMessages = 20,
    this.maxCharacters = 12000,
    this.summaryThresholdCharacters = 16000,
  });

  final int maxRecentMessages;
  final int maxCharacters;
  final int summaryThresholdCharacters;

  List<CoachMessage> selectRecent(List<CoachMessage> messages) {
    final selected = <CoachMessage>[];
    var characters = 0;
    for (final message in messages.reversed) {
      if (selected.length >= maxRecentMessages) {
        break;
      }
      if (selected.isNotEmpty &&
          characters + message.content.length > maxCharacters) {
        break;
      }
      selected.add(message);
      characters += message.content.length;
    }
    return selected.reversed.toList(growable: false);
  }

  bool shouldSummarize(List<CoachMessage> messages) =>
      messages.fold<int>(
        0,
        (total, message) => total + message.content.length,
      ) >
      summaryThresholdCharacters;

  List<CoachMessage> messagesToSummarize(List<CoachMessage> messages) {
    final recent = selectRecent(messages).toSet();
    return messages.where((message) => !recent.contains(message)).toList();
  }
}
