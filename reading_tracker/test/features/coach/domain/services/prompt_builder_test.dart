import 'package:flutter_test/flutter_test.dart';
import 'package:reading_tracker/features/coach/domain/entities/coach_message.dart';
import 'package:reading_tracker/features/coach/domain/models/reader_context.dart';
import 'package:reading_tracker/features/coach/domain/services/coach_system_prompt_builder.dart';
import 'package:reading_tracker/features/coach/domain/services/context_formatter.dart';
import 'package:reading_tracker/features/coach/domain/services/prompt_builder.dart';

void main() {
  group('CoachPromptBuilder', () {
    const builder = CoachPromptBuilder(
      systemPromptBuilder: DefaultCoachSystemPromptBuilder(),
      contextFormatter: MarkdownContextFormatter(),
    );

    test('compone instrucciones, contexto, historial y mensaje actual en orden', () {
      final result = builder.build(
        userMessage: 'Actual',
        conversation: [CoachMessage.user('Uno'), CoachMessage.assistant('Dos')],
        readerContext: _readerContext(),
      );

      expect(result.map((message) => message.role), [CoachMessageRole.system, CoachMessageRole.system, CoachMessageRole.user, CoachMessageRole.assistant, CoachMessageRole.user]);
      expect(result[0].content, contains('ReadPp Coach'));
      expect(result[1].content, startsWith('# Contexto'));
      expect(result.map((message) => message.content).skip(2), ['Uno', 'Dos', 'Actual']);
    });

    test('maneja historial vacio y conserva espacios del mensaje actual', () {
      final result = builder.build(userMessage: '  Actual  ', conversation: const [], readerContext: _readerContext());

      expect(result, hasLength(3));
      expect(result.last.content, '  Actual  ');
    });

    test('elimina mensajes system del historial de dominio', () {
      final result = builder.build(
        userMessage: 'Actual',
        conversation: [CoachMessage.system('Temporal'), CoachMessage.user('Anterior')],
        readerContext: _readerContext(),
      );

      expect(result.where((message) => message.content == 'Temporal'), isEmpty);
      expect(result.where((message) => message.content == 'Actual'), hasLength(1));
    });

    test('el limite prioriza historial reciente sin eliminar system ni actual', () {
      const limitedBuilder = CoachPromptBuilder(
        systemPromptBuilder: DefaultCoachSystemPromptBuilder(),
        contextFormatter: MarkdownContextFormatter(),
        maxConversationMessages: 2,
      );
      final result = limitedBuilder.build(
        userMessage: 'Actual',
        conversation: [CoachMessage.user('Antiguo'), CoachMessage.assistant('Reciente 1'), CoachMessage.user('Reciente 2')],
        readerContext: _readerContext(),
      );

      expect(result.map((message) => message.content).skip(2), ['Reciente 1', 'Reciente 2', 'Actual']);
      expect(result.take(2).every((message) => message.role == CoachMessageRole.system), isTrue);
    });

    test('es determinista para las mismas entradas', () {
      final conversation = [CoachMessage.user('Anterior')];
      final context = _readerContext();
      final first = builder.build(userMessage: 'Actual', conversation: conversation, readerContext: context);
      final second = builder.build(userMessage: 'Actual', conversation: conversation, readerContext: context);

      expect(second.map((message) => (message.role, message.content)), first.map((message) => (message.role, message.content)));
    });

    test('rechaza mensaje actual vacio segun la regla de CoachMessage', () {
      expect(() => builder.build(userMessage: '   ', conversation: const [], readerContext: _readerContext()), throwsArgumentError);
    });
  });
}

ReaderContext _readerContext() => ReaderContext(
  metadata: ReaderContextMetadata(generatedAt: DateTime(2026, 7, 10, 10)),
  library: ReaderLibraryContext(allBooks: const [], currentBooks: const [], completedBooks: const [], pendingBooks: const [], abandonedBooks: const []),
  activity: ReaderActivityContext(readingSessions: const []),
);
