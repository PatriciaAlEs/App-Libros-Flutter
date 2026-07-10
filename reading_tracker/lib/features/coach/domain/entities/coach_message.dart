import 'package:uuid/uuid.dart';

enum CoachMessageRole { system, user, assistant }

class CoachMessage {
  CoachMessage({
    String? id,
    this.conversationId,
    required this.role,
    required String content,
    DateTime? createdAt,
    this.parentUserMessageId,
    this.sequence = 0,
  }) : id = id ?? const Uuid().v4(),
       content = _validateContent(content),
       createdAt = createdAt ?? DateTime.now();

  CoachMessage._assistant({
    String? id,
    this.conversationId,
    required this.content,
    DateTime? createdAt,
    this.parentUserMessageId,
    this.sequence = 0,
  }) : id = id ?? const Uuid().v4(),
       role = CoachMessageRole.assistant,
       createdAt = createdAt ?? DateTime.now();

  factory CoachMessage.system(String content, {String? id}) {
    return CoachMessage(
      id: id,
      role: CoachMessageRole.system,
      content: content,
    );
  }

  factory CoachMessage.user(
    String content, {
    String? id,
    String? conversationId,
    DateTime? createdAt,
    int sequence = 0,
  }) {
    return CoachMessage(
      id: id,
      conversationId: conversationId,
      role: CoachMessageRole.user,
      content: content,
      createdAt: createdAt,
      sequence: sequence,
    );
  }

  factory CoachMessage.assistant(
    String content, {
    String? id,
    String? conversationId,
    DateTime? createdAt,
    String? parentUserMessageId,
    int sequence = 0,
  }) {
    return CoachMessage._assistant(
      id: id,
      conversationId: conversationId,
      content: content,
      createdAt: createdAt,
      parentUserMessageId: parentUserMessageId,
      sequence: sequence,
    );
  }

  final String id;
  final String? conversationId;
  final CoachMessageRole role;
  final String content;
  final DateTime createdAt;
  final String? parentUserMessageId;
  final int sequence;

  CoachMessage copyWith({String? content, int? sequence}) {
    if (role == CoachMessageRole.assistant) {
      return CoachMessage.assistant(
        content ?? this.content,
        id: id,
        conversationId: conversationId,
        createdAt: createdAt,
        parentUserMessageId: parentUserMessageId,
        sequence: sequence ?? this.sequence,
      );
    }
    return CoachMessage(
      id: id,
      conversationId: conversationId,
      role: role,
      content: content ?? this.content,
      createdAt: createdAt,
      parentUserMessageId: parentUserMessageId,
      sequence: sequence ?? this.sequence,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoachMessage &&
          id == other.id &&
          conversationId == other.conversationId &&
          role == other.role &&
          content == other.content &&
          createdAt == other.createdAt &&
          parentUserMessageId == other.parentUserMessageId &&
          sequence == other.sequence;

  @override
  int get hashCode => Object.hash(
    id,
    conversationId,
    role,
    content,
    createdAt,
    parentUserMessageId,
    sequence,
  );

  static String _validateContent(String content) {
    if (content.trim().isEmpty) {
      throw ArgumentError.value(content, 'content', 'Content cannot be empty');
    }
    return content;
  }
}
