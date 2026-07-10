import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reading_tracker/core/database/app_database.dart';
import 'package:reading_tracker/features/coach/data/daos/coach_conversation_dao.dart';
import 'package:reading_tracker/features/coach/domain/entities/coach_conversation.dart';
import 'package:reading_tracker/features/coach/domain/entities/coach_message.dart';

void main() {
  late AppDatabase database;
  late CoachConversationDao dao;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    dao = CoachConversationDao(database);
  });
  tearDown(() => database.close());

  test('crea y lista conversaciones por actividad', () async {
    await dao.upsertConversation(_conversation('old', 1));
    await dao.upsertConversation(_conversation('new', 2));

    final conversations = await dao.getConversations();

    expect(conversations.map((item) => item.id), ['new', 'old']);
  });

  test('inserta, ordena y actualiza el mismo mensaje', () async {
    await dao.upsertConversation(_conversation('conversation', 1));
    final user = CoachMessage.user(
      'Pregunta',
      id: 'user',
      conversationId: 'conversation',
      sequence: 0,
    );
    final assistant = CoachMessage.assistant(
      '',
      id: 'assistant',
      conversationId: 'conversation',
      parentUserMessageId: 'user',
      sequence: 1,
    );
    await dao.upsertMessage(assistant);
    await dao.upsertMessage(user);
    await dao.upsertMessage(assistant.copyWith(content: 'Respuesta'));

    final messages = await dao.getMessages('conversation');

    expect(messages.map((item) => item.id), ['user', 'assistant']);
    expect(messages.last.content, 'Respuesta');
    expect(messages.last.parentUserMessageId, 'user');
  });

  test('eliminar conversacion elimina sus mensajes', () async {
    await dao.upsertConversation(_conversation('conversation', 1));
    await dao.upsertMessage(
      CoachMessage.user('Pregunta', id: 'user', conversationId: 'conversation'),
    );

    await dao.deleteConversation('conversation');

    expect(await dao.getConversation('conversation'), isNull);
    expect(await dao.getMessages('conversation'), isEmpty);
  });
}

CoachConversation _conversation(String id, int day) => CoachConversation(
  id: id,
  title: 'Title $id',
  createdAt: DateTime(2026, 7, day),
  updatedAt: DateTime(2026, 7, day),
  lastMessageAt: DateTime(2026, 7, day),
);
