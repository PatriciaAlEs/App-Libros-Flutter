enum CoachMessageRole { system, user, assistant }

class CoachMessage {
  CoachMessage({required this.role, required String content})
    : content = _validateContent(content);

  CoachMessage._assistant(this.content) : role = CoachMessageRole.assistant;

  factory CoachMessage.system(String content) {
    return CoachMessage(role: CoachMessageRole.system, content: content);
  }

  factory CoachMessage.user(String content) {
    return CoachMessage(role: CoachMessageRole.user, content: content);
  }

  factory CoachMessage.assistant(String content) {
    return CoachMessage._assistant(content);
  }

  final CoachMessageRole role;
  final String content;

  static String _validateContent(String content) {
    if (content.trim().isEmpty) {
      throw ArgumentError.value(content, 'content', 'Content cannot be empty');
    }
    return content;
  }
}
