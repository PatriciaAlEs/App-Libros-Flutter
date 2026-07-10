import 'package:flutter_test/flutter_test.dart';
import 'package:reading_tracker/features/coach/data/repositories/coach_repository_impl.dart';
import 'package:reading_tracker/features/coach/domain/entities/coach_message.dart';
import 'package:reading_tracker/features/coach/domain/repositories/coach_repository.dart';

import '../../domain/services/fakes/fake_llm_client.dart';

void main() {
  group('CoachRepositoryImpl', () {
    test('implementa CoachRepository', () {
      final repository = CoachRepositoryImpl(FakeLlmClient('Respuesta'));

      expect(repository, isA<CoachRepository>());
    });

    test('delega en LlmClient', () async {
      final client = FakeLlmClient('Respuesta');
      final repository = CoachRepositoryImpl(client);
      final messages = [CoachMessage.user('Pregunta')];

      await repository.generateReply(messages);

      expect(client.lastMessages, messages);
    });

    test('devuelve la respuesta proporcionada por LlmClient', () async {
      final repository = CoachRepositoryImpl(FakeLlmClient('Respuesta fija'));

      final response = await repository.generateReply([
        CoachMessage.user('Pregunta'),
      ]);

      expect(response, 'Respuesta fija');
    });

    test('propaga errores de LlmClient', () {
      final repository = CoachRepositoryImpl(_FailingLlmClient());

      expect(
        repository.generateReply([CoachMessage.user('Pregunta')]),
        throwsA(isA<StateError>()),
      );
    });
  });
}

class _FailingLlmClient extends FakeLlmClient {
  _FailingLlmClient() : super('Respuesta');

  @override
  Future<String> complete({required List<CoachMessage> messages}) async {
    throw StateError('failure');
  }
}
