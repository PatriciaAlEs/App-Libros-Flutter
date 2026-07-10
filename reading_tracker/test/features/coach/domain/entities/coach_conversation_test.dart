import 'package:flutter_test/flutter_test.dart';
import 'package:reading_tracker/features/coach/domain/entities/coach_conversation.dart';

void main() {
  test('copyWith conserva id y createdAt', () {
    final createdAt = DateTime(2026, 7, 10);
    final conversation = CoachConversation(
      id: 'conversation',
      title: 'Titulo',
      createdAt: createdAt,
      updatedAt: createdAt,
      lastMessageAt: createdAt,
    );

    final updated = conversation.copyWith(title: 'Nuevo', summary: 'Resumen');

    expect(updated.id, 'conversation');
    expect(updated.createdAt, createdAt);
    expect(updated.title, 'Nuevo');
    expect(updated.summary, 'Resumen');
    expect(updated, updated.copyWith());
  });
}
