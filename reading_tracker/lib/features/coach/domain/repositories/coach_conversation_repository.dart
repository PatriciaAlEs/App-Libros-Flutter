import '../entities/coach_conversation.dart';
import '../entities/coach_message.dart';

abstract interface class CoachConversationRepository {
  Future<CoachConversation> createFromFirstMessage(String message);
  Future<List<CoachConversation>> getConversations();
  Stream<List<CoachConversation>> watchConversations();
  Future<CoachConversation?> getConversation(String id);
  Future<List<CoachMessage>> getMessages(String conversationId);
  Future<void> saveConversation(CoachConversation conversation);
  Future<void> saveMessage(CoachMessage message);
  Future<void> deleteMessage(String id);
  Future<void> deleteMessagesAfter(String conversationId, int sequence);
  Future<void> deleteConversation(String id);
}
