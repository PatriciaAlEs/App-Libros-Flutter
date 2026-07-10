import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reading_tracker/features/coach/data/providers/coach_llm_providers.dart';
import 'package:reading_tracker/features/coach/data/providers/coach_repository_provider.dart';
import 'package:reading_tracker/features/coach/domain/entities/coach_message.dart';
import 'package:reading_tracker/features/coach/domain/repositories/coach_repository.dart';

import '../../domain/services/fakes/fake_llm_client.dart';

void main() {
  group('coachRepositoryProvider', () {
    test('se resuelve con override de llmClientProvider', () async {
      final client = FakeLlmClient('Respuesta');
      final container = ProviderContainer(
        overrides: [llmClientProvider.overrideWithValue(client)],
      );
      addTearDown(container.dispose);

      final repository = container.read(coachRepositoryProvider);
      final response = await repository.generateReply([
        CoachMessage.user('Pregunta'),
      ]);

      expect(repository, isA<CoachRepository>());
      expect(response, 'Respuesta');
      expect(client.lastMessages?.single.content, 'Pregunta');
    });
  });
}
