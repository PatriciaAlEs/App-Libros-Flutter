import 'package:flutter_test/flutter_test.dart';
import 'package:reading_tracker/features/coach/domain/entities/coach_message.dart';
import 'package:reading_tracker/features/coach/domain/services/conversation_context_policy.dart';

void main() {
  test('prioriza mensajes recientes y conserva orden', () {
    const policy = ConversationContextPolicy(maxRecentMessages: 2);
    final result = policy.selectRecent([
      CoachMessage.user('Uno'),
      CoachMessage.assistant('Dos'),
      CoachMessage.user('Tres'),
    ]);

    expect(result.map((message) => message.content), ['Dos', 'Tres']);
  });

  test('detecta conversaciones que necesitan resumen', () {
    const policy = ConversationContextPolicy(summaryThresholdCharacters: 5);

    expect(policy.shouldSummarize([CoachMessage.user('contenido')]), isTrue);
  });
}
