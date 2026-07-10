import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reading_tracker/features/coach/data/providers/coach_llm_providers.dart';
import 'package:reading_tracker/features/coach/data/providers/coach_repository_provider.dart';
import 'package:reading_tracker/features/coach/domain/models/reader_context.dart';
import 'package:reading_tracker/features/coach/domain/repositories/coach_repository.dart';
import 'package:reading_tracker/features/coach/domain/services/prompt_builder.dart';

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
      final response = await repository.generateReply(
        userMessage: 'Pregunta',
        conversation: const [],
        readerContext: _readerContext(),
      );

      expect(repository, isA<CoachRepository>());
      expect(container.read(promptBuilderProvider), isA<PromptBuilder>());
      expect(response, 'Respuesta');
      expect(client.lastMessages?.last.content, 'Pregunta');
    });
  });
}

ReaderContext _readerContext() => ReaderContext(
  metadata: ReaderContextMetadata(generatedAt: DateTime(2026, 7, 10)),
  library: ReaderLibraryContext(
    allBooks: const [],
    currentBooks: const [],
    completedBooks: const [],
    pendingBooks: const [],
    abandonedBooks: const [],
  ),
  activity: ReaderActivityContext(readingSessions: const []),
);
