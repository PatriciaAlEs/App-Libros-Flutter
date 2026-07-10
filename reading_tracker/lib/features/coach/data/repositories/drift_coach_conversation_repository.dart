import 'package:uuid/uuid.dart';

import '../../domain/entities/coach_conversation.dart';
import '../../domain/entities/coach_message.dart';
import '../../domain/repositories/coach_conversation_repository.dart';
import '../daos/coach_conversation_dao.dart';

class DriftCoachConversationRepository implements CoachConversationRepository {
  const DriftCoachConversationRepository(this.dao);
  final CoachConversationDao dao;

  @override
  Future<CoachConversation> createFromFirstMessage(String message) async {
    final now = DateTime.now();
    final conversation = CoachConversation(
      id: const Uuid().v4(),
      title: _titleFrom(message),
      createdAt: now,
      updatedAt: now,
      lastMessageAt: now,
    );
    await dao.upsertConversation(conversation);
    return conversation;
  }

  String _titleFrom(String message) {
    final normalized = message.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.isEmpty) {
      return 'Conversación';
    }
    return normalized.length <= 60
        ? normalized
        : '${normalized.substring(0, 57)}…';
  }

  @override
  Future<void> deleteConversation(String id) => dao.deleteConversation(id);
  @override
  Future<void> deleteMessage(String id) => dao.deleteMessage(id);
  @override
  Future<void> deleteMessagesAfter(String id, int sequence) =>
      dao.deleteMessagesAfter(id, sequence);
  @override
  Future<CoachConversation?> getConversation(String id) =>
      dao.getConversation(id);
  @override
  Future<List<CoachConversation>> getConversations() => dao.getConversations();
  @override
  Future<List<CoachMessage>> getMessages(String id) => dao.getMessages(id);
  @override
  Future<void> saveConversation(CoachConversation value) =>
      dao.upsertConversation(value);
  @override
  Future<void> saveMessage(CoachMessage value) => dao.upsertMessage(value);
  @override
  Stream<List<CoachConversation>> watchConversations() =>
      dao.watchConversations();
}
