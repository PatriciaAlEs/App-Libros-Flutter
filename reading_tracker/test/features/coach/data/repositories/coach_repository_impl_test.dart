import 'package:flutter_test/flutter_test.dart';
import 'package:reading_tracker/features/coach/data/repositories/coach_repository_impl.dart';
import 'package:reading_tracker/features/coach/domain/entities/coach_message.dart';
import 'package:reading_tracker/features/coach/domain/models/reader_context.dart';
import 'package:reading_tracker/features/coach/domain/repositories/coach_repository.dart';
import 'package:reading_tracker/features/coach/domain/services/prompt_builder.dart';

import '../../domain/services/fakes/fake_llm_client.dart';

void main() {
  group('CoachRepositoryImpl', () {
    test(
      'usa el builder y envia exactamente su resultado al cliente',
      () async {
        final builtMessages = [
          CoachMessage.system('Sistema'),
          CoachMessage.user('Actual'),
        ];
        final builder = _RecordingPromptBuilder(builtMessages);
        final client = FakeLlmClient('Respuesta');
        final repository = CoachRepositoryImpl(
          llmClient: client,
          promptBuilder: builder,
        );
        final conversation = [CoachMessage.user('Anterior')];
        final context = _readerContext();

        final response = await repository.generateReply(
          userMessage: 'Actual',
          conversation: conversation,
          readerContext: context,
        );

        expect(repository, isA<CoachRepository>());
        expect(builder.userMessage, 'Actual');
        expect(builder.conversation, same(conversation));
        expect(builder.readerContext, same(context));
        expect(client.lastMessages, builtMessages);
        expect(response, 'Respuesta');
      },
    );

    test(
      'conserva una respuesta vacia para que la gestione el controller',
      () async {
        final repository = CoachRepositoryImpl(
          llmClient: FakeLlmClient('   '),
          promptBuilder: _RecordingPromptBuilder([CoachMessage.user('Actual')]),
        );

        final response = await repository.generateReply(
          userMessage: 'Actual',
          conversation: const [],
          readerContext: _readerContext(),
        );

        expect(response, '   ');
      },
    );

    test('propaga errores de LlmClient', () {
      final repository = CoachRepositoryImpl(
        llmClient: _FailingLlmClient(),
        promptBuilder: _RecordingPromptBuilder([CoachMessage.user('Actual')]),
      );

      expect(
        repository.generateReply(
          userMessage: 'Actual',
          conversation: const [],
          readerContext: _readerContext(),
        ),
        throwsA(isA<StateError>()),
      );
    });
  });
}

class _RecordingPromptBuilder implements PromptBuilder {
  _RecordingPromptBuilder(this.result);

  final List<CoachMessage> result;
  String? userMessage;
  List<CoachMessage>? conversation;
  ReaderContext? readerContext;

  @override
  List<CoachMessage> build({
    required String userMessage,
    required List<CoachMessage> conversation,
    required ReaderContext readerContext,
    bool conversationIncludesCurrentMessage = false,
  }) {
    this.userMessage = userMessage;
    this.conversation = conversation;
    this.readerContext = readerContext;
    return result;
  }
}

class _FailingLlmClient extends FakeLlmClient {
  _FailingLlmClient() : super('Respuesta');

  @override
  Future<String> complete({required List<CoachMessage> messages}) async {
    throw StateError('failure');
  }
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
