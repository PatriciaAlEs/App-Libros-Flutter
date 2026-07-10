import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/coach_conversation.dart';
import '../../domain/entities/coach_message.dart';

class CoachConversationDao {
  const CoachConversationDao(this.database);
  final AppDatabase database;

  Future<void> upsertConversation(CoachConversation conversation) {
    return database.customStatement(
      '''
      INSERT INTO coach_conversations
        (id, title, summary, created_at, updated_at, last_message_at)
      VALUES (?, ?, ?, ?, ?, ?)
      ON CONFLICT(id) DO UPDATE SET
        title = excluded.title,
        summary = excluded.summary,
        updated_at = excluded.updated_at,
        last_message_at = excluded.last_message_at
      ''',
      [
        conversation.id,
        conversation.title,
        conversation.summary,
        conversation.createdAt.millisecondsSinceEpoch,
        conversation.updatedAt.millisecondsSinceEpoch,
        conversation.lastMessageAt.millisecondsSinceEpoch,
      ],
    );
  }

  Future<List<CoachConversation>> getConversations({int limit = 50}) async {
    final rows = await database
        .customSelect(
          'SELECT * FROM coach_conversations ORDER BY last_message_at DESC LIMIT ?',
          variables: [Variable.withInt(limit)],
        )
        .get();
    return rows.map(_conversationFromRow).toList(growable: false);
  }

  Stream<List<CoachConversation>> watchConversations({int limit = 50}) {
    return Stream.fromFuture(getConversations(limit: limit));
  }

  Future<CoachConversation?> getConversation(String id) async {
    final row = await database
        .customSelect(
          'SELECT * FROM coach_conversations WHERE id = ? LIMIT 1',
          variables: [Variable.withString(id)],
        )
        .getSingleOrNull();
    return row == null ? null : _conversationFromRow(row);
  }

  Future<void> upsertMessage(CoachMessage message) {
    final conversationId = message.conversationId;
    if (conversationId == null) {
      throw ArgumentError('Persistent messages require a conversationId');
    }
    return database.customStatement(
      '''
      INSERT INTO coach_messages
        (id, conversation_id, role, content, created_at,
         parent_user_message_id, sequence_number)
      VALUES (?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT(id) DO UPDATE SET content = excluded.content,
        parent_user_message_id = excluded.parent_user_message_id,
        sequence_number = excluded.sequence_number
      ''',
      [
        message.id,
        conversationId,
        message.role.name,
        message.content,
        message.createdAt.millisecondsSinceEpoch,
        message.parentUserMessageId,
        message.sequence,
      ],
    );
  }

  Future<List<CoachMessage>> getMessages(String conversationId) async {
    final rows = await database
        .customSelect(
          '''
      SELECT * FROM coach_messages WHERE conversation_id = ?
      ORDER BY sequence_number ASC, created_at ASC
      ''',
          variables: [Variable.withString(conversationId)],
        )
        .get();
    return rows.map(_messageFromRow).toList(growable: false);
  }

  Future<void> deleteMessage(String id) {
    return database.customStatement('DELETE FROM coach_messages WHERE id = ?', [
      id,
    ]);
  }

  Future<void> deleteMessagesAfter(String conversationId, int sequence) {
    return database.customStatement(
      'DELETE FROM coach_messages WHERE conversation_id = ? AND sequence_number > ?',
      [conversationId, sequence],
    );
  }

  Future<void> deleteConversation(String id) async {
    await database.transaction(() async {
      await database.customStatement(
        'DELETE FROM coach_messages WHERE conversation_id = ?',
        [id],
      );
      await database.customStatement(
        'DELETE FROM coach_conversations WHERE id = ?',
        [id],
      );
    });
  }

  CoachConversation _conversationFromRow(QueryRow row) {
    return CoachConversation(
      id: row.read<String>('id'),
      title: row.read<String>('title'),
      summary: row.readNullable<String>('summary'),
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        row.read<int>('created_at'),
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        row.read<int>('updated_at'),
      ),
      lastMessageAt: DateTime.fromMillisecondsSinceEpoch(
        row.read<int>('last_message_at'),
      ),
    );
  }

  CoachMessage _messageFromRow(QueryRow row) {
    final role = CoachMessageRole.values.byName(row.read<String>('role'));
    final content = row.read<String>('content');
    final id = row.read<String>('id');
    final conversationId = row.read<String>('conversation_id');
    final createdAt = DateTime.fromMillisecondsSinceEpoch(
      row.read<int>('created_at'),
    );
    final sequence = row.read<int>('sequence_number');
    if (role == CoachMessageRole.assistant) {
      return CoachMessage.assistant(
        content,
        id: id,
        conversationId: conversationId,
        createdAt: createdAt,
        parentUserMessageId: row.readNullable<String>('parent_user_message_id'),
        sequence: sequence,
      );
    }
    return CoachMessage(
      id: id,
      conversationId: conversationId,
      role: role,
      content: content,
      createdAt: createdAt,
      sequence: sequence,
    );
  }
}
