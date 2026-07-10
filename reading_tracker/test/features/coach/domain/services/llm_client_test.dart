import 'package:flutter_test/flutter_test.dart';
import 'package:reading_tracker/features/coach/domain/entities/coach_message.dart';
import 'package:reading_tracker/features/coach/domain/services/llm_client.dart';

import 'fakes/fake_llm_client.dart';

void main() {
  group('FakeLlmClient', () {
    test('implementa LlmClient', () {
      final client = FakeLlmClient('respuesta');

      expect(client, isA<LlmClient>());
    });

    test('complete devuelve la respuesta configurada', () async {
      final client = FakeLlmClient('respuesta fija');

      final response = await client.complete(
        messages: [CoachMessage.user('Hola')],
      );

      expect(response, 'respuesta fija');
    });

    test('complete conserva los mensajes recibidos para inspeccion', () async {
      final client = FakeLlmClient('respuesta');
      final messages = [
        CoachMessage.system('Instrucciones'),
        CoachMessage.user('Pregunta'),
      ];

      await client.complete(messages: messages);

      expect(client.lastMessages, messages);
    });

    test('complete rechaza lista de mensajes vacia con ArgumentError', () {
      final client = FakeLlmClient('respuesta');

      expect(client.complete(messages: const []), throwsArgumentError);
    });

    test('complete no modifica la lista original', () async {
      final client = FakeLlmClient('respuesta');
      final originalMessage = CoachMessage.user('Pregunta');
      final messages = [originalMessage];

      await client.complete(messages: messages);
      messages.add(CoachMessage.assistant('Respuesta previa'));

      expect(messages, hasLength(2));
      expect(client.lastMessages, [originalMessage]);
    });

    test('complete permite mensajes system, user y assistant', () async {
      final client = FakeLlmClient('respuesta');
      final messages = [
        CoachMessage.system('Instrucciones'),
        CoachMessage.user('Pregunta'),
        CoachMessage.assistant('Respuesta previa'),
      ];

      final response = await client.complete(messages: messages);

      expect(response, 'respuesta');
      expect(client.lastMessages?.map((message) => message.role), [
        CoachMessageRole.system,
        CoachMessageRole.user,
        CoachMessageRole.assistant,
      ]);
    });

    test('streamCompletion expone fragmentos de texto', () async {
      final client = FakeLlmClient('fragmento');

      final chunks = await client
          .streamCompletion(messages: [CoachMessage.user('Pregunta')])
          .toList();

      expect(chunks, ['fragmento']);
    });
  });
}
